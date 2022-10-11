//
//  NSDate+AMKLaunchTimeProfiler.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/23.
//

#import "NSDate+AMKLaunchTimeProfiler.h"

@implementation NSDate (AMKLaunchTimeProfiler)

#pragma mark - Init Methods

#pragma mark - Getters & Setters

#pragma mark - Data & Networking

#pragma mark - Public Methods

- (NSDate *)amkltp_dateForSystemTimeZone {
    NSInteger interval = [NSTimeZone.systemTimeZone secondsFromGMTForDate:self];
    NSDate *localeDate = [self dateByAddingTimeInterval:interval];
    return localeDate;
}

- (NSString *)amkltp_formattedStringForSystemTimeZone {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter.alloc init];
        dateFormatter.timeZone = NSTimeZone.systemTimeZone;
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    });
    return [dateFormatter stringFromDate:self];
}

- (NSString *_Nullable)amkltp_stringForTimestamp {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter.alloc init];
        dateFormatter.timeZone = NSTimeZone.systemTimeZone;
        dateFormatter.dateFormat = @"yyyyMMddHHmmss";
    });
    return [dateFormatter stringFromDate:self];
}

#pragma mark - Private Methods

#pragma mark - Notifications

#pragma mark - KVO

#pragma mark - Protocol

#pragma mark - Overrides

#pragma mark - Helper Methods

@end
