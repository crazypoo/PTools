//
//  PHealthKit.m
//  adasdasdadadasdasdadadadad
//
//  Created by MYX on 2017/4/21.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import "PHealthKit.h"

@interface PHealthKit ()

@property (nonatomic,assign) double stepCount;
@property (nonatomic,assign) BOOL isLoad;
@property (nonatomic,strong) NSString *stepStr;

@end

@implementation PHealthKit

+ (instancetype)shareInstance {
    
    static PHealthKit *kitManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kitManager = [[PHealthKit alloc] init];
        [kitManager initSetting];
    });
    return kitManager;
}

- (void)initSetting {
    
    self.isLoad = NO;
    if ([HKHealthStore isHealthDataAvailable])
    {
        NSSet *readDataTypes = [self dataTypesToRead];
        
        if (!_healthStore) {
            _healthStore = [HKHealthStore new];
        }
        
        [_healthStore requestAuthorizationToShareTypes:nil readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"You didn't allow HealthKit to access these read data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"The user allow the app to read information about StepCount");
            });
        }];

    }
    else
    {
        NSLog(@"HKHealthStore is not available");
    }
    
    [self stepAllCount];
}

-(NSSet *)dataTypesToRead {
    HKQuantityType *stepType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    return [NSSet setWithObjects:stepType, nil];
}

-(void)stepAllCount
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *interval = [[NSDateComponents alloc] init];
    interval.day = 1;
    
    self.stepCount = 0;
    NSDateComponents *anchorComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                     fromDate:[NSDate date]];
    anchorComponents.hour = 0;
    NSDate *anchorDate = [calendar dateFromComponents:anchorComponents];
    HKQuantityType *quantityType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    HKStatisticsCollectionQuery *query =
    [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType
                                      quantitySamplePredicate:nil
                                                      options:HKStatisticsOptionCumulativeSum
                                                   anchorDate:anchorDate
                                           intervalComponents:interval];
    
    query.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection *results, NSError *error) {
        if (error) {
            NSLog(@"*** An error occurred while calculating the statistics: %@ ***",error.localizedDescription);
        }
        
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:( NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:[[NSDate alloc] init]];
        
        [components setHour:-[components hour]];
        [components setMinute:-[components minute]];
        [components setSecond:-[components second]];
        NSDate *today = [cal dateByAddingComponents:components toDate:[[NSDate alloc] init] options:NSCalendarMatchLast];
        
        NSDateComponents *component = [cal components:( NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:[[NSDate alloc] init]];
        
        [component setHour:23];
        [component setMinute:59];
        [component setSecond:59];
        NSDate *todayEnd = [cal dateByAddingComponents:component toDate: today options:0];
        
        [results enumerateStatisticsFromDate:today toDate:todayEnd withBlock:^(HKStatistics *result, BOOL *stop) {
            HKQuantity *quantity = result.sumQuantity;
            
            if (quantity) {
                double value = [quantity doubleValueForUnit:[HKUnit countUnit]];
                self.stepCount = self.stepCount + value;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.stepStr = [NSString stringWithFormat:@"%@",[NSNumberFormatter localizedStringFromNumber:@(self.stepCount) numberStyle:NSNumberFormatterNoStyle]];
                self.isLoad = YES;
                
                if ([self.delegate respondsToSelector:@selector(kitDataIsload:stepStr:)]) {
                    [self.delegate kitDataIsload:self.isLoad stepStr:self.stepStr];
                }
            });
        }];
    };
    [_healthStore executeQuery:query];
}

@end
