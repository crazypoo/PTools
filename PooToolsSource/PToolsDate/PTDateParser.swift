//
//  PTDateParser.swift
//  PooTools
//
//  English: Explicit, strict date parsing for server and user input.
//  Español: Análisis explícito y estricto de fechas para servidores y usuarios.
//  中文：面向服务器和用户输入的显式严格日期解析。
//

import Foundation

public enum PTDateParsingStrategy: Sendable {
    case iso8601
    case pattern(String)
    case patterns([String])
    case localized(date: Date.FormatStyle.DateStyle?, time: Date.FormatStyle.TimeStyle?)
}

public enum PTDateParsingError: Error, Sendable, Equatable {
    case emptyInput
    case unsupportedFormat
    case invalidDate
    case ambiguousDate
}

public enum PTDateParser {
    /// English: Parses with an explicit strategy and never silently returns the current date.
    /// Español: Analiza con una estrategia explícita y nunca devuelve silenciosamente la fecha actual.
    /// 中文：使用显式策略解析，失败时绝不会静默返回当前时间。
    public static func parse(_ string: String,
                             strategy: PTDateParsingStrategy,
                             context: PTDateContext = .posixUTC) throws -> Date {
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PTDateParsingError.emptyInput
        }

        switch strategy {
        case .iso8601:
            do {
                return try Date.ISO8601FormatStyle(timeZone: context.timeZone).parse(string)
            } catch {
                throw PTDateParsingError.invalidDate
            }
        case let .pattern(pattern):
            return try parsePattern(string, pattern: pattern, context: context)
        case let .patterns(patterns):
            guard !patterns.isEmpty else { throw PTDateParsingError.unsupportedFormat }
            for pattern in patterns {
                if let date = try? parsePattern(string, pattern: pattern, context: context) {
                    return date
                }
            }
            throw PTDateParsingError.invalidDate
        case let .localized(dateStyle, timeStyle):
            do {
                let style = Date.FormatStyle(date: dateStyle,
                                             time: timeStyle,
                                             locale: context.locale,
                                             calendar: context.calendar,
                                             timeZone: context.timeZone)
                return try style.parseStrategy.parse(string)
            } catch {
                throw PTDateParsingError.invalidDate
            }
        }
    }

    /// English: Parses a fixed pattern using a call-local formatter as Foundation's legacy fallback.
    /// Español: Analiza un patrón fijo con un formateador local como respaldo heredado de Foundation.
    /// 中文：固定格式使用每次调用独立的 DateFormatter 作为 Foundation 兼容兜底。
    private static func parsePattern(_ string: String,
                                     pattern: String,
                                     context: PTDateContext) throws -> Date {
        guard !pattern.isEmpty else { throw PTDateParsingError.unsupportedFormat }
        let formatter = DateFormatter()
        formatter.calendar = context.calendar
        formatter.timeZone = context.timeZone
        formatter.locale = context.locale
        formatter.dateFormat = pattern
        formatter.isLenient = false
        guard let date = formatter.date(from: string) else {
            throw PTDateParsingError.invalidDate
        }
        return date
    }
}
