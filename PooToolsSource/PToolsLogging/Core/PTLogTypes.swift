//
//  PTLogTypes.swift
//  PToolsLogging
//
// English: Foundation-only value types shared by every PTools logging backend.
// Español: Tipos de valor basados solo en Foundation compartidos por todos los backends de logging de PTools.
// 中文：由所有 PTools 日志后端共享的 Foundation-only 值类型。
//

import Foundation

public enum PTLogLevel: Int, CaseIterable, Comparable, Sendable {
    case trace
    case debug
    case info
    case notice
    case warning
    case error
    case fault

    public static func < (lhs: PTLogLevel, rhs: PTLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct PTLogCategory: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let general = Self(rawValue: "General")
    public static let lifecycle = Self(rawValue: "Lifecycle")
    public static let network = Self(rawValue: "Network")
    public static let database = Self(rawValue: "Database")
    public static let ui = Self(rawValue: "UI")
    public static let media = Self(rawValue: "Media")
    public static let bluetooth = Self(rawValue: "Bluetooth")
    public static let location = Self(rawValue: "Location")
    public static let security = Self(rawValue: "Security")
    public static let performance = Self(rawValue: "Performance")
}

public enum PTLogPrivacy: Sendable {
    case `public`
    case privateData
    case sensitive
}

public typealias PTLogMetadata = [String: String]

public struct PTLogRecord: Identifiable, Sendable {
    public let id: UInt64
    public let sequence: UInt64
    public let timestamp: Date
    public let level: PTLogLevel
    public let subsystem: String
    public let category: PTLogCategory
    public let message: String
    public let metadata: PTLogMetadata
    public let privacy: PTLogPrivacy
    public let file: String
    public let function: String
    public let line: UInt

    public init(sequence: UInt64,
                timestamp: Date = Date(),
                level: PTLogLevel,
                subsystem: String,
                category: PTLogCategory,
                message: String,
                metadata: PTLogMetadata = [:],
                privacy: PTLogPrivacy = .public,
                file: String,
                function: String,
                line: UInt) {
        self.id = sequence
        self.sequence = sequence
        self.timestamp = timestamp
        self.level = level
        self.subsystem = subsystem
        self.category = category
        self.message = message
        self.metadata = metadata
        self.privacy = privacy
        self.file = file
        self.function = function
        self.line = line
    }
}

public struct PTLogConfiguration: Sendable {
    public var minimumLevel: PTLogLevel
    public var categoryLevels: [PTLogCategory: PTLogLevel]
    public var subsystem: String

    public init(minimumLevel: PTLogLevel = {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }(),
    categoryLevels: [PTLogCategory: PTLogLevel] = [:],
    subsystem: String = Bundle.main.bundleIdentifier ?? "com.crazypoo.PTools") {
        self.minimumLevel = minimumLevel
        self.categoryLevels = categoryLevels
        self.subsystem = subsystem.isEmpty ? "com.crazypoo.PTools" : subsystem
    }

    public func minimumLevel(for category: PTLogCategory) -> PTLogLevel {
        categoryLevels[category] ?? minimumLevel
    }
}

public protocol PTLogDestination: Sendable {
    var identifier: String { get }

    func append(_ record: PTLogRecord)
    func flush() async
}
