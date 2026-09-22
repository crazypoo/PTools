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

// English: Preserve source information as an immutable value when a legacy logger forwards a dynamic file name.
// Español: Conserva la información de origen como un valor inmutable cuando un logger heredado reenvía un archivo dinámico.
// 中文：旧日志器转发动态文件名时，将来源信息保存为不可变值。
public struct PTLogSource: Sendable, Equatable {
    public let file: String
    public let function: String
    public let line: UInt

    public init(file: String, function: String, line: UInt) {
        self.file = file
        self.function = function
        self.line = line
    }
}

// English: Make bounded destinations explicit about which records may be discarded under pressure.
// Español: Hace explícito qué registros pueden descartarse cuando un destino acotado sufre presión.
// 中文：明确有界日志目标在背压下允许丢弃哪些记录。
public enum PTLogDropPolicy: String, Codable, Sendable {
    case dropOldest
    case dropNewest
    case preferImportant
}

// English: Keep sampling policy as a small value contract so future backends do not invent incompatible controls.
// Español: Mantiene la política de muestreo como un contrato de valor pequeño para que futuros backends no inventen controles incompatibles.
// 中文：用小型值类型定义采样策略，避免后续日志后端各自发明不兼容的控制方式。
public enum PTLogSamplingPolicy: Sendable, Equatable {
    case all
    case every(Int)
    case first(Int)

    public static var `default`: Self { .all }

    public func accepts(index: UInt64) -> Bool {
        switch self {
        case .all:
            return true
        case let .every(interval):
            let safeInterval = max(1, interval)
            return index % UInt64(safeInterval) == 0
        case let .first(limit):
            return index <= UInt64(max(0, limit))
        }
    }
}

// English: Expose loss counters without exposing mutable queue state across actors.
// Español: Expone contadores de pérdida sin exponer el estado mutable de las colas entre actores.
// 中文：只暴露丢弃计数，不把可变队列状态跨 actor 暴露出去。
public struct PTLogBackpressureSnapshot: Sendable, Equatable {
    public let queueDroppedCount: UInt64
    public let bufferDroppedCount: UInt64

    public init(queueDroppedCount: UInt64 = 0, bufferDroppedCount: UInt64 = 0) {
        self.queueDroppedCount = queueDroppedCount
        self.bufferDroppedCount = bufferDroppedCount
    }

    public var totalDroppedCount: UInt64 {
        queueDroppedCount &+ bufferDroppedCount
    }
}

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

// English: Keep file policy values immutable across logging backends and actor boundaries.
// Español: Mantén inmutables los valores de política de archivos entre backends y límites de actor.
// 中文：让文件策略值在日志后端和 actor 边界之间保持不可变。
public struct PTLogFileConfiguration: Sendable {
    public let directoryURL: URL
    public let maximumFileSize: UInt64
    public let maximumFileAge: TimeInterval
    public let maximumFiles: Int
    public let retentionDays: TimeInterval
    public let maximumTotalSize: UInt64
    public let bufferCapacity: Int
    public let bufferSize: Int
    public let flushInterval: TimeInterval

    public init(directoryURL: URL? = nil,
                maximumFileSize: UInt64 = 5 * 1024 * 1024,
                maximumFileAge: TimeInterval = 24 * 60 * 60,
                maximumFiles: Int = 7,
                retentionDays: TimeInterval = 7 * 24 * 60 * 60,
                maximumTotalSize: UInt64 = 30 * 1024 * 1024,
                bufferCapacity: Int = 5_000,
                bufferSize: Int = 32 * 1024,
                flushInterval: TimeInterval = 1) {
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.directoryURL = directoryURL
            ?? cachesURL.appendingPathComponent("PTools/Logs", isDirectory: true)
        self.maximumFileSize = max(1, maximumFileSize)
        self.maximumFileAge = max(1, maximumFileAge)
        self.maximumFiles = max(1, maximumFiles)
        self.retentionDays = max(0, retentionDays)
        self.maximumTotalSize = max(1, maximumTotalSize)
        self.bufferCapacity = max(1, bufferCapacity)
        self.bufferSize = max(1, bufferSize)
        self.flushInterval = max(0.1, flushInterval)
    }
}

public protocol PTLogDestination: Sendable {
    var identifier: String { get }

    func append(_ record: PTLogRecord)
    func flush() async
}
