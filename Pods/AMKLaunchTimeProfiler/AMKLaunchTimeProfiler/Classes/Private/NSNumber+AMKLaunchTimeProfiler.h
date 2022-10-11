//
//  NSNumber+AMKLaunchTimeProfiler.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/5/9.
//

#import <Foundation/Foundation.h>

@interface NSNumber (AMKLaunchTimeProfiler)

- (NSDate *_Nullable)amkltp_dateWithTimeIntervalSince1970;

- (NSString *_Nullable)amkltp_formattedDateStringForSystemTimeZone;

@end
