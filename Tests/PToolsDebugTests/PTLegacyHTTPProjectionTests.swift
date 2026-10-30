import Foundation
import XCTest
@testable import PooToolsDEBUG

@MainActor
final class PTLegacyHTTPProjectionTests: XCTestCase {
    private func model(_ id: String?) -> PTHttpModel {
        let value = PTHttpModel()
        value.url = URL(string: "https://example.com/api")
        value.requestId = id
        return value
    }

    func testLegacyIDsAreDeduplicatedWithoutDuplicatingNetworkActor() {
        let store = PTHttpDatasource.shared
        store.removeAll()
        defer { store.removeAll() }
        XCTAssertTrue(store.addHttpRequest(model("same")))
        XCTAssertFalse(store.addHttpRequest(model("same")))
        XCTAssertEqual(store.httpModels.count, 1)
        XCTAssertTrue(store.addHttpRequest(model(nil)))
        XCTAssertTrue(store.addHttpRequest(model(nil)))
        XCTAssertEqual(store.httpModels.count, 3)
    }

    func testLegacyEvictionAndClearReleaseIDIndex() {
        let store = PTHttpDatasource.shared
        store.removeAll()
        defer { store.removeAll() }
        for index in 0..<1001 {
            XCTAssertTrue(store.addHttpRequest(model("request-\(index)")))
        }
        XCTAssertEqual(store.httpModels.count, 1000)
        XCTAssertTrue(store.addHttpRequest(model("request-0")))
        XCTAssertEqual(store.httpModels.count, 1000)
        store.removeAll()
        XCTAssertTrue(store.addHttpRequest(model("request-999")))
    }
}
