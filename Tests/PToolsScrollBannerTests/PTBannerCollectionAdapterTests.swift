// English: Verify the PTBannerView-to-PTCollectionView migration contract without UIKit rendering.
// Español: Verifica el contrato de migración de PTBannerView a PTCollectionView sin renderizado UIKit.
// 中文：不依赖 UIKit 渲染，验证 PTBannerView 到 PTCollectionView 的迁移契约。

import XCTest
import UIKit
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

    func testSingleBannerFallsBackToFinitePaging() {
        let configuration = PTBannerConfiguration()
        configuration.infiniteLoop = true
        configuration.autoScroll = true

        let result = PTBannerCollectionAdapter().makeScrollConfiguration(
            configuration: configuration,
            itemCount: 1,
            defaultInterval: 3
        )

        XCTAssertEqual(result.style, .horizontalPaging)
        XCTAssertFalse(result.autoScroll.isEnabled)
    }

    func testSingleBannerTapReachesDidSelectIndex() async {
        let configuration = PTBannerConfiguration()
        configuration.infiniteLoop = true
        configuration.autoScroll = false

        let banner = PTBannerView(viewConfig: configuration)
        banner.frame = CGRect(x: 0, y: 0, width: 320, height: 160)
        let model = PTBannerModel()
        model.media = UIImage()
        banner.bannerModel = [model]
        banner.layoutIfNeeded()

        guard let collectionView = findCollectionView(in: banner) else {
            XCTFail("Banner should embed a UICollectionView")
            return
        }

        // The Diffable snapshot can complete on a subsequent main-actor turn.
        for _ in 0..<100 where collectionView.numberOfItems(inSection: 0) == 0 {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(collectionView.numberOfItems(inSection: 0), 1)

        var selectedIndices: [Int] = []
        banner.didSelectIndex = { selectedIndices.append($0) }

        collectionView.delegate?.collectionView?(
            collectionView,
            didSelectItemAt: IndexPath(item: 0, section: 0)
        )
        XCTAssertEqual(selectedIndices, [0])
    }

    private func findCollectionView(in view: UIView) -> UICollectionView? {
        if let collectionView = view as? UICollectionView { return collectionView }
        for subview in view.subviews {
            if let collectionView = findCollectionView(in: subview) {
                return collectionView
            }
        }
        return nil
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
