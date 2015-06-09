//
//  NetworkManager.m
//  NetworkTesting
//
//  Created by quarta on 20/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "NetworkManager.h"


@interface NetworkManager () <MHUnicastSocketDelegate, MHMulticastSocketDelegate>

@property (nonatomic) BOOL isFlooding;
@property (nonatomic) BOOL rcvPackets;
@property (nonatomic) BOOL isStream;

@property (nonatomic, strong) NSString *ownPeer;

@property (nonatomic, strong) AppDelegate *appDelegate;

@property (nonatomic) BOOL started;
@property (nonatomic) BOOL failed;

@property (nonatomic, strong) MHUnicastSocket *uSocket;
@property (nonatomic, strong) MHMulticastSocket *mSocket;

@property (nonatomic, strong) NSMutableDictionary *peers;
@property (nonatomic, strong) NSMutableArray *neighbourPeers;


@property (nonatomic) int nbBroadcasts;
@property (nonatomic) int nbReceived;

// Stream
@property (nonatomic, strong) NSMutableDictionary *forwardTagsCount;
@property (nonatomic, strong) NSMutableDictionary *receiveTagsCount;
@property (nonatomic, strong) NSMutableDictionary *streamsSent;
@property (nonatomic, strong) NSString *streamPayload;


@property (nonatomic, strong) NSMutableArray *expReports;

@end

@implementation NetworkManager

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.started = NO;
        self.failed = NO;
        self.isStream = NO;
        
        self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        self.expReports = [[NSMutableArray alloc] init];
        
        self.nbBroadcasts = 0;
        self.nbReceived = 0;
        
        
        self.peers = [[NSMutableDictionary alloc] init];
        self.neighbourPeers = [[NSMutableArray alloc] init];
        self.forwardTagsCount = [[NSMutableDictionary alloc] init];
        self.receiveTagsCount = [[NSMutableDictionary alloc] init];
        self.streamsSent = [[NSMutableDictionary alloc] init];
        
        [MHDiagnostics getSingleton].useTraceInfo = YES;
        [MHDiagnostics getSingleton].useRetransmissionInfo = YES;
        [MHDiagnostics getSingleton].useNeighbourInfo = YES;
        [MHDiagnostics getSingleton].useNetworkLayerInfoCallbacks = YES;
        
        [self generatePayload];
    }
    
    return self;
}


- (void)dealloc
{
    [self.expReports removeAllObjects];
    self.expReports = nil;
    
    [self.peers removeAllObjects];
    self.peers = nil;
    
    [self.forwardTagsCount removeAllObjects];
    self.forwardTagsCount = nil;
    
    [self.receiveTagsCount removeAllObjects];
    self.receiveTagsCount = nil;
    
    [self.streamsSent removeAllObjects];
    self.streamsSent = nil;
    
    [self.neighbourPeers removeAllObjects];
    self.neighbourPeers = nil;
}




- (void)startWithExpNo:(int)expNo
          withFlooding:(BOOL)isFlooding
       withNodeFailure:(BOOL)nodeFailure
           withReceive:(BOOL)receivePackets
            withStream:(BOOL)isStream
{
    // Add new experiment into reports list
    [self.expReports addObject:[[ExperimentReport alloc] initWithNo:expNo]];
    
    self.isStream = isStream;
    self.isFlooding = isFlooding;
    self.rcvPackets = receivePackets;
    
    self.started = YES;
    self.failed = NO;
    
    self.nbBroadcasts = 0;
    self.nbReceived = 0;
    
    
    if (nodeFailure)
    {
        int seconds = (arc4random_uniform(30) + 10);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Disconnection from network
            if (isFlooding)
            {
                [self.uSocket disconnect];
            }
            else // But no group leaving!!
            {
                [self.mSocket disconnect];
            }
            
            self.failed = YES;
            [self writeLine:[NSString stringWithFormat:@"Node crashed after %d seconds (normal!!)", seconds]];
        });
    }
    
    
    if (isFlooding)
    {
        self.uSocket = [[MHUnicastSocket alloc] initWithServiceType:@"ntflood"];
        self.uSocket.delegate = self;
        [self.appDelegate setUniSocket:self.uSocket];
        
        self.ownPeer = [self.uSocket getOwnPeer];
    }
    else
    {
        self.mSocket = [[MHMulticastSocket alloc] initWithServiceType:@"ntshots"];
        self.mSocket.delegate = self;
        [self.appDelegate setMultiSocket:self.mSocket];
        
        self.ownPeer = [self.mSocket getOwnPeer];
        
        [self.mSocket joinGroup:self.ownPeer]; // For unicast stream response
        
        // Joining groups
        if (self.rcvPackets)
        {
            [self.mSocket joinGroup:GROUP_RCV];
        }
        else
        {
            [self.mSocket joinGroup:GROUP_NOT_RCV];
        }
    }
}

- (void)end
{
    self.started = NO;
    [self.peers removeAllObjects];
    [self.neighbourPeers removeAllObjects];
    [self.streamsSent removeAllObjects];
    [self.forwardTagsCount removeAllObjects];
    [self.receiveTagsCount removeAllObjects];
    
    // Network disconnection
    if (self.isFlooding)
    {
        if(!self.failed)
        {
            [self.uSocket disconnect];
        }
        self.uSocket = nil;
    }
    else
    {
        if (!self.failed)
        {
            [self.mSocket disconnect];
        }
        self.mSocket = nil;
    }
    
    [self.appDelegate setUniSocket:nil];
    [self.appDelegate setMultiSocket:nil];
    
    [self report];
}

- (void)broadcast
{
    self.nbBroadcasts++;
    
    NetworkMessage *msg = [[NetworkMessage alloc] initWithPayload:@""];
    MHSocket *sock = nil;
    NSArray *dest = nil;
    
    // Generate destinations based on algorithm
    if (self.isFlooding)
    {
        sock = self.uSocket;
        dest = [self.peers allKeys];
    }
    else
    {
        sock = self.mSocket;
        dest = [[NSArray alloc] initWithObjects:GROUP_RCV, nil];
    }
    
    if(self.isStream)
    {
        [self writeLine:[NSString stringWithFormat:@"Payload length: %d bytes", self.streamPayload.length]];
        
        // Save the timestamp before the stream is sent for later check
        [self.streamsSent setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:[NSNumber numberWithInt:msg.tag]];
        
        msg.payload = self.streamPayload;
        
        // Sending messages
        for (int i = 0; i < LOG_STREAM_COUNT; i++)
        {
            NSError *error;
            [sock sendMessage:[msg asNSData]
               toDestinations:dest
                        error:&error];
        }
        [self writeLine:[NSString stringWithFormat:@"Sent %d packets with tag %d", LOG_STREAM_COUNT, msg.tag]];
    }
    else // Send a single packet
    {
        NSError *error;
        [sock sendMessage:[msg asNSData]
           toDestinations:dest
                    error:&error];
        
        [self writeLine:[NSString stringWithFormat:@"Packet with tag %d sent", msg.tag]];
    }
}




- (void)report
{
    [self writeLine:@""];
    [self writeLine:@""];
    [self writeLine:@"REPORT"];
    [self writeLine:@""];
    
    [self writeLine:[NSString stringWithFormat:@"Display Name: %@", [UIDevice currentDevice].name]];
    [self writeLine:[NSString stringWithFormat:@"Peer: %@", self.ownPeer]];
    
    
    [self writeLine:[NSString stringWithFormat:@"Sent %d packets", self.nbBroadcasts]];
    
    if (self.rcvPackets)
    {
        [self writeLine:@"Can receive packets"];
        
        [self writeLine:[NSString stringWithFormat:@"Received %d packets", self.nbReceived]];
    }
    else
    {
        [self writeLine:@"Cannot receive packets"];
    }
    
    [self writeLine:[NSString stringWithFormat:@"Retransmission ratio: %f", [[MHDiagnostics getSingleton] getRetransmissionRatio]]];
}


- (void)sendResults
{
    for (id reportObj in self.expReports)
    {
        ExperimentReport *report = (ExperimentReport *)reportObj;
        
        [report send];
    }
    
    [self.expReports removeAllObjects];
}



- (ExperimentReport *)currentExpReport
{
    return [self.expReports lastObject];
}

#pragma mark - Writeline methods
- (void)writeLine:(NSString*)msg {
    [[self currentExpReport] writeLine:msg];
    [self.delegate networkManager:self writeLine:msg];
}



#pragma mark - MHSocketDelegate methods
- (void)mhSocket:(MHSocket *)mhSocket
 failedToConnect:(NSError *)error{
    [self writeLine: @"Failed to connect..."];
}


- (void)mhSocket:(MHSocket *)mhSocket
   forwardPacket:(NSString *)info
     withMessage:(NSData *)data
      fromSource:(NSString *)peer
{
    NetworkMessage *msg = [NetworkMessage fromNSData:data];
    
    if (self.isStream)
    {
        [self incrementTagsCount:msg.tag withTagsDict:self.forwardTagsCount];
        
        // If a certain number of messages has been forwarded, then log
        if([self getCountForTag:msg.tag withTagsDict:self.forwardTagsCount] % LOG_STREAM_COUNT == 0)
        {
            [self writeLine:[NSString stringWithFormat:@"%d packets from peer %@, with tag %d forwarded", LOG_STREAM_COUNT, msg.displayName, msg.tag]];
        }
    }
    else
    {
        [self writeLine:[NSString stringWithFormat:@"Packet from peer %@, with tag %d forwarded", msg.displayName, msg.tag]];
    }
}


- (void)mhSocket:(MHSocket *)mhSocket
didReceiveMessage:(NSData *)data
        fromPeer:(NSString *)peer
   withTraceInfo:(NSArray *)traceInfo
{
    if (self.rcvPackets)
    {
        NetworkMessage *msg = [NetworkMessage fromNSData:data];
        self.nbReceived++;
        
        
        if (self.isStream)
        {
            [self incrementTagsCount:msg.tag withTagsDict:self.receiveTagsCount];
            
            // If this is the first received message, add the peer display name
            if([self getCountForTag:msg.tag withTagsDict:self.receiveTagsCount] == 1)
            {
                [self.peers setObject:msg.displayName forKey:peer];
            }
            
            // If we are the stream receiver, we must send a response
            if (msg.tag > 0 && [self.streamsSent objectForKey:[NSNumber numberWithInt:msg.tag]] == nil)
            {
                MHSocket *sock = nil;
                NSArray *dest = [[NSArray alloc] initWithObjects:peer, nil];
                
                if (self.isFlooding)
                {
                    sock = self.uSocket;
                }
                else
                {
                    sock = self.mSocket;
                }
                
                // We prepare for sending response, but with a negative tag
                msg.tag = -msg.tag;
                
                // Send response
                self.nbBroadcasts++;
                
                NSError *error;
                [sock sendMessage:[msg asNSData]
                   toDestinations:dest
                            error:&error];
                
                // If we received a certain number of messages, then log
                if([self getCountForTag:-msg.tag withTagsDict:self.receiveTagsCount] % LOG_STREAM_COUNT == 0)
                {
                    [self writeLine:[NSString stringWithFormat:@"Received %d packets from peer %@, with tag %d", LOG_STREAM_COUNT, msg.displayName, -msg.tag]];
                }
            }
            else if([self.streamsSent objectForKey:[NSNumber numberWithInt:-msg.tag]] != nil)
            {
                // This is the stream response (we know from the negative tag)
                if([self getCountForTag:msg.tag withTagsDict:self.receiveTagsCount] % LOG_STREAM_COUNT == 0)
                {
                    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
                    NSTimeInterval timeInterval = end - [[self.streamsSent objectForKey:[NSNumber numberWithInt:-msg.tag]] doubleValue];
                    [self writeLine: [NSString stringWithFormat:@"Received reply (%d packets) for stream with tag %d in %.3f seconds", LOG_STREAM_COUNT, -msg.tag, timeInterval]];
                }
            }
        }
        else // Just a packet
        {
            [[self currentExpReport] writeTraceInfo:traceInfo];
            [self writeLine:[NSString stringWithFormat:@"Received packet from %@ with tag %d", msg.displayName, msg.tag]];
            
            [self.peers setObject:msg.displayName forKey:peer];
        }
    }
}


- (void)mhSocket:(MHSocket *)mhSocket
neighbourConnected:(NSString *)info
            peer:(NSString *)peer
     displayName:(NSString *)displayName
{
    if(![self.neighbourPeers containsObject:peer])
    {
        [self.neighbourPeers addObject:peer];
    }
    [self.peers setObject:displayName forKey:peer];
    
    [self.delegate networkManager:self updateNeighbourhood:[self displayNamesFromPeerArray:self.neighbourPeers]];
}

- (void)mhSocket:(MHSocket *)mhSocket
neighbourDisconnected:(NSString *)info
            peer:(NSString *)peer
{
    if([self.neighbourPeers containsObject:peer])
    {
        [self.neighbourPeers removeObject:peer];
    }
    
    [self.delegate networkManager:self updateNeighbourhood:[self displayNamesFromPeerArray:self.neighbourPeers]];
}


#pragma mark - MHUnicastSocketDelegate methods
- (void)mhUnicastSocket:(MHUnicastSocket *)mhUnicastSocket
           isDiscovered:(NSString *)info
                   peer:(NSString *)peer
            displayName:(NSString *)displayName{
    [self.peers setObject:displayName forKey:peer];
    
    [self writeLine:[NSString stringWithFormat:@"Discovered peer %@", displayName]];
}

- (void)mhUnicastSocket:(MHUnicastSocket *)mhUnicastSocket
        hasDisconnected:(NSString *)info
                   peer:(NSString *)peer{
    [self writeLine:[NSString stringWithFormat:@"Peer %@ has disconnected", [self displayNameFromPeer:peer]]];
    [self.peers removeObjectForKey:peer];
}



#pragma mark - MulticastSocketDelegate methods
- (void)mhMulticastSocket:(MHMulticastSocket *)mhMulticastSocket
              joinedGroup:(NSString *)info
                     peer:(NSString *)peer
                    group:(NSString *)group
{
    [self writeLine:[NSString stringWithFormat:@"Peer %@ joined a group", peer]];
    [self.peers setObject:@"" forKey:peer];
}





#pragma mark - Display name helper function
- (NSString *)displayNameFromPeer:(NSString *)peer
{
    NSString *displayName = [self.peers objectForKey:peer];
    
    if ([displayName isEqualToString:@""])
    {
        return peer;
    }
    else if(displayName == nil)
    {
        return @"unknown";
    }
    
    return displayName;
}

- (NSArray *)displayNamesFromPeerArray:(NSArray *)peers
{
    NSMutableArray *names = [[NSMutableArray alloc] init];
    
    for (id peer in peers)
    {
        NSString *name = [self displayNameFromPeer:peer];
        
        [names addObject:name];
    }
    
    return names;
}

#pragma mark - Streams helper methods
- (void)incrementTagsCount:(int)tag withTagsDict:(NSMutableDictionary *)dict
{
    id count = [dict objectForKey:[NSNumber numberWithInt:tag]];
    
    if (count == nil)
    {
        count = [NSNumber numberWithInt:0];
    }
    
    [dict setObject:[NSNumber numberWithInt:[count intValue] + 1] forKey:[NSNumber numberWithInt:tag]];
}

- (int)getCountForTag:(int)tag withTagsDict:(NSMutableDictionary *)dict
{
    id count = [dict objectForKey:[NSNumber numberWithInt:tag]];
    
    if (count == nil)
    {
        count = [NSNumber numberWithInt:0];
    }
    
    return [count intValue];
}

- (void)generatePayload
{
    self.streamPayload = @"";
    for (int i = 0; i < STREAM_PACKET_SIZE/10; i++)
    {
        self.streamPayload = [NSString stringWithFormat:@"%@%@", self.streamPayload, @"0000000000"];
    }
}
@end