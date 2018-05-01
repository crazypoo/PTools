//
//  PooActionOnCalendar.h
//  ActionOnCalendar
//
//  Created by crazypoo on 14-5-4.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PooActionOnCalendar : NSObject
+ (void)saveEventStartDate:(NSDate*)startData endDate:(NSDate*)endDate alarm:(float)alarm eventTitle:(NSString*)eventTitle location:(NSString*)location isReminder:(BOOL)isReminder;

@end
