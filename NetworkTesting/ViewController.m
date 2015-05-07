//
//  ViewController.m
//  NetworkTesting
//
//  Created by quarta on 06/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <MHUnicastSocketDelegate, MHMulticastSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UIButton *endButton;

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *broadcastButton;
@property (weak, nonatomic) IBOutlet UISwitch *nodeFailureSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *floodingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *shotsSwitch;

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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.started = NO;
    self.broadcastButton.enabled = NO;
    self.shotsSwitch.on = NO;
    self.endButton.enabled = NO;
    self.nodeFailureSwitch.on = NO;
    self.nbBroadcasts = 0;
    self.nbReceived = 0;
    self.group = @"";
    self.failed = NO;
    
    self.peers = [[NSMutableArray alloc] init];
    self.targetPeers = [[NSMutableArray alloc] init];
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    [[MHDiagnostics getSingleton] useTraceInfo];
    [[MHDiagnostics getSingleton] useRetransmissionInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startPressed:(id)sender {
    self.started = YES;
    self.nodeFailureSwitch.enabled = NO;
    self.floodingSwitch.enabled = NO;
    self.shotsSwitch.enabled = NO;
    self.broadcastButton.enabled = YES;
    self.startButton.enabled = NO;
    self.endButton.enabled = YES;
    [self.logTextView setText:@""];
    self.nbBroadcasts = 0;
    self.nbReceived = 0;
    self.failed = NO;
    
    
    if (self.nodeFailureSwitch.on)
    {
        if (arc4random() % 4 == 0)
        {
            int seconds = (arc4random_uniform(100) + 10);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self.floodingSwitch.on)
                    {
                        [self.uSocket disconnect];
                    }
                    else
                    {
                        [self.mSocket disconnect];
                    }
                
                self.failed = YES;
                [self writeLine:[NSString stringWithFormat:@"Node crashed after %d seconds (normal!!)", seconds]];
            });
        }
    }
    
    
    if (self.floodingSwitch.on)
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
        
        self.group = [NSString stringWithFormat:@"%d", (arc4random() % 3)];
        [self.mSocket joinGroup:self.group];
    }
}

- (IBAction)endPressed:(id)sender {
    self.started = NO;
    self.nodeFailureSwitch.enabled = YES;
    self.floodingSwitch.enabled = YES;
    self.shotsSwitch.enabled = YES;
    self.broadcastButton.enabled = NO;
    self.startButton.enabled = YES;
    self.endButton.enabled = NO;
    
    [self.peers removeAllObjects];
    [self.targetPeers removeAllObjects];
    
    if (self.floodingSwitch.on)
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

- (IBAction)broadcastPressed:(id)sender {
    self.nbBroadcasts++;
    
    if (self.floodingSwitch.on)
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


- (IBAction)floodingValueChanged:(id)sender {
    self.shotsSwitch.on = !self.floodingSwitch.on;
}

- (IBAction)shotsValueChanged:(id)sender {
    self.floodingSwitch.on = !self.shotsSwitch.on;
}

- (void)writeLine:(NSString*)msg {
    [self.logTextView setText:[NSString stringWithFormat:@"%@%@\n", [self.logTextView text], msg]];
    
    if(self.logTextView.text.length > 0)
    {
        NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
        [self.logTextView scrollRangeToVisible:range];
    }
}


- (void)report
{
    if (self.floodingSwitch.on)
    {
        [self writeLine:[NSString stringWithFormat:@"Broadcasted %d packets to peers:", self.nbBroadcasts]];
        
        for (id peer in self.targetPeers)
        {
            [self writeLine:peer];
        }
    }
    else
    {
        [self writeLine:[NSString stringWithFormat:@"Joined group %@", self.group]];
        [self writeLine:[NSString stringWithFormat:@"Broadcasted %d packets to group %@", self.nbBroadcasts, self.group]];
    }
    
    [self writeLine:[NSString stringWithFormat:@"Received %d packets", self.nbReceived]];
    [self writeLine:[NSString stringWithFormat:@"Retransmission ratio: %f", [[MHDiagnostics getSingleton] getRetransmissionRatio]]];
}

#pragma mark - MHUnicastSocketDelegate methods

- (void)mhUnicastSocket:(MHUnicastSocket *)mhUnicastSocket
      didReceiveMessage:(NSData *)data
               fromPeer:(NSString *)peer
          withTraceInfo:(NSArray *)traceInfo
{
    self.nbReceived++;
}

- (void)mhUnicastSocket:(MHUnicastSocket *)mhUnicastSocket
           isDiscovered:(NSString *)info peer:(NSString *)peer
            displayName:(NSString *)displayName{
    [self.peers addObject:peer];
    
    if (arc4random() % 3 == 0)
    {
        [self.targetPeers addObject:peer];
    }
}

- (void)mhUnicastSocket:(MHUnicastSocket *)mhUnicastSocket
        hasDisconnected:(NSString *)info
                   peer:(NSString *)peer{
    [self.peers removeObject:peer];
    
    if([self.targetPeers containsObject:peer])
    {
        [self.targetPeers removeObject:peer];
    }
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
}

@end
