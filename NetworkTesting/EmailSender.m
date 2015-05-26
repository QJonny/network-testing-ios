
//
//  EmailSender.m
//  NetworkTesting
//
//  Created by quarta on 22/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#import "EmailSender.h"


@interface EmailSender () <SKPSMTPMessageDelegate>


@end


#pragma mark - Singleton static variables

static EmailSender *sender = nil;



@implementation EmailSender

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {

    }
    return self;
}

- (void)dealloc
{
    
}


#pragma mark - Singleton methods
+ (EmailSender*)getSingleton
{
    if (sender == nil)
    {
        // Initialize the email sender singleton
        sender = [[EmailSender alloc] init];
    }
    
    return sender;
}




#pragma mark - Email sending
-(void) sendEmailWithBody:(NSString *)messageBody withExpNo:(int)expNo {
    
    SKPSMTPMessage *emailMessage = [[SKPSMTPMessage alloc] init];
    emailMessage.fromEmail = SMTP_USER; //sender email address
    emailMessage.toEmail = SMTP_USER;  //receiver email address
    emailMessage.relayHost = SMTP_SERVER;
    
    emailMessage.requiresAuth = YES;
    emailMessage.login = SMTP_USER; //sender email address
    emailMessage.pass = SMTP_PWD; //sender email password
    emailMessage.subject = [NSString stringWithFormat:@"From [%@]: Experiment %d", [UIDevice currentDevice].name, expNo];
    emailMessage.wantsSecure = YES;
    emailMessage.delegate = self;
    
    // Now creating plain text email message
    NSDictionary *plainMsg = [NSDictionary
                              dictionaryWithObjectsAndKeys:@"text/plain",kSKPSMTPPartContentTypeKey,
                              messageBody,kSKPSMTPPartMessageKey,@"8bit",kSKPSMTPPartContentTransferEncodingKey,nil];
    emailMessage.parts = [NSArray arrayWithObjects:plainMsg,nil];
    
    [emailMessage send];
    // sending email- will take little time to send so its better to use indicator with message showing sending...
}

-(void)messageSent:(SKPSMTPMessage *)message
{
    NSLog (@"Message sent.");
}

// On Failure
-(void)messageFailed:(SKPSMTPMessage *)message error:(NSError *)error
{
    // open an alert with just an OK button
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];

    
    // We try to resend the message in case of an error
    SKPSMTPMessage *emailMessage = [[SKPSMTPMessage alloc] init];
    emailMessage.fromEmail = SMTP_USER; //sender email address
    emailMessage.toEmail = SMTP_USER;  //receiver email address
    emailMessage.relayHost = SMTP_SERVER;
    
    emailMessage.requiresAuth = YES;
    emailMessage.login = SMTP_USER; //sender email address
    emailMessage.pass = SMTP_PWD; //sender email password
    emailMessage.subject = message.subject;
    emailMessage.wantsSecure = YES;
    emailMessage.delegate = self;
    
    emailMessage.parts = message.parts;
    
    [emailMessage send];
}

@end
