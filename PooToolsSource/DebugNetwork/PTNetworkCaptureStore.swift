// English: The actor owns capture identity, eviction, body lifetime, and change delivery.
// Español: El actor posee la identidad, la expulsión, la vida del cuerpo y la entrega de cambios.
// 中文：Actor 统一负责抓包身份、淘汰、正文生命周期和变更投递。

import Foundation

public actor PTNetworkCaptureStore {
    public static let shared = PTNetworkCaptureStore()

    public let maxRecords: Int
    public let bodyMemoryBudget: Int
    public let diskBudget: Int64

    private var nextSequence: UInt64 = 0
    private var recordsByID: [UUID: PTNetworkCaptureRecord] = [:]
    private var order: [UUID] = []
    private var continuations: [UUID: AsyncStream<PTNetworkCaptureChange>.Continuation] = [:]
    private var bodyMemoryCost = 0
    private var diskCost: Int64 = 0

    public init(maxRecords: Int = 500,
                bodyMemoryBudget: Int = 64 * 1024 * 1024,
                diskBudget: Int64 = 256 * 1024 * 1024) {
        self.maxRecords = max(1, maxRecords)
        self.bodyMemoryBudget = max(0, bodyMemoryBudget)
        self.diskBudget = max(0, diskBudget)
    }

    @discardableResult
    public func insert(_ record: PTNetworkCaptureRecord) -> PTNetworkCaptureRecord {
        if let existing = recordsByID[record.id] { return existing }
        let assigned = record.withSequence(nextSequence)
        nextSequence &+= 1
        recordsByID[assigned.id] = assigned
        order.append(assigned.id)
        addCost(for: assigned)
        evictIfNeeded()
        emit(.inserted(assigned.id))
        return assigned
    }

    @discardableResult
    public func finalize(id: UUID,
                         response: PTNetworkCaptureResponseSnapshot?,
                         timing: PTNetworkTiming,
                         metrics: PTNetworkTaskMetricsSnapshot?,
                         error: PTNetworkCaptureError?,
                         completion: PTNetworkCaptureCompletion,
                         redirects: [PTNetworkRedirectSnapshot] = [],
                         fetchSource: PTNetworkFetchSource? = nil,
                         retryCount: Int = 0) -> Bool {
        guard let current = recordsByID[id], current.phase != .finalized else { return false }
        let finalized = current.replacing(response: response,
                                          timing: timing,
                                          metrics: metrics,
                                          error: error,
                                          completion: completion,
                                          phase: .finalized,
                                          redirects: redirects,
                                          fetchSource: fetchSource,
                                          retryCount: retryCount)
        replace(finalized, change: .updated(id))
        return true
    }

    public func record(id: UUID) -> PTNetworkCaptureRecord? {
        recordsByID[id]
    }

    public func summaries(filter: PTNetworkCaptureFilter? = nil) -> [PTNetworkCaptureSummary] {
        order.compactMap { id in
            guard let record = recordsByID[id] else { return nil }
            let summary = PTNetworkCaptureSummary(record: record)
            return filter?.matches(summary) == false ? nil : summary
        }
    }

    public func records(filter: PTNetworkCaptureFilter? = nil) -> [PTNetworkCaptureRecord] {
        order.compactMap { id in
            guard let record = recordsByID[id] else { return nil }
            let summary = PTNetworkCaptureSummary(record: record)
            return filter?.matches(summary) == false ? nil : record
        }
    }

    @discardableResult
    public func remove(id: UUID) -> Bool {
        guard let record = recordsByID.removeValue(forKey: id) else { return false }
        order.removeAll { $0 == id }
        removeCost(for: record)
        cleanupFile(for: record)
        emit(.removed(id))
        return true
    }

    public func clear() {
        recordsByID.values.forEach(cleanupFile)
        recordsByID.removeAll(keepingCapacity: true)
        order.removeAll(keepingCapacity: true)
        bodyMemoryCost = 0
        diskCost = 0
        emit(.reset)
    }

    public func changes() -> AsyncStream<PTNetworkCaptureChange> {
        let token = UUID()
        return AsyncStream { continuation in
            continuations[token] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(token) }
            }
        }
    }

    public func currentBodyMemoryCost() -> Int { bodyMemoryCost }
    public func currentDiskCost() -> Int64 { diskCost }

    private func removeContinuation(_ token: UUID) {
        continuations.removeValue(forKey: token)
    }

    private func emit(_ change: PTNetworkCaptureChange) {
        continuations.values.forEach { $0.yield(change) }
    }

    private func replace(_ record: PTNetworkCaptureRecord, change: PTNetworkCaptureChange) {
        if let old = recordsByID[record.id] { removeCost(for: old) }
        recordsByID[record.id] = record
        addCost(for: record)
        evictIfNeeded()
        emit(change)
    }

    private func evictIfNeeded() {
        while order.count > maxRecords || bodyMemoryCost > bodyMemoryBudget || diskCost > diskBudget {
            guard let candidateID = order.first(where: { recordsByID[$0]?.phase == .finalized }) else { return }
            guard let candidate = recordsByID.removeValue(forKey: candidateID) else {
                order.removeAll { $0 == candidateID }
                continue
            }
            order.removeAll { $0 == candidateID }
            removeCost(for: candidate)
            cleanupFile(for: candidate)
            emit(.removed(candidateID))
        }
    }

    private func addCost(for record: PTNetworkCaptureRecord) {
        bodyMemoryCost += record.request.body.memoryCost
        bodyMemoryCost += record.response?.body.memoryCost ?? 0
        diskCost += fileSize(record.request.body.diskURL)
        diskCost += fileSize(record.response?.body.diskURL)
    }

    private func removeCost(for record: PTNetworkCaptureRecord) {
        bodyMemoryCost = max(0, bodyMemoryCost - record.request.body.memoryCost - (record.response?.body.memoryCost ?? 0))
        diskCost = max(0, diskCost - fileSize(record.request.body.diskURL) - fileSize(record.response?.body.diskURL))
    }

    private func fileSize(_ url: URL?) -> Int64 {
        guard let url, let value = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber else { return 0 }
        return value.int64Value
    }

    private func cleanupFile(for record: PTNetworkCaptureRecord) {
        for url in [record.request.body.diskURL, record.response?.body.diskURL].compactMap({ $0 }) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

public actor PTNetworkCaptureCenter {
    public static let shared = PTNetworkCaptureCenter()

    private let store: PTNetworkCaptureStore

    public init(store: PTNetworkCaptureStore = .shared) {
        self.store = store
    }

    @discardableResult
    public func record(_ record: PTNetworkCaptureRecord) async -> PTNetworkCaptureRecord {
        await store.insert(record)
    }

    public func finalize(id: UUID,
                         response: PTNetworkCaptureResponseSnapshot?,
                         timing: PTNetworkTiming,
                         metrics: PTNetworkTaskMetricsSnapshot?,
                         error: PTNetworkCaptureError?,
                         completion: PTNetworkCaptureCompletion,
                         redirects: [PTNetworkRedirectSnapshot] = [],
                         fetchSource: PTNetworkFetchSource? = nil,
                         retryCount: Int = 0) async -> Bool {
        await store.finalize(id: id,
                             response: response,
                             timing: timing,
                             metrics: metrics,
                             error: error,
                             completion: completion,
                             redirects: redirects,
                             fetchSource: fetchSource,
                             retryCount: retryCount)
    }
}

private extension PTNetworkCaptureRecord {
    func withSequence(_ sequence: UInt64) -> PTNetworkCaptureRecord {
        PTNetworkCaptureRecord(id: id,
                               sequence: sequence,
                               request: request,
                               response: response,
                               timing: timing,
                               metrics: metrics,
                               error: error,
                               source: source,
                               completion: completion,
                               phase: phase,
                               redirects: redirects,
                               fetchSource: fetchSource,
                               retryCount: retryCount)
    }

    func replacing(response: PTNetworkCaptureResponseSnapshot?,
                   timing: PTNetworkTiming,
                   metrics: PTNetworkTaskMetricsSnapshot?,
                   error: PTNetworkCaptureError?,
                   completion: PTNetworkCaptureCompletion,
                   phase: PTNetworkCapturePhase,
                   redirects: [PTNetworkRedirectSnapshot],
                   fetchSource: PTNetworkFetchSource?,
                   retryCount: Int) -> PTNetworkCaptureRecord {
        PTNetworkCaptureRecord(id: id,
                               sequence: sequence,
                               request: request,
                               response: response,
                               timing: timing,
                               metrics: metrics,
                               error: error,
                               source: source,
                               completion: completion,
                               phase: phase,
                               redirects: redirects,
                               fetchSource: fetchSource,
                               retryCount: retryCount)
    }
}
