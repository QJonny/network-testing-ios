//
//  NetworkManager.h
//  NetworkTesting
//
//  Created by quarta on 20/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef NetworkTesting_NetworkManager_h
#define NetworkTesting_NetworkManager_h

#import "AppDelegate.h"
#import "MHDiagnostics.h"
#import "MHMulticastSocket.h"
#import "MHUnicastSocket.h"

#import "ExperimentReport.h"


#define GROUP_RCV @"group_rcv"
#define GROUP_NOT_RCV @"group_not_rcv"

@protocol NetworkManagerDelegate;


@interface NetworkManager: NSObject

@property (nonatomic, weak) id<NetworkManagerDelegate> delegate;

- (instancetype)init;

- (void)startWithExpNo:(int)expNo
          withFlooding:(BOOL)isFlooding
       withNodeFailure:(BOOL)nodeFailure
           withReceive:(BOOL)receivePackets;
- (void)end;
- (void)broadcast;

- (void)sendResults;

@end



@protocol NetworkManagerDelegate <NSObject>

@required
- (void)networkManager:(NetworkManager *)networkManager
   writeLine:(NSString *)msg;
@end

#endif
