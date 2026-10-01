// English: This bounded actor is the shared cache contract for resource and computation caches.
// Español: Este actor acotado es el contrato común para cachés de recursos y cálculos.
// 中文：这个有界 Actor 是资源缓存和计算缓存的统一契约实现。

import Foundation

public struct PTCacheNamespace: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.isEmpty ? "default" : rawValue
    }
}

// English: Shared cache policy keeps limits, expiry, namespace and cleanup behavior explicit.
// Español: La política común hace explícitos los límites, la caducidad, el espacio de nombres y la limpieza.
// 中文：统一缓存策略明确容量限制、过期时间、命名空间和清理行为。
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

public protocol PTCacheStore<Key, Value>: Sendable where Key: Hashable & Sendable, Value: Sendable {
    associatedtype Key
    associatedtype Value

    func value(for key: Key) async -> Value?
    func insert(_ value: Value, for key: Key, cost: Int) async
    func removeValue(for key: Key) async
    func removeAll() async
}

public actor PTMemoryCacheStore<Key: Hashable & Sendable, Value: Sendable>: PTCacheStore {
    public let policy: PTCachePolicy
    public var countLimit: Int { policy.countLimit }
    public var costLimit: Int { policy.costLimit }

    private var values: [Key: Value] = [:]
    private var costs: [Key: Int] = [:]
    private var expirationDates: [Key: Date] = [:]
    private var order: [Key] = []
    private var totalCost = 0
    private var hitCount: UInt64 = 0
    private var missCount: UInt64 = 0
    private var insertionCount: UInt64 = 0
    private var evictionCount: UInt64 = 0
    private var expiredCount: UInt64 = 0
    private var lastEvictionReason: PTCacheEvictionReason?

    public init(countLimit: Int = 100,
                costLimit: Int = 16 * 1024 * 1024) {
        self.policy = PTCachePolicy(countLimit: countLimit, costLimit: costLimit)
    }

    public init(policy: PTCachePolicy) {
        self.policy = policy
    }

    public func value(for key: Key) -> Value? {
        guard let value = values[key] else {
            missCount += 1
            return nil
        }
        if let expirationDate = expirationDates[key], expirationDate <= .now {
            removeValue(for: key, reason: .expired)
            missCount += 1
            expiredCount += 1
            return nil
        }
        hitCount += 1
        order.removeAll { $0 == key }
        order.append(key)
        return value
    }

    public func insert(_ value: Value, for key: Key, cost: Int) {
        if let oldCost = costs.updateValue(max(0, cost), forKey: key) {
            totalCost -= oldCost
        } else {
            order.append(key)
        }
        values[key] = value
        totalCost += max(0, cost)
        insertionCount += 1
        if let expiration = policy.expiration {
            expirationDates[key] = Date().addingTimeInterval(expiration)
        } else {
            expirationDates.removeValue(forKey: key)
        }
        evictIfNeeded()
    }

    public func removeValue(for key: Key) {
        removeValue(for: key, reason: .manual)
    }

    public func removeAll() {
        removeAll(reason: .manual)
    }

    public func metrics() -> PTCacheMetrics {
        PTCacheMetrics(hits: hitCount,
                       misses: missCount,
                       insertions: insertionCount,
                       evictions: evictionCount,
                       expiredEntries: expiredCount,
                       totalCost: totalCost,
                       count: values.count,
                       lastEvictionReason: lastEvictionReason)
    }

    public func handleMemoryWarning() {
        guard policy.clearsOnMemoryWarning else { return }
        removeAll(reason: .memoryWarning)
    }

    public func handleLowDisk() {
        removeAll(reason: .lowDisk)
    }

    private func removeValue(for key: Key, reason: PTCacheEvictionReason) {
        guard values.removeValue(forKey: key) != nil else { return }
        totalCost = max(0, totalCost - (costs.removeValue(forKey: key) ?? 0))
        expirationDates.removeValue(forKey: key)
        order.removeAll { $0 == key }
        if reason != .manual {
            evictionCount += 1
            lastEvictionReason = reason
        }
    }

    private func removeAll(reason: PTCacheEvictionReason) {
        values.removeAll(keepingCapacity: true)
        costs.removeAll(keepingCapacity: true)
        expirationDates.removeAll(keepingCapacity: true)
        order.removeAll(keepingCapacity: true)
        totalCost = 0
        if reason != .manual {
            evictionCount += 1
            lastEvictionReason = reason
        }
    }

    private func evictIfNeeded() {
        while order.count > countLimit || totalCost > costLimit {
            guard let key = order.first else { return }
            let reason: PTCacheEvictionReason = order.count > countLimit ? .countLimit : .costLimit
            removeValue(for: key, reason: reason)
        }
    }
}
