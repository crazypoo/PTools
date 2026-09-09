import XCTest
@testable import ptools

@MainActor
final class PTUIFoundationContractTests: XCTestCase {
    func testSkeletonConfigurationUsesSafeDefaults() {
        let configuration = PTCollectionViewConfig()

        XCTAssertEqual(configuration.skeletonItemCount, 6)
        XCTAssertEqual(configuration.skeletonCornerRadius, 8)
    }

    func testSkeletonConfigurationAcceptsBoundedCustomValues() {
        let configuration = PTCollectionViewConfig()
        configuration.skeletonItemCount = 12
        configuration.skeletonCornerRadius = 14

        XCTAssertEqual(configuration.skeletonItemCount, 12)
        XCTAssertEqual(configuration.skeletonCornerRadius, 14)
    }
}
