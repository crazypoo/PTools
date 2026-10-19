// English: Verify the PTBannerView-to-PTCollectionView migration contract without UIKit rendering.
// Español: Verifica el contrato de migración de PTBannerView a PTCollectionView sin renderizado UIKit.
// 中文：不依赖 UIKit 渲染，验证 PTBannerView 到 PTCollectionView 的迁移契约。

import XCTest
@testable import PooToolsScrollBanner

@MainActor
final class PTBannerCollectionAdapterTests: XCTestCase {
    func testMapsToViewportPagingAndAutoScroll() {
        var configuration = PTBannerConfiguration()
        configuration.infiniteLoop = true
        configuration.autoScroll = true

        let adapter = PTBannerCollectionAdapter()
        let result = adapter.makeScrollConfiguration(configuration: configuration,
                                                      itemCount: 3,
                                                      defaultInterval: 3)

        XCTAssertEqual(result.style, .horizontalInfinite)
        XCTAssertEqual(result.paging.snapMode, .viewport)
        XCTAssertTrue(result.autoScroll.isEnabled)
        XCTAssertEqual(result.autoScroll.interval, 3)
    }

    func testCreatesStableLogicalRows() {
        let adapter = PTBannerCollectionAdapter()
        let models = (0..<3).map { _ in PTBannerModel() }
        let section = adapter.makeSection(models: models)
        let identifiers = section.rows?.map(\.diffId) ?? []

        XCTAssertEqual(identifiers.count, 3)
        XCTAssertEqual(identifiers.count, Set(identifiers).count)
    }
}
