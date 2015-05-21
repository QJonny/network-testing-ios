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

// Email sending
#import "SKPSMTPMessage.h"
#import "NSData+Base64Additions.h" // for Base64 encoding


#define SMTP_SERVER @"smtp.live.com"
#define SMTP_USER @"react.group@hotmail.com"
#define SMTP_PWD @"reactgroup1234"



@protocol NetworkManagerDelegate;


@interface NetworkManager: NSObject

@property (nonatomic, weak) id<NetworkManagerDelegate> delegate;

- (instancetype)init;

- (void)startWithFlooding:(BOOL)isFlooding withNodeFailure:(BOOL)nodeFailure;
- (void)end;
- (void)broadcast;

@end



@protocol NetworkManagerDelegate <NSObject>

@required
- (void)networkManager:(NetworkManager *)networkManager
   writeText:(NSString *)text;
@end

#endif
