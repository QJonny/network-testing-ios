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

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.displayName = [UIDevice currentDevice].name;
        self.tag = [NetworkMessage generateTag];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.displayName = [decoder decodeObjectForKey:@"displayName"];
        self.tag = [decoder decodeObjectForKey:@"tag"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.displayName forKey:@"displayName"];
    [encoder encodeObject:self.tag forKey:@"tag"];
}


- (void)dealloc
{
}





- (NSData *)asNSData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    
    return data;
}

+ (NSString *)generateTag
{
    return [NSString stringWithFormat:@"%d", arc4random_uniform(100000)];
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
