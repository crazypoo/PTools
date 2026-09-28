// English: Small deterministic checks for the 5.34 platform contracts.
// Español: Comprobaciones deterministas pequeñas para los contratos de plataforma 5.34.
// 中文：5.34 平台契约的小型确定性检查。

import XCTest
@testable import PToolsBackgroundTasks
@testable import PToolsConnectivity
@testable import PToolsNotifications
@testable import PToolsDeepLink
@testable import PToolsRouteCore
@testable import PToolsStorage
@testable import PToolsStorageCore

final class PTPlatformTests: XCTestCase {
    func testDeepLinkProducesTypedRouteParameters() throws {
        let url = try XCTUnwrap(URL(string: "myapp://orders/42?preview=true"))
        let request = try PTDeepLinkParser.request(
            from: url,
            configuration: PTDeepLinkConfiguration(schemes: ["myapp"])
        )

        XCTAssertEqual(request.route.id.rawValue, "orders")
        XCTAssertEqual(request.parameters["path0"], .integer(42))
        XCTAssertEqual(request.parameters["preview"], .boolean(true))
        XCTAssertEqual(request.source, .urlScheme)
    }

    func testTypedStorageUsesNamespaceAndRoundTripsValue() async throws {
        let storage = PTStorage(namespace: PTStorageNamespace(module: "tests", feature: "platform"),
                                 backend: PTMemoryStorage())
        let key = PTStorageKey<String>("name")

        try await storage.set("PTools", for: key)

        let value = try await storage.value(for: key)
        let otherValue = try await storage.data(for: "other-name")
        XCTAssertEqual(value, "PTools")
        XCTAssertNil(otherValue)
    }

    func testConnectivitySnapshotKeepsNewAddressFamilyFlags() throws {
        let snapshot = PTConnectivitySnapshot(status: .satisfied,
                                               interfaces: [.wifi],
                                               supportsIPv4: true,
                                               supportsIPv6: true)
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(PTConnectivitySnapshot.self, from: data)
        XCTAssertTrue(decoded.supportsIPv4)
        XCTAssertTrue(decoded.supportsIPv6)
    }

    func testConnectivitySnapshotReadsLegacyPayload() throws {
        let legacy = """
        {"status":"unknown","interfaces":[],"isExpensive":false,"isConstrained":false,"timestamp":0}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PTConnectivitySnapshot.self, from: legacy)
        XCTAssertFalse(decoded.supportsIPv4)
        XCTAssertFalse(decoded.supportsIPv6)
    }

    func testBackgroundHostConfigurationRejectsDuplicateIdentifiers() {
        let configuration = PTBackgroundTaskHostConfiguration(
            registrations: [.init(identifier: "same", kind: .appRefresh)],
            backgroundURLSessionIdentifiers: ["same"]
        )
        XCTAssertFalse(configuration.isValid)
    }

    func testKeychainAdapterValidatesEmptyKeysBeforeSecurityAccess() async {
        let storage = PTKeychainStorageAdapter(service: "")
        do {
            _ = try await storage.data(for: "account")
            XCTFail("An empty service must fail before touching Keychain")
        } catch PTStorageError.invalidKey {
            // English: Validation must happen before the system Keychain boundary.
            // Español: La validación debe ocurrir antes del límite del Keychain del sistema.
            // 中文：必须在进入系统 Keychain 边界前完成参数校验。
        } catch {
            XCTFail("Unexpected storage error: \(error)")
        }
    }

#if canImport(UserNotifications)
    func testLocationNotificationTriggerIsAValueSnapshot() throws {
        let trigger = PTNotificationLocationTrigger(identifier: "office",
                                                     latitude: 31.2,
                                                     longitude: 121.5,
                                                     radius: 80,
                                                     repeats: true)
        let decoded = try JSONDecoder().decode(PTNotificationLocationTrigger.self,
                                               from: JSONEncoder().encode(trigger))
        XCTAssertEqual(decoded, trigger)
    }
#endif
}
