//
//  PTDateContext.swift
//  PooTools
//
//  English: Foundation-only date context and value types.
//  Español: Tipos de valor y contexto de fechas basados únicamente en Foundation.
//  中文：仅依赖 Foundation 的日期语境和值类型。
//

import Foundation

/// English: Describes the calendar, time zone, and locale used to interpret an instant.
/// Español: Describe el calendario, la zona horaria y la región usados para interpretar un instante.
/// 中文：描述解释绝对时间点时使用的日历、时区和区域设置。
public struct PTDateContext: Hashable, Sendable, Codable {
    public let calendar: Calendar
    public let timeZone: TimeZone
    public let locale: Locale

    public init(calendar: Calendar = .current,
                timeZone: TimeZone? = nil,
                locale: Locale? = nil) {
        let resolvedTimeZone = timeZone ?? calendar.timeZone
        let resolvedLocale = locale ?? calendar.locale ?? .current
        var normalizedCalendar = calendar
        normalizedCalendar.timeZone = resolvedTimeZone
        normalizedCalendar.locale = resolvedLocale
        self.calendar = normalizedCalendar
        self.timeZone = resolvedTimeZone
        self.locale = resolvedLocale
    }

    /// English: A point-in-time snapshot of the current user environment.
    /// Español: Una instantánea del entorno actual del usuario.
    /// 中文：当前用户环境的时间点快照。
    public static var current: PTDateContext {
        PTDateContext(calendar: .current,
                      timeZone: .current,
                      locale: .current)
    }

    /// English: A context backed by Foundation's auto-updating current values.
    /// Español: Un contexto basado en los valores actuales autoactualizables de Foundation.
    /// 中文：使用 Foundation 自动更新当前值的日期语境。
    public static var autoupdatingCurrent: PTDateContext {
        PTDateContext(calendar: .autoupdatingCurrent,
                      timeZone: .autoupdatingCurrent,
                      locale: .autoupdatingCurrent)
    }

    /// English: Gregorian UTC context for machine-readable values.
    /// Español: Contexto gregoriano UTC para valores legibles por máquinas.
    /// 中文：用于机器可读值的公历 UTC 语境。
    public static var utc: PTDateContext {
        PTDateContext(calendar: Calendar(identifier: .gregorian),
                      timeZone: .gmt,
                      locale: Locale(identifier: "en_US"))
    }

    /// English: Gregorian UTC context with POSIX locale for protocol and server strings.
    /// Español: Contexto gregoriano UTC con región POSIX para protocolos y servidores.
    /// 中文：用于协议和服务器字符串的公历 UTC POSIX 语境。
    public static var posixUTC: PTDateContext {
        PTDateContext(calendar: Calendar(identifier: .gregorian),
                      timeZone: .gmt,
                      locale: Locale(identifier: "en_US_POSIX"))
    }
}

/// English: A small abstraction shared by date values that carry a context.
/// Español: Una abstracción pequeña compartida por valores de fecha con contexto.
/// 中文：携带日期语境的值类型共用的小型协议。
public protocol PTDateReadable: Sendable {
    var date: Date { get }
    var context: PTDateContext { get }
}

/// English: Components projected once from a date context.
/// Español: Componentes proyectados una sola vez desde un contexto de fecha.
/// 中文：从日期语境中一次性提取的日期组件。
public struct PTDateComponentsView: Sendable, Hashable, Codable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let hour: Int
    public let minute: Int
    public let second: Int
    public let weekday: Int
    public let weekOfYear: Int
    public let weekOfMonth: Int
    public let yearForWeekOfYear: Int
    public let quarter: Int

    public init(date: Date, context: PTDateContext) {
        let components = context.calendar.dateComponents([
            .year, .month, .day, .hour, .minute, .second,
            .weekday, .weekOfYear, .weekOfMonth, .yearForWeekOfYear, .quarter
        ], from: date)
        year = components.year ?? 0
        month = components.month ?? 0
        day = components.day ?? 0
        hour = components.hour ?? 0
        minute = components.minute ?? 0
        second = components.second ?? 0
        weekday = components.weekday ?? 0
        weekOfYear = components.weekOfYear ?? 0
        weekOfMonth = components.weekOfMonth ?? 0
        yearForWeekOfYear = components.yearForWeekOfYear ?? 0
        quarter = components.quarter ?? 0
    }
}

/// English: Calendar-aware offset; unlike Duration, it follows calendar rules such as DST.
/// Español: Desplazamiento consciente del calendario; a diferencia de Duration, respeta DST.
/// 中文：遵循日历规则的偏移量；不同于 Duration，它会正确处理夏令时。
public struct PTDateOffset: Hashable, Sendable, Codable {
    public let years: Int
    public let months: Int
    public let weeks: Int
    public let days: Int
    public let hours: Int
    public let minutes: Int
    public let seconds: Int

    public init(years: Int = 0,
                months: Int = 0,
                weeks: Int = 0,
                days: Int = 0,
                hours: Int = 0,
                minutes: Int = 0,
                seconds: Int = 0) {
        self.years = years
        self.months = months
        self.weeks = weeks
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }

    public static func years(_ value: Int) -> PTDateOffset { PTDateOffset(years: value) }
    public static func months(_ value: Int) -> PTDateOffset { PTDateOffset(months: value) }
    public static func weeks(_ value: Int) -> PTDateOffset { PTDateOffset(weeks: value) }
    public static func days(_ value: Int) -> PTDateOffset { PTDateOffset(days: value) }
    public static func hours(_ value: Int) -> PTDateOffset { PTDateOffset(hours: value) }
    public static func minutes(_ value: Int) -> PTDateOffset { PTDateOffset(minutes: value) }
    public static func seconds(_ value: Int) -> PTDateOffset { PTDateOffset(seconds: value) }

    public var dateComponents: DateComponents {
        var result = DateComponents()
        result.year = years
        result.month = months
        result.weekOfYear = weeks
        result.day = days
        result.hour = hours
        result.minute = minutes
        result.second = seconds
        return result
    }
}

/// English: Controls ambiguous and repeated local times during calendar searches.
/// Español: Controla las horas locales ambiguas o repetidas durante búsquedas del calendario.
/// 中文：控制日历查找中的歧义时间和重复本地时间。
public struct PTDateResolutionPolicy: Sendable {
    public let matchingPolicy: Calendar.MatchingPolicy
    public let repeatedTimePolicy: Calendar.RepeatedTimePolicy
    public let direction: Calendar.SearchDirection

    public init(matchingPolicy: Calendar.MatchingPolicy = .nextTime,
                repeatedTimePolicy: Calendar.RepeatedTimePolicy = .first,
                direction: Calendar.SearchDirection = .forward) {
        self.matchingPolicy = matchingPolicy
        self.repeatedTimePolicy = repeatedTimePolicy
        self.direction = direction
    }
}

/// English: Explicit unit for Unix timestamps.
/// Español: Unidad explícita para marcas de tiempo Unix.
/// 中文：Unix 时间戳的显式单位。
public enum PTTimestampUnit: String, Sendable, Codable {
    case seconds
    case milliseconds
}

/// English: Locale-aware names for date symbols.
/// Español: Nombres de símbolos de fecha sensibles a la región.
/// 中文：遵循区域设置的日期符号名称样式。
public enum PTDateSymbolStyle: Sendable {
    case full
    case abbreviated
    case narrow
}

/// English: Small set of common PTools formatting presets.
/// Español: Conjunto pequeño de formatos habituales de PTools.
/// 中文：PTools 常用日期格式的小型预设集合。
public enum PTDateFormat: Sendable {
    case date
    case dateTime
    case time
    case iso8601
    case log
    case serverDateTime
}
