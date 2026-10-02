// English: This bounded actor is the shared cache contract for resource and computation caches.
// Español: Este actor acotado es el contrato común para cachés de recursos y cálculos.
// 中文：这个有界 Actor 是资源缓存和计算缓存的统一契约实现。

import Foundation
#if canImport(PToolsCore)
import PToolsCore
#endif

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
