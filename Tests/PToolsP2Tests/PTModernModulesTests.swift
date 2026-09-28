// English: Deterministic checks for the P2 configuration and audio value contracts.
// Español: Comprobaciones deterministas para los contratos de configuración y audio de P2.
// 中文：P2 配置和音频值类型契约的确定性测试。

import XCTest
@testable import PToolsActivities
@testable import PToolsAppIntents
@testable import PToolsConfiguration
@testable import PToolsAudio
@testable import PToolsCore
@testable import PToolsFeedback
@testable import PToolsRouteCore
@testable import PToolsWidgetCore

final class PTModernModulesTests: XCTestCase {
    func testConfigurationLayersKeepSnapshotStable() async throws {
        let key = PTConfigKey(name: "limit", defaultValue: 1)
        let encoded = try JSONEncoder().encode(2)
        let store = PTConfigurationStore(defaults: [key.name: encoded])

        let first = try await store.refresh()
        XCTAssertEqual(try first.value(for: key), 2)

        try await store.setLocalOverride(3, for: key)
        XCTAssertEqual(try first.value(for: key), 2)
        let second = try await store.refresh()
        XCTAssertEqual(try second.value(for: key), 3)
    }

    func testConditionalFlagUsesContext() async throws {
        let definition = PTFeatureFlagDefinition(
            name: "new-ui",
            defaultState: .conditional,
            conditions: [.environment(.development)]
        )
        let store = PTConfigurationStore(
            context: .init(environment: .development),
            flags: [definition]
        )

        let snapshot = try await store.refresh()
        XCTAssertTrue(snapshot.isEnabled("new-ui"))
    }

    func testWaveformUsesBoundedSamples() {
        let waveform = PTAudioWaveform.from(amplitudes: [-2, 0.25, 2], sampleCount: 2)
        XCTAssertEqual(waveform.samples, [1, 1])
    }

    @MainActor
    func testFeedbackSignalUsesOneCoreHook() {
        var received: PTFeedbackSignal?
        PTFeedbackCenter.shared.handler = { received = $0 }
        PTFeedbackCenter.shared.emit(.success)
        XCTAssertEqual(received, .success)
        PTFeedbackCenter.shared.handler = nil
    }

    func testWidgetStoreRequiresExplicitAppGroup() {
        XCTAssertThrowsError(try PTWidgetSharedStore(appGroupIdentifier: ""))
    }

    func testAppIntentDescriptorPreservesRouteSource() {
        let descriptor = PTAppIntentRouteDescriptor(route: PTRoute(id: "orders"))
        XCTAssertEqual(descriptor.request().source, .appIntent)
    }

    func testActivityDiagnosticsAreCodableValueState() throws {
        let diagnostics = PTActivityDiagnostics(identifier: "order-1",
                                                 lifecycle: .active,
                                                 generation: 2,
                                                 pushTokenAvailable: true)
        let roundTrip = try JSONDecoder().decode(PTActivityDiagnostics.self,
                                                 from: JSONEncoder().encode(diagnostics))
        XCTAssertEqual(roundTrip, diagnostics)
    }
}
