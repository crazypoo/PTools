//
//  PTCoreContracts.swift
//  PToolsCore
//
// English: Foundation-only contracts shared by logging, cache, and error adapters.
// Español: Contratos basados solo en Foundation compartidos por los adaptadores de logs, caché y errores.
// 中文：供日志、缓存和错误适配器共享的 Foundation-only 契约。
//

import Foundation

public enum PTLogSeverity: String, Sendable {
    case debug
    case info
    case warning
    case error
}

public struct PTLogEvent: Sendable {
    public let message: String
    public let severity: PTLogSeverity
    public let category: String

    public init(message: String,
                severity: PTLogSeverity = .info,
                category: String = "general") {
        self.message = message
        self.severity = severity
        self.category = category
    }
}

// English: Keep logging backends replaceable and outside the Core dependency graph.
// Español: Mantiene reemplazables los backends de logging y fuera del grafo de dependencias de Core.
// 中文：让日志后端可替换，并保持在 Core 依赖图之外。
public protocol PTLogging: Sendable {
    func log(_ event: PTLogEvent)
}

// English: Use a small typed cache contract instead of exposing a third-party cache type.
// Español: Usa un contrato de caché tipado y pequeño en lugar de exponer un tipo de caché de terceros.
// 中文：使用小型类型化缓存契约，不向外暴露第三方缓存类型。
public protocol PTCacheStorage: Sendable {
    associatedtype Key: Hashable & Sendable
    associatedtype Value: Sendable

    func value(forKey key: Key) async -> Value?
    func insert(_ value: Value, forKey key: Key) async
    func removeValue(forKey key: Key) async
    func removeAll() async
}

// English: The default memory cache is actor-isolated, bounded by ownership, and dependency-free.
// Español: La caché de memoria predeterminada está aislada en un actor, controlada por su propietario y sin dependencias.
// 中文：默认内存缓存使用 actor 隔离、由所有者管理且不依赖第三方库。
public actor PTMemoryCache<Value: Sendable>: PTCacheStorage {
    public typealias Key = String

    private var storage: [String: Value] = [:]

    public init() {}

    public func value(forKey key: String) async -> Value? {
        storage[key]
    }

    public func insert(_ value: Value, forKey key: String) async {
        storage[key] = value
    }

    public func removeValue(forKey key: String) async {
        storage.removeValue(forKey: key)
    }

    public func removeAll() async {
        storage.removeAll(keepingCapacity: false)
    }
}

// English: Use one typed error surface for infrastructure failures without leaking a feature error type.
// Español: Usa una superficie de error tipada para fallos de infraestructura sin filtrar errores de funciones concretas.
// 中文：为基础设施故障提供统一类型化错误，不泄漏具体功能模块的错误类型。
public enum PTCoreError: Error, LocalizedError, Sendable, Equatable {
    case invalidInput
    case cancelled
    case notConfigured
    case underlying(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "The supplied input is invalid."
        case .cancelled:
            return "The operation was cancelled."
        case .notConfigured:
            return "The infrastructure is not configured."
        case .underlying(let message):
            return message
        }
    }
}

// English: Keep infrastructure results typed and independent from feature-specific errors.
// Español: Mantiene los resultados de infraestructura tipados e independientes de errores de funciones concretas.
// 中文：让基础设施结果保持类型化，并独立于具体功能模块的错误类型。
public enum PTResult<Success: Sendable>: Sendable {
    case success(Success)
    case failure(PTCoreError)

    public var successValue: Success? {
        guard case .success(let value) = self else { return nil }
        return value
    }

    public var failureError: PTCoreError? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}
