//
//  NSNumber+AMKLaunchTimeProfiler.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/5/9.
//

#import "NSNumber+AMKLaunchTimeProfiler.h"
#import "NSDate+AMKLaunchTimeProfiler.h"

@implementation NSNumber (AMKLaunchTimeProfiler)

#pragma mark - Init Methods

#pragma mark - Getters & Setters

- (NSDate *_Nullable)amkltp_dateWithTimeIntervalSince1970 {
    return [NSDate dateWithTimeIntervalSince1970:self.doubleValue];
}

- (NSString *_Nullable)amkltp_formattedDateStringForSystemTimeZone {
    return self.amkltp_dateWithTimeIntervalSince1970.amkltp_formattedStringForSystemTimeZone;
}

#pragma mark - Data & Networking

#pragma mark - Public Methods

#pragma mark - Private Methods

#pragma mark - Notifications

#pragma mark - KVO

#pragma mark - Protocol

#pragma mark - Overrides

#pragma mark - Helper Methods

@end
