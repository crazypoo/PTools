//
//  NSDate+AMKLaunchTimeProfiler.h
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/3/23.
//

#import <Foundation/Foundation.h>

@interface NSDate (AMKLaunchTimeProfiler)

- (NSDate *_Nullable)amkltp_dateForSystemTimeZone;

- (NSString *_Nullable)amkltp_formattedStringForSystemTimeZone;

- (NSString *_Nullable)amkltp_stringForTimestamp;

@end
