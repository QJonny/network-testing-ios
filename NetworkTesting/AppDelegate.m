//
//  AppDelegate.m
//  NetworkTesting
//
//  Created by quarta on 06/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (nonatomic, strong) MHUnicastSocket *uSocket;
@property (nonatomic, strong) MHMulticastSocket *mSocket;

@end

@implementation AppDelegate


- (void)setUniSocket:(MHUnicastSocket *)socket
{
    self.uSocket = socket;
}

- (void)setMultiSocket:(MHMulticastSocket *)socket
{
    self.mSocket = socket;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    if(self.uSocket != nil)
    {
        [self.uSocket applicationWillResignActive];
    }
    
    if(self.mSocket != nil)
    {
        [self.mSocket applicationWillResignActive];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if(self.uSocket != nil)
    {
        [self.uSocket applicationDidBecomeActive];
    }
    
    if(self.mSocket != nil)
    {
        [self.mSocket applicationDidBecomeActive];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    if(self.uSocket != nil)
    {
        [self.uSocket applicationWillTerminate];
    }
    
    if(self.mSocket != nil)
    {
        [self.mSocket applicationWillTerminate];
    }
}

@end
