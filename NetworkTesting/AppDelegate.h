//
//  AppDelegate.h
//  NetworkTesting
//
//  Created by quarta on 06/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MHUnicastSocket.h"
#import "MHMulticastSocket.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)setUniSocket:(MHUnicastSocket *)socket;
- (void)setMultiSocket:(MHMulticastSocket *)socket;

@end

