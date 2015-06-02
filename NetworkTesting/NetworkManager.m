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

@property (nonatomic, strong) NSString *ownPeer;

@property (nonatomic, strong) AppDelegate *appDelegate;

@property (nonatomic) BOOL started;

@property (nonatomic, strong) MHUnicastSocket *uSocket;
@property (nonatomic, strong) MHMulticastSocket *mSocket;

@property (nonatomic, strong) NSMutableDictionary *peers;
@property (nonatomic) int nbBroadcasts;
@property (nonatomic) int nbReceived;

@property (nonatomic) BOOL failed;


@property (nonatomic, strong) NSMutableArray *expReports;

@end

@implementation NetworkManager

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.started = NO;
        self.nbBroadcasts = 0;
        self.nbReceived = 0;
        self.failed = NO;
        self.expReports = [[NSMutableArray alloc] init];
        
        self.peers = [[NSMutableDictionary alloc] init];
        self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        [MHDiagnostics getSingleton].useTraceInfo = YES;
        [MHDiagnostics getSingleton].useRetransmissionInfo = YES;
        [MHDiagnostics getSingleton].useNetworkLayerInfoCallbacks = YES;
    }
    
    return self;
}


- (void)dealloc
{
    [self.expReports removeAllObjects];
    self.expReports = nil;
    
    [self.peers removeAllObjects];
    self.peers = nil;
}




- (void)startWithExpNo:(int)expNo
          withFlooding:(BOOL)isFlooding
       withNodeFailure:(BOOL)nodeFailure
           withReceive:(BOOL)receivePackets
{
    [self.expReports addObject:[[ExperimentReport alloc] initWithNo:expNo]];
    
    
    self.isFlooding = isFlooding;
    self.rcvPackets = receivePackets;
    
    self.started = YES;
    self.nbBroadcasts = 0;
    self.nbReceived = 0;
    self.failed = NO;
    
    
    if (nodeFailure)
    {
        if (arc4random() % 4 == 0)
        {
            int seconds = (arc4random_uniform(20) + 5);
            
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
    
    if (self.isFlooding)
    {
        NSError *error;
        [self.uSocket sendMessage:[[NSString stringWithFormat:@"%@", [UIDevice currentDevice].name] dataUsingEncoding:NSUTF8StringEncoding]
                   toDestinations:[self.peers allKeys]
                            error:&error];
    }
    else
    {
        NSError *error;
        [self.mSocket sendMessage:[[NSString stringWithFormat:@"%@", [UIDevice currentDevice].name] dataUsingEncoding:NSUTF8StringEncoding]
                   toDestinations:[[NSArray alloc] initWithObjects:GROUP_RCV, nil]
                            error:&error];
    }
}


- (ExperimentReport *)currentExpReport
{
    return [self.expReports lastObject];
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
      fromSource:(NSString *)peer
{
    [self writeLine:[NSString stringWithFormat:@"Packet from peer %@ forwarded", [self displayNameFromPeer:peer]]];
}


- (void)mhSocket:(MHSocket *)mhSocket
didReceiveMessage:(NSData *)data
        fromPeer:(NSString *)peer
   withTraceInfo:(NSArray *)traceInfo
{
    if (self.rcvPackets)
    {
        self.nbReceived++;
    
        NSString *displayName = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        [[self currentExpReport] writeTraceInfo:traceInfo];
        [self writeLine:[NSString stringWithFormat:@"Received packet from %@", displayName]];
        
        [self.peers setObject:displayName forKey:peer];
    }
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
    
    return displayName;
}

@end