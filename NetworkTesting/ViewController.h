//
//  ViewController.h
//  NetworkTesting
//
//  Created by quarta on 06/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import <UIKit/UIKit.h>
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

@interface ViewController : UIViewController


@end

