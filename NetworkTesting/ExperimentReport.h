//
//  Experiment.h
//  NetworkTesting
//
//  Created by quarta on 21/05/15.
//  Copyright (c) 2015 quarta. All rights reserved.
//

#ifndef NetworkTesting_ExperimentReport_h
#define NetworkTesting_ExperimentReport_h

#import <Foundation/Foundation.h>
#import "EmailSender.h"


@interface ExperimentReport: NSObject

@property (nonatomic, readonly) int expNo;

- (instancetype)initWithNo:(int)expNo;


- (void)writeLine:(NSString *)msg;

- (void)writeTraceInfo:(NSArray *)traceInfo;


- (void)send;

@end


#endif
