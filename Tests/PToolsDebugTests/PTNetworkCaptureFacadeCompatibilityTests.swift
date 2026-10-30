import XCTest
import Foundation
import PooToolsDEBUG

// Compiled by the iOS Debug XCTest target. Importing only the historical
// PooToolsDEBUG module must keep Network capture types source-compatible.
final class PTNetworkCaptureFacadeCompatibilityTests: XCTestCase {
    func testLegacyModuleReexportsCanonicalCaptureTypes() {
        let storeType: PTNetworkCaptureStore.Type = PTNetworkCaptureStore.self
        let policy: PTNetworkPrivacyPolicy = .default
        let filter = PTNetworkCaptureFilter(keyword: "endpoint")
        XCTAssertEqual(String(describing: storeType), "PTNetworkCaptureStore")
        XCTAssertEqual(policy.replacement, "[REDACTED]")
        XCTAssertEqual(filter.keyword, "endpoint")
    }
}
