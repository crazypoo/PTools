import XCTest
@testable import PToolsDevice

final class PTDeviceTests: XCTestCase {
    func testUnknownIdentifierUsesSafeFallback() {
        let runtime = PTDeviceRuntimeInfo(
            identifier: "FutureDevice1,1",
            environment: .physical,
            architecture: .arm64,
            operatingSystem: OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0),
            processorCount: 8,
            physicalMemory: 8_000_000_000
        )
        let device = PTDevice(runtime: runtime)

        XCTAssertEqual(device.model.rawValue, "unknown:FutureDevice1,1")
        XCTAssertEqual(device.family, .unknown)
        XCTAssertEqual(device.platform, .unknown)
        XCTAssertFalse(device.isSimulator)
    }

    func testSimulatorIdentifierIsResolvedSeparatelyFromHostArchitecture() {
        let environment = PTDeviceRuntimeEnvironment(
            machineIdentifier: "arm64",
            simulatorModelIdentifier: "iPhone18,3",
            isSimulator: true,
            architecture: .arm64
        )
        let device = PTDevice(runtime: PTDeviceRuntimeResolver.resolve(environment: environment))

        XCTAssertEqual(device.identifier, "iPhone18,3")
        XCTAssertEqual(device.model.rawValue, "iphone-17")
        XCTAssertEqual(device.family, .iPhone)
        XCTAssertEqual(device.platform, .iOS)
        XCTAssertTrue(device.isSimulator)
    }

    func testCatalogRejectsNoRuntimeJSONDependency() {
        XCTAssertFalse(PTDeviceCatalog.allSpecifications.isEmpty)
        XCTAssertEqual(PTDeviceCatalog.model(for: "iPhone18,3")?.rawValue, "iphone-17")
    }
}
