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

@property (nonatomic, strong) NSString *writeBuffer;

@property (nonatomic, strong) AppDelegate *appDelegate;

@property (nonatomic, strong) NSString *group;
@property (nonatomic) BOOL started;

@property (nonatomic, strong) MHUnicastSocket *uSocket;
@property (nonatomic, strong) MHMulticastSocket *mSocket;

@property (nonatomic, strong) NSMutableArray *peers;
@property (nonatomic, strong) NSMutableArray *targetPeers;
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
        self.writeBuffer = @"";
        
        self.started = NO;
        self.nbBroadcasts = 0;
        self.nbReceived = 0;
        self.group = @"";
        self.failed = NO;
        self.expReports = [[NSMutableArray alloc] init];
        
        self.peers = [[NSMutableArray alloc] init];
        self.targetPeers = [[NSMutableArray alloc] init];
        self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        [MHDiagnostics getSingleton].useTraceInfo = YES;
        [MHDiagnostics getSingleton].useRetransmissionInfo = YES;
    }
    
    return self;
}


- (void)dealloc
{
    self.writeBuffer = nil;
    [self.expReports removeAllObjects];
    self.expReports = nil;
    
    [self.peers removeAllObjects];
    self.peers = nil;
    
    [self.targetPeers removeAllObjects];
    self.targetPeers = nil;
}




- (void)startWithExpNo:(int)expNo withFlooding:(BOOL)isFlooding withNodeFailure:(BOOL)nodeFailure
{
    [self.expReports addObject:[[ExperimentReport alloc] initWithNo:expNo]];
    
    
    self.isFlooding = isFlooding;
    
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
    }
    else
    {
        self.mSocket = [[MHMulticastSocket alloc] initWithServiceType:@"ntshots"];
        self.mSocket.delegate = self;
        [self.appDelegate setMultiSocket:self.mSocket];
        
        // We join a random group ("0", "1" or "2")
        self.group = [NSString stringWithFormat:@"%d", (arc4random() % 3)];
        [self.mSocket joinGroup:self.group];
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
    
    [self.targetPeers removeAllObjects];
}

- (void)broadcast
{
    self.nbBroadcasts++;
    
    if (self.isFlooding)
    {
        NSError *error;
        [self.uSocket sendMessage:[@"broadcast flooding message" dataUsingEncoding:NSUTF8StringEncoding]
                   toDestinations:self.targetPeers
                            error:&error];
    }
    else
    {
        NSError *error;
        [self.mSocket sendMessage:[@"broadcast 6shots message" dataUsingEncoding:NSUTF8StringEncoding]
                   toDestinations:[[NSArray alloc] initWithObjects:self.group, nil]
                            error:&error];
    }
}


- (ExperimentReport *)currentExpReport
{
    return [self.expReports lastObject];
}


- (void)report
{
    if (self.isFlooding)
    {
        [self writeLine:[NSString stringWithFormat:@"Peer: %@", [self.uSocket getOwnPeer]]];
        [self writeLine:[NSString stringWithFormat:@"Broadcasted %d packets to peers:", self.nbBroadcasts]];
        
        for (id peer in self.targetPeers)
        {
            [self writeLine:peer];
        }
    }
    else
    {
        [self writeLine:[NSString stringWithFormat:@"Peer: %@", [self.mSocket getOwnPeer]]];
        [self writeLine:[NSString stringWithFormat:@"Joined group %@", self.group]];
        [self writeLine:[NSString stringWithFormat:@"Broadcasted %d packets to group %@", self.nbBroadcasts, self.group]];
    }
    
    
    [self writeLine:[NSString stringWithFormat:@"Received %d packets", self.nbReceived]];
    [self writeLine:[NSString stringWithFormat:@"Retransmission ratio: %f", [[MHDiagnostics getSingleton] getRetransmissionRatio]]];
    
    
    [self flushWriteBuffer];
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
    self.writeBuffer = [NSString stringWithFormat:@"%@%@\n", self.writeBuffer, msg];
    [[self currentExpReport] writeLine:msg];
}

- (void)flushWriteBuffer
{
    [self.delegate networkManager:self writeText:self.writeBuffer];
    self.writeBuffer = @"";
}


#pragma mark - MHUnicastSocketDelegate methods

- (void)mhUnicastSocket:(MHUnicastSocket *)mhUnicastSocket
      didReceiveMessage:(NSData *)data
               fromPeer:(NSString *)peer
          withTraceInfo:(NSArray *)traceInfo
{
    self.nbReceived++;
    
    [[self currentExpReport] writeTraceInfo:traceInfo];
}

- (void)mhUnicastSocket:(MHUnicastSocket *)mhUnicastSocket
           isDiscovered:(NSString *)info peer:(NSString *)peer
            displayName:(NSString *)displayName{
    [self.peers addObject:peer];
    
    // We will not broadcast messages to every peer in the network,
    // but only approximatively 1/3
    if (arc4random() % 3 == 0)
    {
        if (![self.targetPeers containsObject:peer])
        {
            [self.targetPeers addObject:peer];
        }
    }
}

- (void)mhUnicastSocket:(MHUnicastSocket *)mhUnicastSocket
        hasDisconnected:(NSString *)info
                   peer:(NSString *)peer{
    [self.peers removeObject:peer];
}

- (void)mhUnicastSocket:(MHUnicastSocket *)mhUnicastSocket
        failedToConnect:(NSError *)error{
    [self writeLine: @"Failed to connect..."];
}






#pragma mark - MulticastSocketDelegate methods
- (void)mhMulticastSocket:(MHMulticastSocket *)mhMulticastSocket
          failedToConnect:(NSError *)error
{
    [self writeLine: @"Failed to connect..."];
}

- (void)mhMulticastSocket:(MHMulticastSocket *)mhMulticastSocket
        didReceiveMessage:(NSData *)data
                 fromPeer:(NSString *)peer
            withTraceInfo:(NSArray *)traceInfo
{
    self.nbReceived++;
    
    [[self currentExpReport] writeTraceInfo:traceInfo];
}




@end