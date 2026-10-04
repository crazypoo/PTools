//
//  PTCoreValueTypes.swift
//  PToolsCore
//
//  Immutable values shared across concurrency boundaries.
//  Valores inmutables compartidos entre límites de concurrencia.
//  在并发边界之间传递的不可变值类型。
//

import Foundation

// English: Keep these response and progress values free of UIKit and dynamic payloads.
// Español: Mantiene estos valores de respuesta y progreso libres de UIKit y payloads dinámicos.
// 中文：让响应和进度值类型不依赖 UIKit，也不携带动态对象。
public struct PTProgressSnapshot: Sendable, Equatable {
    public let completedUnitCount: Int64
    public let totalUnitCount: Int64
    public let fractionCompleted: Double

    public init(completedUnitCount: Int64,
                totalUnitCount: Int64,
                fractionCompleted: Double) {
        self.completedUnitCount = completedUnitCount
        self.totalUnitCount = totalUnitCount
        self.fractionCompleted = fractionCompleted
    }
}

// English: Response metadata contains only immutable value types.
// Español: Los metadatos de respuesta contienen únicamente tipos de valor inmutables.
// 中文：响应元数据只包含不可变值类型。
public struct PTResponseMetadata: Sendable, Equatable {
    public let statusCode: Int?
    public let headers: [String: String]
    public let isDegraded: Bool
    public let isCancelled: Bool

    public init(statusCode: Int? = nil,
                headers: [String: String] = [:],
                isDegraded: Bool = false,
                isCancelled: Bool = false) {
        self.statusCode = statusCode
        self.headers = headers
        self.isDegraded = isDegraded
        self.isCancelled = isCancelled
    }
}

// English: Shared cache values stay in the Foundation-only Core product so every target uses one contract.
// Español: Los valores compartidos de caché permanecen en Core, basado solo en Foundation, para que cada target use un contrato único.
// 中文：共享缓存值类型放在仅依赖 Foundation 的 Core 产品中，让所有 target 使用同一契约。
public struct PTCacheNamespace: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.isEmpty ? "default" : rawValue
    }
}

public struct PTCachePolicy: Sendable, Equatable {
    public let countLimit: Int
    public let costLimit: Int
    public let expiration: TimeInterval?
    public let namespace: PTCacheNamespace
    public let clearsOnMemoryWarning: Bool
    public let lowDiskThreshold: Int64?
    public let diskLimit: Int64?
    public let diskTarget: Int64?

    public init(countLimit: Int = 100,
                costLimit: Int = 16 * 1024 * 1024,
                expiration: TimeInterval? = nil,
                namespace: String = "default",
                clearsOnMemoryWarning: Bool = true,
                lowDiskThreshold: Int64? = nil,
                diskLimit: Int64? = nil,
                diskTarget: Int64? = nil) {
        self.countLimit = max(1, countLimit)
        self.costLimit = max(0, costLimit)
        self.expiration = expiration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        self.namespace = PTCacheNamespace(rawValue: namespace)
        self.clearsOnMemoryWarning = clearsOnMemoryWarning
        self.lowDiskThreshold = lowDiskThreshold.flatMap { $0 > 0 ? $0 : nil }
        self.diskLimit = diskLimit.flatMap { $0 > 0 ? $0 : nil }
        self.diskTarget = diskTarget.flatMap { value in
            guard value > 0 else { return nil }
            return diskLimit.map { min(value, $0) } ?? value
        }
    }
}

public enum PTCacheEvictionReason: String, Sendable, Codable {
    case expired
    case countLimit
    case costLimit
    case memoryWarning
    case lowDisk
    case manual
}

public struct PTCacheMetrics: Sendable, Codable, Equatable {
    public let hits: UInt64
    public let misses: UInt64
    public let insertions: UInt64
    public let evictions: UInt64
    public let expiredEntries: UInt64
    public let totalCost: Int
    public let count: Int
    public let lastEvictionReason: PTCacheEvictionReason?

    public init(hits: UInt64 = 0,
                misses: UInt64 = 0,
                insertions: UInt64 = 0,
                evictions: UInt64 = 0,
                expiredEntries: UInt64 = 0,
                totalCost: Int = 0,
                count: Int = 0,
                lastEvictionReason: PTCacheEvictionReason? = nil) {
        self.hits = hits
        self.misses = misses
        self.insertions = insertions
        self.evictions = evictions
        self.expiredEntries = expiredEntries
        self.totalCost = totalCost
        self.count = count
        self.lastEvictionReason = lastEvictionReason
    }
}

// English: Location provider contracts carry only coordinates across actors.
// Español: Los contratos de ubicación solo transportan coordenadas entre actores.
// 中文：定位 Provider 只通过坐标值跨 actor 传递数据。
public struct PTLocationSnapshot: Codable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let city: String

    // English: Keep the city optional in practice so older coordinate-only callers remain source compatible.
    // Español: Mantiene la ciudad opcional en la práctica para conservar la compatibilidad de los llamadores antiguos.
    // 中文：让城市字段在实际使用中保持可选语义，兼容旧的仅坐标调用方。
    public init(latitude: Double, longitude: Double, city: String = "") {
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
    }

    // English: Decode snapshots written before the city field was introduced.
    // Español: Decodifica instantáneas escritas antes de introducir el campo de ciudad.
    // 中文：兼容城市字段加入前写入的旧快照。
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
    }
}

public protocol PTLocationProviding: Sendable {
    func currentLocation() async -> PTLocationSnapshot?
}

// English: Preserve the legacy erased model while keeping new value types typed.
// Español: Conserva el modelo borrado heredado y mantiene tipados los nuevos valores.
// 中文：保留旧版擦除模型，同时让新的值类型保持明确类型。
public struct PTBaseStructModel<T> {
    public var originalString: String = ""
    public var customerModel: T?
    public var resultData: Data? = Data()

    public init() {}
}

extension PTBaseStructModel: Sendable where T: Sendable {}

public typealias PTLegacyStructModel = PTBaseStructModel<Any>

// English: Keep this compatibility box out of the UI and network layers.
// Español: Mantiene esta caja de compatibilidad fuera de las capas UI y de red.
// 中文：让这个兼容包装器不进入 UI 和网络层。
@available(*, deprecated, message: "Use a concrete Sendable value instead of boxing a metatype")
public struct PTSendableTypeBox<T: Sendable>: Sendable {
    public let type: T?

    public init(_ type: T?) {
        self.type = type
    }
}
