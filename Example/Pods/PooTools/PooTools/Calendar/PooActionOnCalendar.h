//
//  PooActionOnCalendar.h
//  ActionOnCalendar
//
//  Created by crazypoo on 14-5-4.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PooActionOnCalendar : NSObject

/*! @brief 把数据插入到日历作提醒
 * @param startData 开始时间
 * @param endDate 结束时间
 * @param alarm 闹钟
 * @param eventTitle 事件标题
 * @param location 位置
 * @param isReminder 是否提醒
 */
+ (void)saveEventStartDate:(NSDate*)startData
                   endDate:(NSDate*)endDate
                     alarm:(float)alarm
                eventTitle:(NSString*)eventTitle
                  location:(NSString*)location
                isReminder:(BOOL)isReminder;
@end
