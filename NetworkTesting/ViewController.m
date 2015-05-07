//
//  ViewController.m
//  NetworkTesting
//
//  Created by quarta on 06/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UIButton *endButton;

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *broadcastButton;
@property (weak, nonatomic) IBOutlet UISwitch *nodeFailureSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *floodingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *shotsSwitch;

@property (nonatomic, strong) NSString *group;
@property (nonatomic) BOOL started;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.started = NO;
    self.broadcastButton.enabled = NO;
    self.endButton.enabled = NO;
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
}

- (IBAction)endPressed:(id)sender {
    self.started = NO;
    self.nodeFailureSwitch.enabled = YES;
    self.floodingSwitch.enabled = YES;
    self.shotsSwitch.enabled = YES;
    self.broadcastButton.enabled = NO;
    self.startButton.enabled = YES;
    self.endButton.enabled = NO;
}

- (IBAction)broadcastPressed:(id)sender {
}


- (IBAction)floodingValueChanged:(id)sender {
    self.shotsSwitch.on = !self.floodingSwitch.on;
}

- (IBAction)shotsValueChanged:(id)sender {
    self.floodingSwitch.on = self.shotsSwitch.on;
}
@end
