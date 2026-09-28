// English: Deterministic checks for the P1 simulation contracts.
// Español: Comprobaciones deterministas para los contratos de simulación P1.
// 中文：P1 模拟契约的确定性检查。

import XCTest
@testable import PToolsSimulationCore
@testable import PToolsSimulation

final class PTAdvancedTests: XCTestCase {
    func testInstantReplayPreservesEventOrder() async throws {
        let runtime = PTSimulationRuntime(environment: .init(isEnabled: true), clock: .init(mode: .instant))
        let scenario = PTSimulationScenario(identifier: "basic", events: [
            .init(time: .seconds(2), kind: .online(true)),
            .init(time: .seconds(4), kind: .online(false))
        ])
        await runtime.install(.init(scenarios: [scenario]))
        let stream = try await runtime.replay(identifier: "basic")
        var values: [Bool] = []
        for await event in stream {
            if case .online(let value) = event.kind { values.append(value) }
        }
        XCTAssertEqual(values, [true, false])
    }

    func testDisabledRuntimeRejectsReplay() async {
        let runtime = PTSimulationRuntime()
        await runtime.install(.init(scenarios: [.init(identifier: "demo", events: [])]))
        do {
            _ = try await runtime.replay(identifier: "demo")
            XCTFail("Disabled simulation must reject replay")
        } catch PTSimulationError.disabled {
            // English: The runtime must remain opt-in in every build configuration.
            // Español: El runtime debe seguir siendo opt-in en todas las configuraciones.
            // 中文：任何构建配置下模拟运行时都必须显式启用。
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
