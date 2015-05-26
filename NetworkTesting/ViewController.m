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

@property (nonatomic, strong) NetworkManager *networkManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.broadcastButton.enabled = NO;
    self.rcvPacketsSwitch.on = NO;
    self.endButton.enabled = NO;
    self.nodeFailureSwitch.on = NO;
    
    self.sendResultsButton.enabled = YES;
    self.experimentNoModifier.enabled = YES;
    
    self.networkManager = [[NetworkManager alloc] init];
    self.networkManager.delegate = self;
    
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
    [self.logTextView setText:@""];
    
    [self.networkManager startWithExpNo:(int) self.experimentNoModifier.value withFlooding:self.algSwitch.on withNodeFailure:self.nodeFailureSwitch.on withReceive:self.rcvPacketsSwitch.on];
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

#pragma mark - NetworkManagerDelegate methods
- (void)networkManager:(NetworkManager *)networkManager writeLine:(NSString *)msg
{
    [self.logTextView setText:[NSString stringWithFormat:@"%@%@\n", self.logTextView.text, msg]];
    
    if(self.logTextView.text.length > 0)
    {
        NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
        [self.logTextView scrollRangeToVisible:range];
    }
}

@end
