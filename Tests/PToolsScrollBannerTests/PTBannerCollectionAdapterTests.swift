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

    func testEmbeddedBannerCellUsesFullViewportBelowNavigationBar() async {
        let host = UIViewController()
        let navigation = UINavigationController(rootViewController: host)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        navigation.view.layoutIfNeeded()

        let configuration = PTBannerConfiguration()
        configuration.autoScroll = false
        let banner = PTBannerView(viewConfig: configuration)
        banner.frame = CGRect(x: 0, y: 0, width: 390, height: 390)
        host.view.addSubview(banner)

        let model = PTBannerModel()
        model.media = UIImage()
        banner.bannerModel = [model]

        guard let collectionView = findCollectionView(in: banner) else {
            XCTFail("Banner should embed a UICollectionView")
            return
        }

        for _ in 0..<100 {
            host.view.layoutIfNeeded()
            banner.layoutIfNeeded()
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
            if collectionView.numberOfItems(inSection: 0) == 1,
               let attributes = collectionView.layoutAttributesForItem(
                   at: IndexPath(item: 0, section: 0)),
               abs(attributes.frame.height - 390) < 0.5 {
                break
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertEqual(collectionView.contentInsetAdjustmentBehavior, .never)
        XCTAssertEqual(collectionView.adjustedContentInset.top, 0, accuracy: 0.5)
        XCTAssertEqual(collectionView.bounds.height, 390, accuracy: 0.5)
        let itemHeight = collectionView.layoutAttributesForItem(
            at: IndexPath(item: 0, section: 0))?.frame.height
        XCTAssertNotNil(itemHeight)
        if let itemHeight {
            XCTAssertEqual(itemHeight, 390, accuracy: 0.5)
        }
    }

    func testMultiPageBannerFillsViewportAndResizesInsideNavigationHost() async {
        let host = UIViewController()
        let navigation = UINavigationController(rootViewController: host)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        navigation.view.layoutIfNeeded()

        let configuration = PTBannerConfiguration()
        configuration.autoScroll = false
        configuration.infiniteLoop = true
        let banner = PTBannerView(viewConfig: configuration)
        banner.frame = CGRect(x: 0, y: 0, width: 390, height: 390)
        host.view.addSubview(banner)

        let first = PTBannerModel()
        first.media = UIImage()
        let second = PTBannerModel()
        second.media = UIImage()
        banner.bannerModel = [first, second]

        guard let collectionView = findCollectionView(in: banner) else {
            XCTFail("Banner should embed a UICollectionView")
            return
        }

        func awaitLayout(expectedHeight: CGFloat) async -> CGFloat? {
            for _ in 0..<100 {
                host.view.layoutIfNeeded()
                banner.layoutIfNeeded()
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.layoutIfNeeded()
                if collectionView.numberOfItems(inSection: 0) > 1,
                   let attributes = collectionView.layoutAttributesForItem(
                       at: IndexPath(item: 0, section: 0)),
                   abs(attributes.frame.height - expectedHeight) < 0.5 {
                    return attributes.frame.height
                }
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
            return collectionView.layoutAttributesForItem(
                at: IndexPath(item: 0, section: 0))?.frame.height
        }

        XCTAssertEqual(collectionView.contentInsetAdjustmentBehavior, .never)
        let originalHeight = await awaitLayout(expectedHeight: 390)
        XCTAssertEqual(collectionView.bounds.height, 390, accuracy: 0.5)
        XCTAssertNotNil(originalHeight)
        if let originalHeight { XCTAssertEqual(originalHeight, 390, accuracy: 0.5) }

        // A width/height update must invalidate the pager instead of keeping
        // the initial geometry or subtracting the navigation bar again.
        banner.frame.size.height = 336
        let resizedHeight = await awaitLayout(expectedHeight: 336)
        XCTAssertNotNil(resizedHeight)
        if let resizedHeight { XCTAssertEqual(resizedHeight, 336, accuracy: 0.5) }
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
