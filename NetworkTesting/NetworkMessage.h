//
//  NetworkMessage.h
//  NetworkTesting
//
//  Created by quarta on 08/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef NetworkTesting_NetworkMessage_h
#define NetworkTesting_NetworkMessage_h


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NetworkMessage : NSObject<NSCoding>

@property (nonatomic, readwrite) NSString *displayName;
@property (nonatomic, readwrite) int tag;
@property (nonatomic, readwrite) NSString *payload;


- (instancetype)initWithPayload:(NSString *)payload;

- (NSData *)asNSData;


+ (NetworkMessage *)fromNSData:(NSData *)nsData;
@end


#endif
