//
//  Experiment.m
//  NetworkTesting
//
//  Created by quarta on 21/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//


#import "ExperimentReport.h"


@interface ExperimentReport ()

@property (nonatomic, readwrite) int expNo;
@property (nonatomic, strong) NSString *writeBuffer;
@property (nonatomic, strong) NSMutableArray *traceInfos;

@end

@implementation ExperimentReport

- (instancetype)initWithNo:(int)expNo
{
    self = [super init];
    
    if (self)
    {
        self.expNo = expNo;
        self.writeBuffer = @"";
        self.traceInfos = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (void)dealloc
{
    self.writeBuffer = nil;
    [self.traceInfos removeAllObjects];
    self.traceInfos = nil;
}



- (void)writeLine:(NSString *)msg
{
    self.writeBuffer = [NSString stringWithFormat:@"%@%@;\n", self.writeBuffer, msg];
}

- (void)writeTraceInfo:(NSArray *)traceInfo
{
    [self.traceInfos addObject:traceInfo];
}


- (void)send
{
    for (int i = 0; i < self.traceInfos.count; i++)
    {
        NSArray *traceInfo = [self.traceInfos objectAtIndex:i];
        
        [self writeLine:[NSString stringWithFormat:@"Trace info of received packet no %d",i+1]];
        
        for (id node in traceInfo)
        {
            [self writeLine:node];
        }
    }
    
    NSString* log = [NSString stringWithFormat:@"{\"exp\":\"%d\", \"message\":\"%@\"}", self.expNo, self.writeBuffer];
    DDLogVerbose(log);
}



@end