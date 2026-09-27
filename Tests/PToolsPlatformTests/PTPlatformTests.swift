// English: Small deterministic checks for the 5.34 platform contracts.
// Español: Comprobaciones deterministas pequeñas para los contratos de plataforma 5.34.
// 中文：5.34 平台契约的小型确定性检查。

import XCTest
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
}
