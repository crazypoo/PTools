// English: Deterministic checks for the P1 simulation contracts.
// Español: Comprobaciones deterministas para los contratos de simulación P1.
// 中文：P1 模拟契约的确定性检查。

import XCTest
@testable import PToolsBluetooth
@testable import PToolsConnectivity
@testable import PToolsCore
@testable import PToolsDevice
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

    func testSimulationProvidersMatchProductionContracts() async {
        let connectivity: any PTConnectivityProviding = PTMockConnectivityProvider(online: true)
        let location: any PTLocationProviding = PTMockLocationProvider(location: (31.2, 121.5))
        let bluetooth: any PTBluetoothProviding = PTMockBluetoothProvider()
        let device: any PTDeviceCapabilityProviding = PTMockDeviceProvider()

        let connectivityStatus = await connectivity.current().status
        let locationLatitude = await location.currentLocation()?.latitude
        let discoveredPeripherals = await bluetooth.discoveredPeripherals()
        let cameraStatus = await device.status(for: .camera)
        XCTAssertEqual(connectivityStatus, .satisfied)
        XCTAssertEqual(locationLatitude, 31.2)
        XCTAssertTrue(discoveredPeripherals.isEmpty)
        XCTAssertEqual(cameraStatus, .unknown)
    }
}
