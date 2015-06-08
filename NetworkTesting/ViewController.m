//
//  ViewController.m
//  NetworkTesting
//
//  Created by quarta on 06/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <NetworkManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *algLabel;
@property (weak, nonatomic) IBOutlet UISwitch *algSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *rcvPacketsSwitch;

@property (weak, nonatomic) IBOutlet UIButton *sendResultsButton;
@property (weak, nonatomic) IBOutlet UISwitch *nodeFailureSwitch;


@property (weak, nonatomic) IBOutlet UILabel *experimentNoLabel;
@property (weak, nonatomic) IBOutlet UIStepper *experimentNoModifier;

@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@property (weak, nonatomic) IBOutlet UIButton *endButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (weak, nonatomic) IBOutlet UIButton *broadcastButton;

@property (weak, nonatomic) IBOutlet UISwitch *displaySwitch;
@property (weak, nonatomic) IBOutlet UILabel *displayLabel;

@property (nonatomic, strong) NetworkManager *networkManager;

@property (nonatomic, strong) NSString *bufferLog;
@property (nonatomic, strong) NSString *bufferNeighbourhood;

@property (weak, nonatomic) IBOutlet UISwitch *msgSwitch;
@property (weak, nonatomic) IBOutlet UILabel *msgLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.broadcastButton.enabled = NO;
    self.rcvPacketsSwitch.on = NO;
    self.endButton.enabled = NO;
    self.nodeFailureSwitch.on = NO;
    
    self.displaySwitch.on = YES;
    self.displaySwitch.enabled = NO;
    
    self.sendResultsButton.enabled = YES;
    self.experimentNoModifier.enabled = YES;
    
    self.networkManager = [[NetworkManager alloc] init];
    self.networkManager.delegate = self;
    
    self.bufferLog = @"";
    self.bufferNeighbourhood = @"";
    
    self.msgSwitch.enabled = YES;
    self.msgSwitch.on = YES;
    
    [self.experimentNoLabel setText:[NSString stringWithFormat:@"Exp. no: %d", (int) self.experimentNoModifier.value]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)algValueChanged:(id)sender {
    if (self.algSwitch.on)
    {
        [self.algLabel setText:@"Flooding"];
    }
    else
    {
        [self.algLabel setText:@"6Shots"];
    }
}

- (IBAction)startPressed:(id)sender {
    self.experimentNoModifier.enabled = NO;
    self.sendResultsButton.enabled = NO;
    self.nodeFailureSwitch.enabled = NO;
    self.algSwitch.enabled = NO;
    self.rcvPacketsSwitch.enabled = NO;
    self.broadcastButton.enabled = YES;
    self.startButton.enabled = NO;
    self.endButton.enabled = YES;
    self.displaySwitch.enabled = YES;
    self.bufferLog = @"";
    self.bufferNeighbourhood = @"";
    self.msgSwitch.enabled = NO;
    [self updateDisplayText];
    
    [self.networkManager startWithExpNo:(int) self.experimentNoModifier.value
                           withFlooding:self.algSwitch.on
                        withNodeFailure:self.nodeFailureSwitch.on
                            withReceive:self.rcvPacketsSwitch.on
                             withStream:!self.msgSwitch.on];
}

- (IBAction)endPressed:(id)sender {
    self.experimentNoModifier.enabled = YES;
    self.sendResultsButton.enabled = YES;
    
    self.experimentNoModifier.value++;
    [self.experimentNoLabel setText:[NSString stringWithFormat:@"Exp. no: %d", (int) self.experimentNoModifier.value]];
    
    self.nodeFailureSwitch.enabled = YES;
    self.algSwitch.enabled = YES;
    self.rcvPacketsSwitch.enabled = YES;
    self.broadcastButton.enabled = NO;
    self.startButton.enabled = YES;
    self.endButton.enabled = NO;
    self.msgSwitch.enabled = YES;
    
    self.displaySwitch.enabled = NO;
    
    [self.networkManager end];
}

- (IBAction)broadcastPressed:(id)sender {
    [self.networkManager broadcast];
}


- (IBAction)expValueChanged:(id)sender {
    [self.experimentNoLabel setText:[NSString stringWithFormat:@"Exp. no: %d", (int) self.experimentNoModifier.value]];
}

- (IBAction)sendResultsPressed:(id)sender {
    [self.networkManager sendResults];
    self.sendResultsButton.enabled = NO;
}

- (IBAction)displayValueChanged:(id)sender {
    if (self.displaySwitch.on)
    {
        [self.displayLabel setText:@"Log"];
    }
    else
    {
        [self.displayLabel setText:@"Neighbourhood"];
    }

    [self updateDisplayText];
}


- (IBAction)msgValueChanged:(id)sender {
    if (self.msgSwitch.on)
    {
        [self.msgLabel setText:@"1 packet"];
    }
    else
    {
        [self.msgLabel setText:@"Stream"];
    }
}

#pragma mark - NetworkManagerDelegate methods
- (void)networkManager:(NetworkManager *)networkManager writeLine:(NSString *)msg
{
    self.bufferLog = [NSString stringWithFormat:@"%@%@\n", self.bufferLog, msg];

    [self updateDisplayText];
}

- (void)networkManager:(NetworkManager *)networkManager updateNeighbourhood:(NSArray *)neighbours
{
    self.bufferNeighbourhood = @"";
    
    for (id name in neighbours)
    {
        self.bufferNeighbourhood = [NSString stringWithFormat:@"%@%@\n", self.bufferNeighbourhood, name];
    }
    
    [self updateDisplayText];
}

#pragma mark - Text display helper methods
- (void)updateDisplayText
{
    if(self.displaySwitch.on)
    {
        [self.logTextView setText:self.bufferLog];
    }
    else
    {
        [self.logTextView setText:self.bufferNeighbourhood];
    }
    
    if(self.logTextView.text.length > 0)
    {
        NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
        [self.logTextView scrollRangeToVisible:range];
    }
}
@end
