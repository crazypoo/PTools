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
    static let PTEventError = NSError(domain: "Not suppor", code: 0)
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
                                remindTime:TimeInterval) async throws {
        return try await withUnsafeThrowingContinuation { continuation in
            PTEventOnCalendar.createEvent(startDate: startDate, endDate: endDate, eventTitle: eventTitle, location: location, notes: notes, eventType: eventType, remindTime: remindTime) { finish, error in
                if error != nil {
                    continuation.resume(throwing: error!)
                }
            }
        }
    }
    
    open class func createEvent(startDate:DateInRegion,
                                endDate:DateInRegion,
                                eventTitle:String,
                                location:String,
                                notes:String,
                                eventType:EKEntityType,
                                remindTime:TimeInterval,
                                handle:((_ finish:Bool,_ error:Error?)->Void)? = nil) {
        let eventStore = EKEventStore()
        if #available(iOS 17.0, *) {
            switch eventType {
            case .event:
                switch PTPermission.calendar(access: .full).status {
                case .authorized:
                    eventStore.requestFullAccessToEvents { granted, error in
                        PTEventOnCalendar.eventCreateFunction(eventStore: eventStore, startDate: startDate, endDate: endDate, eventTitle: eventTitle, location: location, notes: notes, remindTime: remindTime,handle: handle)
                    }
                case .denied:
                    switch PTPermission.calendar(access: .write).status {
                    case .authorized:
                        eventStore.requestWriteOnlyAccessToEvents { granted, error in
                            PTEventOnCalendar.eventCreateFunction(eventStore: eventStore, startDate: startDate, endDate: endDate, eventTitle: eventTitle, location: location, notes: notes, remindTime: remindTime,handle: handle)
                        }
                    default:
                        if handle != nil {
                            handle!(false,PTEventOnCalendar.PTEventError)
                        }
                    }
                default:
                    if handle != nil {
                        handle!(false,PTEventOnCalendar.PTEventError)
                    }
                }
            case .reminder:
                eventStore.requestFullAccessToReminders { granted, error in
                    PTEventOnCalendar.remindCreateFunction(eventStore: eventStore, startDate: startDate, endDate: endDate, eventTitle: eventTitle, location: location, notes: notes, remindTime: remindTime, handle: handle)
                }
            @unknown default:
                break
            }
        } else {
            eventStore.requestAccess(to: eventType) { granted, error in
                if granted && error == nil {
                    switch eventType {
                    case .event:
                        PTEventOnCalendar.eventCreateFunction(eventStore: eventStore, startDate: startDate, endDate: endDate, eventTitle: eventTitle, location: location, notes: notes, remindTime: remindTime,handle: handle)
                    case .reminder:
                        PTEventOnCalendar.remindCreateFunction(eventStore: eventStore, startDate: startDate, endDate: endDate, eventTitle: eventTitle, location: location, notes: notes, remindTime: remindTime, handle: handle)
                    default:
                        break
                    }
                } else {
                    if handle != nil {
                        handle!(false,error)
                    }
                }
            }
        }
    }
    
    class func eventCreateFunction(eventStore:EKEventStore,
                                   startDate:DateInRegion,
                                   endDate:DateInRegion,
                                   eventTitle:String,
                                   location:String,
                                   notes:String,
                                   remindTime:TimeInterval,
                                   handle:((_ finish:Bool,_ error:Error?)->Void)? = nil) {
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
    }
    
    class func remindCreateFunction(eventStore:EKEventStore,
                                   startDate:DateInRegion,
                                   endDate:DateInRegion,
                                   eventTitle:String,
                                   location:String,
                                   notes:String,
                                   remindTime:TimeInterval,
                                   handle:((_ finish:Bool,_ error:Error?)->Void)? = nil) {
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
    }
}
