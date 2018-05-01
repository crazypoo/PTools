//
//  PooActionOnCalendar.m
//  ActionOnCalendar
//
//  Created by crazypoo on 14-5-4.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import "PooActionOnCalendar.h"
#import <EventKit/EventKit.h>

@implementation PooActionOnCalendar

+ (void)saveEventStartDate:(NSDate*)startData endDate:(NSDate*)endDate alarm:(float)alarm eventTitle:(NSString*)eventTitle location:(NSString*)location isReminder:(BOOL)isReminder
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    //TODO: 6.0以後的方法
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        //TODO: 設置日曆提醒參數（只能真機）
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error)
                {
                }
                else if (!granted)
                {
                }
                else
                {
                    //TODO: 創建時間
                    EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                    event.title = eventTitle;
                    event.location = location;
                    //[NSDate dateWithTimeIntervalSinceNow:10];
                    event.startDate = startData;
                    //[NSDate dateWithTimeIntervalSinceNow:20];
                    event.endDate = endDate;
                    // event.allDay = YES;
                    [event addAlarm:[EKAlarm alarmWithRelativeOffset:alarm]];
                    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                    NSError *err;
                    [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
                    
                    NSLog(@"保存日历成功");
                    
                    if (isReminder)
                    {
                        EKCalendar * iDefaultCalendar = [eventStore defaultCalendarForNewReminders];
                        
                        EKReminder *reminder = [EKReminder reminderWithEventStore:eventStore];
                        reminder.calendar = [eventStore defaultCalendarForNewReminders];
                        
                        reminder.title = eventTitle;
                        reminder.calendar = iDefaultCalendar;
                        EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:[NSDate dateWithTimeIntervalSinceNow:-10]];
                        [reminder addAlarm:alarm];
                        NSError *error = nil;
                        
                        [eventStore saveReminder:reminder commit:YES error:&error];
                        if (error)
                        {
                            NSLog(@"error=%@",error);
                        }
                    }
                }
            });
        }];
    }
    else
    {
        //TODO:IOS6以下操作方式
        EKEvent *event = [EKEvent eventWithEventStore:eventStore];
        event.title = eventTitle;
        event.location = location;
        //[NSDate dateWithTimeIntervalSinceNow:10];
        event.startDate = startData;
        
        //[NSDate dateWithTimeIntervalSinceNow:20];
        event.endDate = endDate;
        // event.allDay = YES;
        [event addAlarm:[EKAlarm alarmWithRelativeOffset:alarm]];
        
        [event setCalendar:[eventStore defaultCalendarForNewEvents]];
        NSError *err;
        [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
        NSLog(@"保存成功");
        
        if (isReminder)
        {
            EKCalendar * iDefaultCalendar = [eventStore defaultCalendarForNewReminders];
            EKReminder *reminder = [EKReminder reminderWithEventStore:eventStore];
            reminder.calendar = [eventStore defaultCalendarForNewReminders];
            reminder.title = eventTitle;
            reminder.calendar = iDefaultCalendar;
            EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:[NSDate dateWithTimeIntervalSinceNow:-10]];
            [reminder addAlarm:alarm];
            NSError *error = nil;
            
            [eventStore saveReminder:reminder commit:YES error:&error];
            if (error)
            {
                NSLog(@"error=%@",error);
            }
        }
    }
}
@end
