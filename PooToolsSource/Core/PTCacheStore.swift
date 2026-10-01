// English: This bounded actor is the shared cache contract for resource and computation caches.
// Español: Este actor acotado es el contrato común para cachés de recursos y cálculos.
// 中文：这个有界 Actor 是资源缓存和计算缓存的统一契约实现。

import Foundation

public protocol PTCacheStore<Key, Value>: Sendable where Key: Hashable & Sendable, Value: Sendable {
    associatedtype Key
    associatedtype Value

    func value(for key: Key) async -> Value?
    func insert(_ value: Value, for key: Key, cost: Int) async
    func removeValue(for key: Key) async
    func removeAll() async
}

public actor PTMemoryCacheStore<Key: Hashable & Sendable, Value: Sendable>: PTCacheStore {
    public let countLimit: Int
    public let costLimit: Int

    private var values: [Key: Value] = [:]
    private var costs: [Key: Int] = [:]
    private var order: [Key] = []
    private var totalCost = 0

    public init(countLimit: Int = 100,
                costLimit: Int = 16 * 1024 * 1024) {
        self.countLimit = max(1, countLimit)
        self.costLimit = max(0, costLimit)
    }

    public func value(for key: Key) -> Value? {
        guard let value = values[key] else { return nil }
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
        evictIfNeeded()
    }

    public func removeValue(for key: Key) {
        values.removeValue(forKey: key)
        totalCost = max(0, totalCost - (costs.removeValue(forKey: key) ?? 0))
        order.removeAll { $0 == key }
    }

    public func removeAll() {
        values.removeAll(keepingCapacity: true)
        costs.removeAll(keepingCapacity: true)
        order.removeAll(keepingCapacity: true)
        totalCost = 0
    }

    private func evictIfNeeded() {
        while order.count > countLimit || totalCost > costLimit {
            guard let key = order.first else { return }
            order.removeFirst()
            values.removeValue(forKey: key)
            totalCost = max(0, totalCost - (costs.removeValue(forKey: key) ?? 0))
        }
    }
}

