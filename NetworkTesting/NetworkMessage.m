//
//  NetworkMessage.m
//  NetworkTesting
//
//  Created by quarta on 08/06/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//
#import "NetworkMessage.h"

@interface NetworkMessage ()

@end

@implementation NetworkMessage

- (instancetype)initWithPayload:(NSString *)payload
{
    self = [super init];
    if (self)
    {
        self.displayName = [UIDevice currentDevice].name;
        self.tag = [NetworkMessage generateTag];
        self.payload = payload;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.displayName = [decoder decodeObjectForKey:@"displayName"];
        self.tag = [decoder decodeIntForKey:@"tag"];
        self.payload = [decoder decodeObjectForKey:@"payload"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.displayName forKey:@"displayName"];
    [encoder encodeInt:self.tag forKey:@"tag"];
    [encoder encodeObject:self.payload forKey:@"payload"];
}


- (void)dealloc
{
}





- (NSData *)asNSData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    
    return data;
}

+ (int)generateTag
{
    return arc4random_uniform(99999) + 1;
}

+ (NetworkMessage *)fromNSData:(NSData *)nsData
{
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:nsData];
    
    if([object isKindOfClass:[NetworkMessage class]])
    {
        NetworkMessage *message = object;
        
        return message;
    }
    else
    {
        return nil;
    }
}

@end
