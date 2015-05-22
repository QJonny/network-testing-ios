//
//  EmailSender.h
//  NetworkTesting
//
//  Created by quarta on 22/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef NetworkTesting_EmailSender_h
#define NetworkTesting_EmailSender_h


#import <Foundation/Foundation.h>

// Email sending
#import "SKPSMTPMessage.h"
#import "NSData+Base64Additions.h" // for Base64 encoding


#define SMTP_SERVER @"smtp.live.com"
#define SMTP_USER @"react.group@hotmail.com"
#define SMTP_PWD @"reactgroup1234"


@interface EmailSender : NSObject

- (instancetype)init;

+ (EmailSender*)getSingleton;

-(void) sendEmailWithBody:(NSString *)messageBody withExpNo:(int)expNo;

@end


#endif
