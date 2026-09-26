//
//  PTZonedDate.swift
//  PooTools
//
//  English: Context-bound date operations built on modern Foundation.
//  Español: Operaciones de fecha ligadas a un contexto basadas en Foundation moderna.
//  中文：基于现代 Foundation 的带语境日期操作。
//

import Foundation

/// English: An absolute instant paired with the context used to represent it.
/// Español: Un instante absoluto junto con el contexto usado para representarlo.
/// 中文：绝对时间点与其表示语境的不可变组合。
public struct PTZonedDate: PTDateReadable, Hashable, Codable, Comparable {
    public let date: Date
    public let context: PTDateContext

    public init(date: Date, context: PTDateContext = .autoupdatingCurrent) {
        self.date = date
        self.context = context
    }

    public static func now(in context: PTDateContext = .autoupdatingCurrent) -> PTZonedDate {
        PTZonedDate(date: Date(), context: context)
    }

    /// English: Changes only the representation context; the instant never changes.
    /// Español: Cambia solo el contexto de representación; el instante nunca cambia.
    /// 中文：只改变表示语境，不改变绝对时间点。
    public func `in`(_ context: PTDateContext) -> PTZonedDate {
        PTZonedDate(date: date, context: context)
    }

    public static func < (lhs: PTZonedDate, rhs: PTZonedDate) -> Bool {
        lhs.date < rhs.date
    }

    public var components: PTDateComponentsView {
        PTDateComponentsView(date: date, context: context)
    }

    public var year: Int { components.year }
    public var month: Int { components.month }
    public var day: Int { components.day }
    public var hour: Int { components.hour }
    public var minute: Int { components.minute }
    public var second: Int { components.second }
    public var weekday: Int { components.weekday }
    public var weekOfYear: Int { components.weekOfYear }
    public var weekOfMonth: Int { components.weekOfMonth }
    public var yearForWeekOfYear: Int { components.yearForWeekOfYear }
    public var quarter: Int { components.quarter }

    /// English: Formats user-facing values with a Foundation value style.
    /// Español: Formatea valores visibles para el usuario con un estilo de valor de Foundation.
    /// 中文：使用 Foundation 值类型格式化用户可见日期。
    public func formatted(date dateStyle: Date.FormatStyle.DateStyle? = .abbreviated,
                          time timeStyle: Date.FormatStyle.TimeStyle? = .shortened) -> String {
        let style = Date.FormatStyle(date: dateStyle,
                                     time: timeStyle,
                                     locale: context.locale,
                                     calendar: context.calendar,
                                     timeZone: context.timeZone)
        return date.formatted(style)
    }

    /// English: Formats a fixed protocol pattern with a call-local legacy formatter.
    /// Español: Formatea un patrón fijo de protocolo con un formateador heredado local.
    /// 中文：使用每次调用独立的旧式格式化器处理固定协议格式。
    public func formatted(pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = context.calendar
        formatter.timeZone = context.timeZone
        formatter.locale = context.locale
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    public func formatted(_ format: PTDateFormat) -> String {
        switch format {
        case .date:
            return formatted(date: .abbreviated, time: nil)
        case .dateTime:
            return formatted(date: .abbreviated, time: .shortened)
        case .time:
            return formatted(date: nil, time: .shortened)
        case .iso8601:
            return iso8601String()
        case .log:
            return formatted(pattern: "yyyy-MM-dd HH:mm:ss.SSS")
        case .serverDateTime:
            return formatted(pattern: "yyyy-MM-dd HH:mm:ss")
        }
    }

    public func iso8601String(includingFractionalSeconds: Bool = false) -> String {
        let style = Date.ISO8601FormatStyle(includingFractionalSeconds: includingFractionalSeconds,
                                            timeZone: context.timeZone)
        return date.ISO8601Format(style)
    }

    public func monthName(_ style: PTDateSymbolStyle = .full) -> String {
        let symbol: Date.FormatStyle.Symbol.Month
        switch style {
        case .full: symbol = .wide
        case .abbreviated: symbol = .abbreviated
        case .narrow: symbol = .narrow
        }
        let format = Date.FormatStyle(date: nil,
                                      time: nil,
                                      locale: context.locale,
                                      calendar: context.calendar,
                                      timeZone: context.timeZone).month(symbol)
        return date.formatted(format)
    }

    public func weekdayName(_ style: PTDateSymbolStyle = .full) -> String {
        let symbol: Date.FormatStyle.Symbol.Weekday
        switch style {
        case .full: symbol = .wide
        case .abbreviated: symbol = .abbreviated
        case .narrow: symbol = .narrow
        }
        let format = Date.FormatStyle(date: nil,
                                      time: nil,
                                      locale: context.locale,
                                      calendar: context.calendar,
                                      timeZone: context.timeZone).weekday(symbol)
        return date.formatted(format)
    }

    /// English: Uses Foundation relative formatting while honoring the supplied reference instant.
    /// Español: Usa el formato relativo de Foundation respetando el instante de referencia.
    /// 中文：使用 Foundation 相对时间格式，并尊重传入的参考时间点。
    public func relativeDescription(to reference: Date = Date(),
                                    presentation: Date.RelativeFormatStyle.Presentation = .named,
                                    unitsStyle: Date.RelativeFormatStyle.UnitsStyle = .abbreviated) -> String {
        let style = Date.RelativeFormatStyle(presentation: presentation,
                                             unitsStyle: unitsStyle,
                                             locale: context.locale,
                                             calendar: context.calendar)
        let delta = date.timeIntervalSince(reference)
        let syntheticDate = Date().addingTimeInterval(delta)
        return style.format(syntheticDate)
    }

    public func intervalDescription(to other: PTZonedDate) -> String {
        let lower = min(date, other.date)
        let upper = max(date, other.date)
        let style = Date.IntervalFormatStyle(date: .abbreviated,
                                             time: .shortened,
                                             locale: context.locale,
                                             calendar: context.calendar,
                                             timeZone: context.timeZone)
        return style.format(lower..<upper)
    }

    public func adding(_ offset: PTDateOffset) -> PTZonedDate {
        let result = context.calendar.date(byAdding: offset.dateComponents, to: date) ?? date
        return PTZonedDate(date: result, context: context)
    }

    public func subtracting(_ offset: PTDateOffset) -> PTZonedDate {
        adding(PTDateOffset(years: -offset.years,
                            months: -offset.months,
                            weeks: -offset.weeks,
                            days: -offset.days,
                            hours: -offset.hours,
                            minutes: -offset.minutes,
                            seconds: -offset.seconds))
    }

    public func components(to other: PTZonedDate,
                           units: Set<Calendar.Component>) -> DateComponents {
        context.calendar.dateComponents(units, from: date, to: other.date)
    }

    public func next(matching components: DateComponents,
                     policy: PTDateResolutionPolicy = .init()) -> PTZonedDate? {
        guard let nextDate = context.calendar.nextDate(after: date,
                                                       matching: components,
                                                       matchingPolicy: policy.matchingPolicy,
                                                       repeatedTimePolicy: policy.repeatedTimePolicy,
                                                       direction: policy.direction) else {
            return nil
        }
        return PTZonedDate(date: nextDate, context: context)
    }

    public var startOfDay: PTZonedDate {
        PTZonedDate(date: context.calendar.startOfDay(for: date), context: context)
    }

    public var dayInterval: DateInterval? {
        context.calendar.dateInterval(of: .day, for: date)
    }

    public var weekInterval: DateInterval? {
        context.calendar.dateInterval(of: .weekOfYear, for: date)
    }

    public var monthInterval: DateInterval? {
        context.calendar.dateInterval(of: .month, for: date)
    }

    public var yearInterval: DateInterval? {
        context.calendar.dateInterval(of: .year, for: date)
    }

    public var isToday: Bool {
        context.calendar.isDateInToday(date)
    }

    public var isYesterday: Bool {
        context.calendar.isDateInYesterday(date)
    }

    public var isTomorrow: Bool {
        context.calendar.isDateInTomorrow(date)
    }

    public var isWeekend: Bool {
        context.calendar.isDateInWeekend(date)
    }

    public func isSameDay(as other: PTZonedDate) -> Bool {
        context.calendar.isDate(date, inSameDayAs: other.date)
    }

    public func isSame(_ component: Calendar.Component, as other: PTZonedDate) -> Bool {
        context.calendar.isDate(date, equalTo: other.date, toGranularity: component)
    }

    public func isInPast(relativeTo reference: Date = Date()) -> Bool {
        date < reference
    }

    public func isInFuture(relativeTo reference: Date = Date()) -> Bool {
        date > reference
    }
}

public extension Date {
    /// English: Creates a context-bound representation without changing the instant.
    /// Español: Crea una representación con contexto sin cambiar el instante.
    /// 中文：创建带语境的日期表示，不改变绝对时间点。
    func zoned(in context: PTDateContext = .autoupdatingCurrent) -> PTZonedDate {
        PTZonedDate(date: self, context: context)
    }

    static func fromTimestamp(_ value: TimeInterval,
                              unit: PTTimestampUnit) -> Date {
        let seconds = unit == .seconds ? value : value / 1_000
        return Date(timeIntervalSince1970: seconds)
    }

    func timestamp(unit: PTTimestampUnit) -> TimeInterval {
        switch unit {
        case .seconds: return timeIntervalSince1970
        case .milliseconds: return timeIntervalSince1970 * 1_000
        }
    }
}
