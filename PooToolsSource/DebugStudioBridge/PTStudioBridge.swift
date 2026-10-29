// One explicit, scene-independent consumer of the existing PTNetworkCaptureStore.
import Foundation
#if SWIFT_PACKAGE
import PooToolsDEBUG
#endif

public struct PTStudioBridgeConfiguration: Sendable {
    public var isEnabled: Bool
    public var maximumQueuedEvents: Int
    public var maximumPendingRequests: Int
    public var maximumBatchCount: Int
    public var batchInterval: Duration
    public var privacy: PTStudioPrivacyGate

    public init(isEnabled: Bool = false,
                maximumQueuedEvents: Int = 512,
                maximumPendingRequests: Int = 512,
                maximumBatchCount: Int = 24,
                batchInterval: Duration = .milliseconds(150),
                privacy: PTStudioPrivacyGate = .init()) {
        self.isEnabled = isEnabled
        self.maximumQueuedEvents = max(32, min(maximumQueuedEvents, 2048))
        self.maximumPendingRequests = max(32, min(maximumPendingRequests, 2048))
        self.maximumBatchCount = max(1, min(maximumBatchCount, 24))
        self.batchInterval = batchInterval
        self.privacy = privacy
    }


}

/// A running bridge is not necessarily connected: only an ACK proves delivery.
public enum PTStudioDeliveryState: String, Sendable, Equatable {
    case stopped, awaitingAcknowledgement, connected, retrying
}

public struct PTStudioBridgeStatus: Sendable, Equatable {
    public let isRunning: Bool
    public let queuedEvents: Int
    public let pendingRequests: Int
    public let droppedEvents: UInt64
    public let lastAcknowledgedSequence: UInt64?
    public let deliveryState: PTStudioDeliveryState
    public let consecutiveSendFailures: Int
    /// Sanitized diagnostic; never includes tokens, bodies, or full URLs.
    public let lastSendError: String?
}

public actor PTStudioBridge {
    public static let shared = PTStudioBridge()
    private let store: PTNetworkCaptureStore
    private var transport: (any PTStudioTransport)?
    private var streamTask: Task<Void, Never>?
    private var flushTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var config = PTStudioBridgeConfiguration()
    private var sessionID = UUID()
    private var deviceID = UUID() // Ephemeral; never IDFV, IDFA, serial number or hardware identity.
    private var nextSequence: UInt64 = 0
    private var lastAck: UInt64?
    private var droppedEvents: UInt64 = 0
    private var isSending = false
    private var retryExponent = 0
    private var consecutiveSendFailures = 0
    private var lastSendError: String?
    private var generation: UInt64 = 0
    private var queue: [PTStudioEnvelope] = []
    private var pending: [UUID: PTStudioMessageKind] = [:]
    private var pendingOrder: [UUID] = []

    public init(store: PTNetworkCaptureStore = .shared) {
        self.store = store
    }

    public func status() -> PTStudioBridgeStatus {
        let state: PTStudioDeliveryState
        if transport == nil {
            state = .stopped
        } else if consecutiveSendFailures > 0 {
            state = .retrying
        } else {
            state = lastAck == nil ? .awaitingAcknowledgement : .connected
        }
        return PTStudioBridgeStatus(isRunning: transport != nil,
                                    queuedEvents: queue.count, pendingRequests: pending.count,
                                    droppedEvents: droppedEvents, lastAcknowledgedSequence: lastAck,
                                    deliveryState: state,
                                    consecutiveSendFailures: consecutiveSendFailures,
                                    lastSendError: lastSendError)
    }

    /// Call only after a user explicitly switches on diagnostics in a Debug build.
    /// This never turns on capture, alters URLSession or installs a URLProtocol.
    public func start(using transport: any PTStudioTransport,
                      configuration: PTStudioBridgeConfiguration) async throws {
        #if !DEBUG
        throw PTStudioBridgeError.disabledInRelease
        #else
        guard configuration.isEnabled else { throw PTStudioBridgeError.disabledInRelease }
        guard self.transport == nil else { throw PTStudioBridgeError.alreadyRunning }
        generation &+= 1
        self.config = configuration
        self.transport = transport
        sessionID = UUID()
        deviceID = UUID()
        nextSequence = 0
        lastAck = nil
        droppedEvents = 0
        retryExponent = 0
        consecutiveSendFailures = 0
        lastSendError = nil
        queue.removeAll()
        pending.removeAll()
        pendingOrder.removeAll()

        // Register before the initial snapshot; any overlap is coalesced by requestID.
        let changes = await store.changes(bufferingNewest: configuration.maximumPendingRequests * 2)
        enqueue(kind: .hello, payload: .init(message: "ptools-debug-studio/1"))
        enqueue(kind: .capabilities, payload: .init(capabilities: .current))
        for record in await store.records() {
            mark(record.id, kind: record.phase == .finalized ? .recordFinalize : .recordUpsert)
        }
        streamTask = Task { [weak self] in
            for await change in changes {
                if Task.isCancelled { break }
                await self?.consume(change)
            }
        }
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                if Task.isCancelled { break }
                await self?.heartbeat()
            }
        }
        scheduleFlush(after: .zero)
        #endif
    }

    public func stop() async {
        generation &+= 1
        let previous = transport
        transport = nil
        streamTask?.cancel()
        streamTask = nil
        flushTask?.cancel()
        flushTask = nil
        heartbeatTask?.cancel()
        heartbeatTask = nil
        queue.removeAll()
        pending.removeAll()
        pendingOrder.removeAll()
        isSending = false
        retryExponent = 0
        consecutiveSendFailures = 0
        lastSendError = nil
        await previous?.close()
    }

    private func heartbeat() {
        guard transport != nil else { return }
        enqueue(kind: .heartbeat)
        scheduleFlush(after: .zero)
    }

    private func consume(_ change: PTNetworkCaptureChange) async {
        guard transport != nil else { return }
        switch change {
        case .inserted(let id), .updated(let id):
            if let record = await store.record(id: id) {
                mark(id, kind: record.phase == .finalized ? .recordFinalize : .recordUpsert)
            }
        case .removed(let id):
            await materializePending()
            enqueue(kind: .recordDelete, requestID: id)
        case .reset:
            let abandoned = queue.count + pending.count
            droppedEvents &+= UInt64(abandoned)
            queue.removeAll()
            pending.removeAll()
            pendingOrder.removeAll()
            enqueue(kind: .sessionReset)
        }
        scheduleFlush(after: config.batchInterval)
    }

    private func mark(_ id: UUID, kind: PTStudioMessageKind) {
        guard transport != nil else { return }
        if let prior = pending[id] {
            // A finalize must not be replaced by an older upsert notification.
            if prior == .recordFinalize { return }
            pending[id] = kind
        } else {
            if pendingOrder.count >= config.maximumPendingRequests {
                let evicted = pendingOrder.removeFirst()
                pending.removeValue(forKey: evicted)
                droppedEvents &+= 1
            }
            pending[id] = kind
            pendingOrder.append(id)
        }
    }

    private func materializePending() async {
        let ids = pendingOrder
        pendingOrder.removeAll(keepingCapacity: true)
        for id in ids {
            guard let kind = pending.removeValue(forKey: id) else { continue }
            guard let record = await store.record(id: id) else {
                droppedEvents &+= 1
                continue
            }
            // The final privacy gate runs before enqueue, encoding, logs, or transmission.
            let snapshot = config.privacy.map(record)
            enqueue(kind: kind, requestID: id, source: record.source.rawValue,
                    payload: PTStudioPayload(record: snapshot))
        }
    }

    private func enqueue(kind: PTStudioMessageKind, requestID: UUID? = nil,
                         source: String = "ptoolsDebugNetwork",
                         payload: PTStudioPayload = .init()) {
        nextSequence &+= 1
        queue.append(PTStudioEnvelope(sessionID: sessionID, deviceID: deviceID,
                                      requestID: requestID, sequence: nextSequence,
                                      monotonicTime: ProcessInfo.processInfo.systemUptime,
                                      source: source, kind: kind, payload: payload))
        if queue.count > config.maximumQueuedEvents {
            // Gaps are observable through session sequence numbers and status.droppedEvents.
            let removed = queue.count - config.maximumQueuedEvents
            queue.removeFirst(removed)
            droppedEvents &+= UInt64(removed)
        }
    }

    private func scheduleFlush(after delay: Duration) {
        guard transport != nil, flushTask == nil else { return }
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            if Task.isCancelled { return }
            await self?.flush()
        }
    }

    private func flush() async {
        flushTask = nil
        guard transport != nil, !isSending else { return }
        await materializePending()
        guard let transport, !queue.isEmpty else { return }
        let batch = Array(queue.prefix(config.maximumBatchCount))
        let sendingGeneration = generation
        isSending = true
        do {
            let acknowledgement = try await transport.send(batch)
            guard acknowledgement.schemaVersion == PTStudioEnvelope.currentSchemaVersion,
                  acknowledgement.sessionID == sessionID,
                  acknowledgement.acceptedSequence >= batch[batch.count - 1].sequence else {
                throw PTStudioBridgeError.invalidAcknowledgement
            }
            // A stopped or restarted bridge must never mutate the new session.
            guard sendingGeneration == generation else { return }
            // While the actor was awaiting the network, reset could have intervened.
            if self.transport != nil,
               Array(queue.prefix(batch.count)).map(\.eventID) == batch.map(\.eventID) {
                queue.removeFirst(batch.count)
                lastAck = acknowledgement.acceptedSequence
            }
            retryExponent = 0
            consecutiveSendFailures = 0
            lastSendError = nil
            isSending = false
            if !queue.isEmpty || !pending.isEmpty { scheduleFlush(after: .zero) }
        } catch {
            guard sendingGeneration == generation else { return }
            isSending = false
            guard self.transport != nil else { return }
            retryExponent = min(retryExponent + 1, 5)
            consecutiveSendFailures = min(consecutiveSendFailures + 1, Int.max - 1)
            lastSendError = Self.safeDiagnostic(for: error)
            // Retain the same eventIDs and sequences across retries for deduplication.
            scheduleFlush(after: .seconds(1 << retryExponent))
        }
    }
    private static func safeDiagnostic(for error: Error) -> String {
        if let failure = error as? PTStudioBridgeError {
            switch failure {
            case .serverStatus(401): return "HTTP 401: pairing token rejected. Confirm or re-pair in Studio."
            case .serverStatus(400): return "HTTP 400: collector rejected the event schema."
            case .serverStatus(let status): return "Collector returned HTTP \(status)."
            case .invalidAcknowledgement: return "Collector ACK was invalid."
            case .transportRejected: return "Collector rejected the request."
            default: return "Bridge setup failed."
            }
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case -1202, -1200: return "TLS trust failed. Trust the Studio Development CA and confirm the leaf pin."
            case -1003: return "Mac hostname could not be resolved; check Bonjour and Wi-Fi."
            case -1004: return "Mac TLS port unavailable; check Bridge listener and firewall."
            case -1001: return "Mac Bridge timed out."
            case -1009: return "iPhone network is unavailable."
            default: return "Network error \(nsError.code) during secure Studio transport."
            }
        }
        return "Secure Studio transport error (\(nsError.domain), code \(nsError.code))."
    }

}
