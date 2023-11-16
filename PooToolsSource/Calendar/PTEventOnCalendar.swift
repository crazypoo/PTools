//
//  PTEventOnCalendar.swift
//  MinaTicket
//
//  Created by jax on 2022/8/24.
//  Copyright © 2022 Hola. All rights reserved.
//

import UIKit
import EventKit
import SwiftDate

@objcMembers
public class PTEventOnCalendar: NSObject {
    //MARK: 把数据插入到日历作提醒
    ///把数据插入到日历作提醒
    /// - Parameters:
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    ///   - eventTitle: 标题
    ///   - location: 地址
    ///   - notes: 备注
    ///   - eventType: 提醒类型
    ///   - remindTime: 大于0是开始后提醒,小于0就开始时间前提醒
    ///   - handle: 成功回调
    open class func createEvent(startDate:DateInRegion,
                                endDate:DateInRegion,
                                eventTitle:String,
                                location:String,
                                notes:String,
                                eventType:EKEntityType,
                                remindTime:TimeInterval,
                                handle:((_ finish:Bool,_ error:Error?)->Void)? = nil) {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: eventType) { granted, error in
            if granted && error == nil {
                switch eventType {
                case .event:
                    let event = EKEvent.init(eventStore: eventStore)
                    event.title = eventTitle
                    event.location = location
                    event.startDate = startDate.date
                    event.endDate = endDate.date
                    event.notes = notes
                    event.addAlarm(EKAlarm.init(relativeOffset: remindTime))
                    event.calendar = eventStore.defaultCalendarForNewEvents

                    do {
                        try eventStore.save(event, span: .thisEvent)
                        PTGCDManager.gcdAfter(time: 0.2) {
                            if handle != nil {
                                handle!(true,nil)
                            }
                        }
                    } catch {
                        PTGCDManager.gcdAfter(time: 0.2) {
                            if handle != nil {
                                handle!(false,error)
                            }
                        }
                    }
                case .reminder:
                    let event = EKReminder.init(eventStore: eventStore)
                    event.title = eventTitle
                    event.location = location
                    event.startDateComponents = startDate.date.dateComponents
                    event.dueDateComponents = endDate.date.dateComponents
                    event.notes = notes
                    event.priority = 1
                    event.addAlarm(EKAlarm.init(absoluteDate: (startDate - abs(remindTime).int.seconds).date))
                    event.calendar = eventStore.defaultCalendarForNewReminders()
                    do {
                        try eventStore.save(event, commit: true)
                        PTGCDManager.gcdAfter(time: 0.2) {
                            if handle != nil {
                                handle!(true,nil)
                            }
                        }
                    } catch {
                        PTGCDManager.gcdAfter(time: 0.2) {
                            if handle != nil {
                                handle!(false,error)
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
