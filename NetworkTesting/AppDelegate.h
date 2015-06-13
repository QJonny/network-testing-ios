//
//  AppDelegate.h
//  NetworkTesting
//
//  Created by quarta on 06/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MHSocket.h"

#import "LogglyLogger.h"
#import "LogglyFormatter.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)setNetworkSocket:(MHSocket *)socket;

@end

