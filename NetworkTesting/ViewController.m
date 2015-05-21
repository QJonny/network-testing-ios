//
//  ViewController.m
//  NetworkTesting
//
//  Created by quarta on 06/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <NetworkManagerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UIButton *endButton;

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *broadcastButton;
@property (weak, nonatomic) IBOutlet UISwitch *nodeFailureSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *floodingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *shotsSwitch;

@property (nonatomic, strong) NetworkManager *networkManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.broadcastButton.enabled = NO;
    self.shotsSwitch.on = NO;
    self.endButton.enabled = NO;
    self.nodeFailureSwitch.on = NO;
    
    self.networkManager = [[NetworkManager alloc] init];
    self.networkManager.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startPressed:(id)sender {
    self.nodeFailureSwitch.enabled = NO;
    self.floodingSwitch.enabled = NO;
    self.shotsSwitch.enabled = NO;
    self.broadcastButton.enabled = YES;
    self.startButton.enabled = NO;
    self.endButton.enabled = YES;
    [self.logTextView setText:@""];
    
    [self.networkManager startWithFlooding:self.floodingSwitch.on withNodeFailure:self.nodeFailureSwitch.on];
}

- (IBAction)endPressed:(id)sender {
    self.nodeFailureSwitch.enabled = YES;
    self.floodingSwitch.enabled = YES;
    self.shotsSwitch.enabled = YES;
    self.broadcastButton.enabled = NO;
    self.startButton.enabled = YES;
    self.endButton.enabled = NO;
    
    [self.networkManager end];
}

- (IBAction)broadcastPressed:(id)sender {
    [self.networkManager broadcast];
}


- (IBAction)floodingValueChanged:(id)sender {
    self.shotsSwitch.on = !self.floodingSwitch.on;
}

- (IBAction)shotsValueChanged:(id)sender {
    self.floodingSwitch.on = !self.shotsSwitch.on;
}


#pragma mark - NetworkManagerDelegate methods
- (void)networkManager:(NetworkManager *)networkManager writeText:(NSString *)text
{
    [self.logTextView setText:text];
    
    if(self.logTextView.text.length > 0)
    {
        NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
        [self.logTextView scrollRangeToVisible:range];
    }
}

@end
