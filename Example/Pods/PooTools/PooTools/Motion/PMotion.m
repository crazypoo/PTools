//
//  PMotion.m
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/21.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PMotion.h"
#import <CoreMotion/CoreMotion.h>
#import "Utils.h"

static PMotion *pmotion = nil;

@interface PMotion()
@property (nonatomic, strong) CMMotionActivityManager *activityManager;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSString *stepCountStr;
@property (nonatomic, strong) NSString *stepStatusStr;
@property (nonatomic, strong) NSString *stepSpeedStr;
@property (nonatomic, strong) CMPedometer *pedometer;
@end

@implementation PMotion

+(instancetype)defaultMonitor
{
    @synchronized (self) {
        if (!pmotion) {
            pmotion = [[PMotion alloc] init];
        }
        return pmotion;
    }
}

-(void)getMotion
{
    [self startAct];
}

-(void)startAct
{
    if (!([CMPedometer isStepCountingAvailable] || [CMMotionActivityManager isActivityAvailable]))
    {
        NSString *msg = @"哎喲，不能運行哦,僅支持M7以上處理器, 所以暫時只能在iPhone5s以上玩哦.";
        [Utils alertShowWithMessage:msg];
        
        return;
    }
    
    self.operationQueue = [[NSOperationQueue alloc] init];

    if ([CMPedometer isStepCountingAvailable]) {
        
        self.pedometer = [[CMPedometer alloc]init];
        
        [self.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            
            CMPedometerData *data = (CMPedometerData *)pedometerData;
            
            NSNumber *number = data.numberOfSteps;
            
            self.stepCountStr = [NSString stringWithFormat:@"%@",number];

        }];
        
    }

    if ([CMMotionActivityManager isActivityAvailable]) {
        
        self.activityManager = [[CMMotionActivityManager alloc] init];
        
        [self.activityManager startActivityUpdatesToQueue:self.operationQueue withHandler:^(CMMotionActivity *activity){
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 self.stepStatusStr = [self statusForActivity:activity];
                 self.stepSpeedStr = [self stringFromConfidence:activity.confidence];
                 
                 if ([self.delegate respondsToSelector:@selector(callBackWithStep:status:speed:)]) {
                     [self.delegate callBackWithStep:self.stepCountStr status:self.stepStatusStr speed:self.stepSpeedStr];
                 }
             });
         }];
    }
    
    
}

- (NSString *)statusForActivity:(CMMotionActivity *)activity {
    
    NSMutableString *status = @"".mutableCopy;
    
    if (activity.stationary) {
        
        [status appendString:@"not moving"];
    }
    
    if (activity.walking) {
        
        if (status.length) [status appendString:@", "];
        
        [status appendString:@"on a walking person"];
    }
    
    if (activity.running) {
        
        if (status.length) [status appendString:@", "];
        
        [status appendString:@"on a running person"];
    }
    
    if (activity.automotive) {
        
        if (status.length) [status appendString:@", "];
        
        [status appendString:@"in a vehicle"];
    }
    
    if (activity.unknown || !status.length) {
        
        [status appendString:@"unknown"];
    }
    
    return status;
}

- (NSString *)stringFromConfidence:(CMMotionActivityConfidence)confidence {
    
    switch (confidence) {
            
        case CMMotionActivityConfidenceLow:
            
            return @"Low";
            
        case CMMotionActivityConfidenceMedium:
            
            return @"Medium";
            
        case CMMotionActivityConfidenceHigh:
            
            return @"High";
            
        default:
            
            return nil;
    }
}
@end
