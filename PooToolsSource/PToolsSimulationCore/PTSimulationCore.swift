// English: Foundation-only deterministic simulation contracts and virtual time.
// Español: Contratos de simulación deterministas y tiempo virtual basados solo en Foundation.
// 中文：仅依赖 Foundation 的确定性模拟契约和虚拟时间。

import Foundation

public struct PTSimulationEvent: Codable, Hashable, Sendable {
    public enum Kind: Codable, Hashable, Sendable {
        case online(Bool)
        case location(latitude: Double, longitude: Double)
        case motion(String)
        case bluetoothDiscovered(String)
        case bluetoothConnected(String)
        case notification(String)
        case device(String)
    }

    public let time: Duration
    public let kind: Kind
    public init(time: Duration = .zero, kind: Kind) { self.time = time; self.kind = kind }
}

public struct PTSimulationScenario: Codable, Hashable, Sendable {
    public let identifier: String
    public let events: [PTSimulationEvent]
    public init(identifier: String, events: [PTSimulationEvent]) {
        self.identifier = identifier; self.events = events.sorted { $0.time < $1.time }
    }
}

public struct PTSimulationTimeline: Codable, Hashable, Sendable {
    public let scenarios: [PTSimulationScenario]
    public init(scenarios: [PTSimulationScenario] = []) { self.scenarios = scenarios }
    public func scenario(identifier: String) -> PTSimulationScenario? { scenarios.first { $0.identifier == identifier } }
}

public struct PTSimulationEnvironment: Codable, Hashable, Sendable {
    public let isEnabled: Bool
    public let demoMode: Bool
    public init(isEnabled: Bool = false, demoMode: Bool = false) { self.isEnabled = isEnabled; self.demoMode = demoMode }
}

public actor PTSimulationClock {
    public enum Mode: String, Codable, Sendable { case instant, accelerated, manual }
    public let mode: Mode
    public let acceleration: Double
    private var current: Duration
    private var waiters: [UUID: (deadline: Duration, continuation: CheckedContinuation<Void, Error>)] = [:]

    public init(mode: Mode = .manual, acceleration: Double = 1, start: Duration = .zero) {
        self.mode = mode; self.acceleration = max(0.001, acceleration); self.current = start
    }

    public func now() -> Duration { current }

    public func advance(by duration: Duration) {
        guard duration >= .zero else { return }
        current += duration
        let ready = waiters.filter { $0.value.deadline <= current }
        ready.forEach { waiters.removeValue(forKey: $0.key)?.continuation.resume() }
    }

    public func sleep(for duration: Duration) async throws {
        if duration <= .zero { return }
        let deadline = current + duration
        if mode == .instant { current = deadline; return }
        let id = UUID()
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                waiters[id] = (deadline, continuation)
            }
        }, onCancel: { [weak self] in
            Task { await self?.cancelWaiter(id) }
        })
    }

    private func cancelWaiter(_ id: UUID) {
        waiters.removeValue(forKey: id)?.continuation.resume(throwing: CancellationError())
    }
}

public protocol PTSimulationLocationProviding: Sendable {
    func location() async -> (latitude: Double, longitude: Double)?
}

public protocol PTSimulationMotionProviding: Sendable {
    func state() async -> String?
}

public protocol PTSimulationBluetoothProviding: Sendable {
    func discovered() async -> [String]
    func isConnected(identifier: String) async -> Bool
}

public protocol PTSimulationConnectivityProviding: Sendable {
    func isOnline() async -> Bool
}

public protocol PTSimulationNotificationScheduling: Sendable {
    func schedule(identifier: String) async
}

public protocol PTSimulationDeviceProviding: Sendable {
    func value(for key: String) async -> String?
}
