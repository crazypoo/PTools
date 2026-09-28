// English: Opt-in simulation runtime with deterministic replay and provider substitution.
// Español: Runtime de simulación opt-in con reproducción determinista y sustitución de providers.
// 中文：提供显式启用、确定性回放和 Provider 替换的模拟运行时。

import Foundation
#if SWIFT_PACKAGE
import PToolsSimulationCore
#endif

public enum PTSimulationError: Error, LocalizedError, Sendable, Equatable {
    case disabled
    case missingScenario
    public var errorDescription: String? {
        switch self { case .disabled: "Simulation is disabled"; case .missingScenario: "Simulation scenario is missing" }
    }
}

public actor PTSimulationRuntime {
    public static let shared = PTSimulationRuntime(environment: .init())
    public let environment: PTSimulationEnvironment
    public let clock: PTSimulationClock
    private var timeline = PTSimulationTimeline()
    private var activeScenario: PTSimulationScenario?

    public init(environment: PTSimulationEnvironment = .init(), clock: PTSimulationClock = .init()) {
        self.environment = environment; self.clock = clock
    }

    public func install(_ timeline: PTSimulationTimeline) { self.timeline = timeline }

    public func replay(identifier: String) throws -> AsyncStream<PTSimulationEvent> {
        guard environment.isEnabled else { throw PTSimulationError.disabled }
        guard let scenario = timeline.scenario(identifier: identifier) else { throw PTSimulationError.missingScenario }
        activeScenario = scenario
        return AsyncStream { continuation in
            Task { [weak self] in
                guard let self else { continuation.finish(); return }
                do {
                    var previous = Duration.zero
                    for event in scenario.events {
                        try await clock.sleep(for: max(.zero, event.time - previous))
                        previous = event.time
                        continuation.yield(event)
                    }
                    continuation.finish()
                    await self.finishScenario(scenario)
                } catch {
                    continuation.finish()
                }
            }
        }
    }

    public func advance(by duration: Duration) async { await clock.advance(by: duration) }
    public func currentScenario() -> PTSimulationScenario? { activeScenario }
    public func stop() { activeScenario = nil }

    private func finishScenario(_ scenario: PTSimulationScenario) {
        guard activeScenario?.identifier == scenario.identifier else { return }
        activeScenario = nil
    }
}

public actor PTMockConnectivityProvider: PTSimulationConnectivityProviding {
    private var online: Bool
    public init(online: Bool = true) { self.online = online }
    public func isOnline() async -> Bool { online }
    public func setOnline(_ value: Bool) { online = value }
}

public actor PTMockLocationProvider: PTSimulationLocationProviding {
    private var value: (latitude: Double, longitude: Double)?
    public init(location: (latitude: Double, longitude: Double)? = nil) { self.value = location }
    public func location() async -> (latitude: Double, longitude: Double)? { value }
    public func setLocation(latitude: Double, longitude: Double) { value = (latitude, longitude) }
}

public actor PTMockBluetoothProvider: PTSimulationBluetoothProviding {
    private var discoveredIdentifiers: [String] = []
    private var connected: Set<String> = []
    public init() {}
    public func discovered() async -> [String] { discoveredIdentifiers }
    public func isConnected(identifier: String) async -> Bool { connected.contains(identifier) }
    public func setDiscovered(_ identifiers: [String]) { discoveredIdentifiers = identifiers }
    public func setConnected(_ value: Bool, identifier: String) {
        if value { connected.insert(identifier) } else { connected.remove(identifier) }
    }
}
