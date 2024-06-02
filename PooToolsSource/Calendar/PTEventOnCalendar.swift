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
    
    /// 事件主线程
    /// - Parameters:
    ///   - parameter: 返回的参数
    ///   - eventsClosure: 闭包
    private static func resultMain<T>(parameter: T, eventsClosure: @escaping ((T) -> Void)) {
        PTGCDManager.gcdMain {
            eventsClosure(parameter)
        }
    }
    
    /// 根据NSDate获取对应的DateComponents对象
    static func dateComponentFrom(date: Date) -> DateComponents {
        let cal = Calendar.current
        let dateComponents = cal.dateComponents([.minute, .hour, .day, .month, .year], from: date)
        return dateComponents
    }
    
    /// 指定年月的开始日期
    static func startOfMonth(year: Int, month: Int) -> Date {
        let calendar = Calendar.current
        var startComps = DateComponents()
        startComps.day = 1
        startComps.month = month
        startComps.year = year
        let startDate = calendar.date(from: startComps)!
        return startDate
    }
    
    /// 指定年月的结束日期
    static func endOfMonth(year: Int, month: Int, returnEndTime: Bool = false) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        if returnEndTime {
            components.second = -1
        } else {
            components.day = -1
        }
        let tem = startOfMonth(year: year, month: month)
        let endOfYear =  calendar.date(byAdding: components, to: tem)!
        return endOfYear
    }

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
    public class func createEvent(startDate:DateInRegion,
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
    
    public class func createEvent(startDate:DateInRegion,
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
            
    // MARK: 根据时间段获取日历事件
    /// 根据时间段获取日历事件
    /// - Parameters:
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    ///   - eventsClosure: 事件闭包
    static func selectCalendarsEvents(startDate: Date, endDate: Date, eventsClosure: @escaping (([EKEvent]) -> Void)) {
        let eventStore = EKEventStore()
        // 请求日历事件
        eventStore.requestAccess(to: .event, completion: {
            granted, error in
            if (granted) && (error == nil) {
                // 获取本地日历（剔除节假日，生日等其他系统日历）
                let calendars = eventStore.calendars(for: .event).filter({
                    (calender) -> Bool in
                    return calender.type == .local || calender.type == .calDAV
                })
                let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
                let eV = eventStore.events(matching: predicate)
                resultMain(parameter: eV, eventsClosure: eventsClosure)
            } else {
                resultMain(parameter: [], eventsClosure: eventsClosure)
            }
        })
    }
    
    // MARK: 修改日历事件
    /// 修改日历事件
    /// - Parameters:
    ///   - eventIdentifier: 唯一标识符区分某个事件
    ///   - title: 提醒的标题
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    ///   - notes: 备注
    ///   - eventsClosure: 事件闭包
    static func updateCalendarsEvents(eventIdentifier: String, title: String, startDate: Date, endDate: Date, notes: String, eventsClosure: @escaping ((Bool) -> Void)) {
        let eventStore = EKEventStore()
        // 请求日历事件
        eventStore.requestAccess(to: .event, completion: {
            granted, error in
            if (granted) && (error == nil) {
                // 获取本地日历（剔除节假日，生日等其他系统日历）
                let calendars = eventStore.calendars(for: .event).filter({
                    (calender) -> Bool in
                    return calender.type == .local || calender.type == .calDAV
                })
                let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
                let events = eventStore.events(matching: predicate)
                let eventArray = events.filter { $0.calendarItemIdentifier == eventIdentifier }
                guard eventArray.count > 0 else {
                    resultMain(parameter: false, eventsClosure: eventsClosure)
                    return
                }
                let event = eventArray[0]
                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.notes = notes
                event.calendar = eventStore.defaultCalendarForNewEvents
                do {
                    try eventStore.save(event, span: .thisEvent)
                    resultMain(parameter: true, eventsClosure: eventsClosure)
                } catch {
                    resultMain(parameter: false, eventsClosure: eventsClosure)
                }
            } else {
                resultMain(parameter: false, eventsClosure: eventsClosure)
            }
        })
    }

    // MARK: 删除日历事件
    /// 删除日历事件
    /// - Parameters:
    ///   - eventIdentifier: 唯一标识符区分某个事件
    ///   - eventsClosure: 事件闭包
    static func removeCalendarsEvent(eventIdentifier: String, eventsClosure: @escaping ((Bool) -> Void)) {
        let eventStore = EKEventStore()
        // 请求日历事件
        eventStore.requestAccess(to: .event, completion: {
            granted, error in
            if (granted) && (error == nil) {
                // 获取本地日历（剔除节假日，生日等其他系统日历）
                let calendars = eventStore.calendars(for: .event).filter({
                    (calender) -> Bool in
                    return calender.type == .local || calender.type == .calDAV
                })
                // 获取当前年
                let com = Calendar.current.dateComponents([.year], from: Date())
                let currentYear = com.year!
                var events: [EKEvent] = []
                // 获取所有的事件（前后20年）
                for i in -20...20 {
                    let startDate = startOfMonth(year: currentYear + i, month:1)
                    let endDate = endOfMonth(year: currentYear + i, month: 12, returnEndTime: true)
                    let predicate = eventStore.predicateForEvents(
                        withStart: startDate, end: endDate, calendars: calendars)
                    let eV = eventStore.events(matching: predicate)
                    eV.enumerated().forEach { index,value in
                        events.append(value)
                    }
                }
                let event = events.filter { return $0.calendarItemIdentifier == eventIdentifier }
                guard event.count > 0 else {
                    resultMain(parameter: false, eventsClosure: eventsClosure)
                    return
                }
                do {
                    try eventStore.remove(event[0], span: .thisEvent, commit: true)
                    resultMain(parameter: true, eventsClosure: eventsClosure)
                } catch {
                    resultMain(parameter: false, eventsClosure: eventsClosure)
                }
            } else {
                resultMain(parameter: false, eventsClosure: eventsClosure)
            }
        })
    }
}

//MARK: Event
extension PTEventOnCalendar {
    //MARK: 把数据插入到事件作提醒
    ///把数据插入到事件作提醒
    /// - Parameters:
    ///   - eventStore:
    ///   - startDate:
    ///   - endDate:
    ///   - eventTitle:
    ///   - location:
    ///   - notes:
    ///   - remindTime:
    ///   - handle: 成功回调
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
    
    // MARK: 查询出所有提醒事件
    static func selectReminder(remindersClosure: @escaping (([EKReminder]?) -> Void)) {
        // 在取得提醒之前，需要先获取授权
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .reminder) {
            (granted: Bool, error: Error?) in
            if (granted) && (error == nil) {
                // 获取授权后，我们可以得到所有的提醒事项
                let predicate = eventStore.predicateForReminders(in: nil)
                eventStore.fetchReminders(matching: predicate, completion: {
                    (reminders: [EKReminder]?) -> Void in
                    resultMain(parameter: reminders, eventsClosure: remindersClosure)
                })
            } else {
                resultMain(parameter: nil, eventsClosure: remindersClosure)
            }
        }
    }

    // MARK: 修改提醒事件
    /// 修改提醒事件
    /// - Parameters:
    ///   - eventIdentifier: 唯一标识符区分某个事件
    ///   - title: 提醒的标题
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    ///   - notes: 备注
    ///   - eventsClosure: 事件闭包
    static func updateEvent(eventIdentifier: String, title: String, startDate: Date, endDate: Date, notes: String, eventsClosure: @escaping ((Bool) -> Void)) {
        let eventStore = EKEventStore()
        // 获取"提醒"的访问授权
        eventStore.requestAccess(to: .reminder) {(granted, error) in
            if (granted) && (error == nil) {
                // 获取授权后，我们可以得到所有的提醒事项
                let predicate = eventStore.predicateForReminders(in: nil)
                eventStore.fetchReminders(matching: predicate, completion: {
                    (reminders: [EKReminder]?) -> Void in
                    guard let weakReminders = reminders else {
                        resultMain(parameter: false, eventsClosure: eventsClosure)
                        return
                    }
                    let weakReminder = weakReminders.filter { $0.calendarItemIdentifier == eventIdentifier }
                    guard weakReminder.count > 0 else {
                        resultMain(parameter: false, eventsClosure: eventsClosure)
                        return
                    }
                    let reminder = weakReminder[0]
                    reminder.title = title
                    reminder.notes = notes
                    reminder.startDateComponents = dateComponentFrom(date: startDate)
                    reminder.dueDateComponents = dateComponentFrom(date: endDate)
                    reminder.calendar = eventStore.defaultCalendarForNewReminders()
                    // 修改提醒事项
                    do {
                        try eventStore.save(reminder, commit: true)
                        resultMain(parameter: true, eventsClosure: eventsClosure)
                    } catch {
                        resultMain(parameter: false, eventsClosure: eventsClosure)
                    }
                })
            }
        }
    }
    
    // MARK: 移除提醒事件
    /// 移除提醒事件
    /// - Parameters:
    ///   - eventIdentifier: 唯一标识符区分某个事件
    ///   - title: 提醒的标题
    ///   - startDate: 开始时间
    ///   - endDate: 结束时间
    ///   - notes: 备注
    ///   - eventsClosure: 事件闭包
    static func removeEvent(eventIdentifier: String, eventsClosure: @escaping ((Bool) -> Void)) {
        let eventStore = EKEventStore()
        // 获取"提醒"的访问授权
        eventStore.requestAccess(to: .reminder) {(granted, error) in
            if (granted) && (error == nil) {
                // 获取授权后，我们可以得到所有的提醒事项
                let predicate = eventStore.predicateForReminders(in: nil)
                eventStore.fetchReminders(matching: predicate, completion: {
                    (reminders: [EKReminder]?) -> Void in
                    guard let weakReminders = reminders else {
                        resultMain(parameter: false, eventsClosure: eventsClosure)
                        return
                    }
                    let reminderArray = weakReminders.filter { $0.calendarItemIdentifier == eventIdentifier }
                    guard reminderArray.count > 0 else {
                        resultMain(parameter: false, eventsClosure: eventsClosure)
                        return
                    }
                    // 移除提醒事项
                    do {
                        try eventStore.remove(reminderArray[0], commit: true)
                        resultMain(parameter: true, eventsClosure: eventsClosure)
                    } catch {
                        resultMain(parameter: false, eventsClosure: eventsClosure)
                    }
                })
            }
        }
    }
}

//MARK: Reminds
extension PTEventOnCalendar {
    //MARK: 把数据插入到提醒作提醒
    ///把数据插入到提醒作提醒
    /// - Parameters:
    ///   - eventStore:
    ///   - startDate:
    ///   - endDate:
    ///   - eventTitle:
    ///   - location:
    ///   - notes:
    ///   - remindTime:
    ///   - handle: 成功回调
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
