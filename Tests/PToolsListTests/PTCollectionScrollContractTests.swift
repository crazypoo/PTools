import UIKit
import XCTest
@testable import ptools

// English: Verify the logical/physical scroll contract without depending on a network or media fixture.
// Español: Verifica el contrato de desplazamiento lógico/físico sin depender de red ni de medios reales.
// 中文：不依赖网络和媒体资源，验证逻辑页与物理投影之间的滚动契约。
@MainActor
final class PTCollectionScrollContractTests: XCTestCase {
    private func makeList(style: PTCollectionScrollStyle) -> PTCollectionView {
        let configuration = PTCollectionViewConfig()
        configuration.refreshWithoutAnimation = true
        configuration.scrollConfiguration = PTCollectionScrollConfiguration(
            style: style,
            paging: PTCollectionPagingConfiguration(allowsSkippingPages: false),
            infinite: PTCollectionInfiniteConfiguration(maxProjectedItems: 600),
            autoScroll: PTCollectionAutoScrollConfiguration()
        )
        let list = PTCollectionView(viewConfig: configuration)
        list.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        list.layoutIfNeeded()
        return list
    }

    func testInfiniteSnapshotKeepsLogicalCountAndUsesUniquePhysicalIDs() async {
        let list = makeList(style: .horizontalInfinite)
        let rows = (0..<3).map { index in
            PTRows(title: "Banner \(index)", ID: "Cell", diffId: "banner-\(index)")
        }
        let section = PTSection(identifier: "banner-section", rows: rows)
        let loaded = expectation(description: "infinite data loaded")

        list.showCollectionDetail(collectionData: [section], animated: false) { _ in
            loaded.fulfill()
        }
        await fulfillment(of: [loaded], timeout: 2)

        XCTAssertEqual(list.totalPages, 3)
        XCTAssertEqual(list.effectiveScrollStyle, .horizontalInfinite)
        let projectedIdentifiers = list.diffableDataSource.snapshot().itemIdentifiers
        XCTAssertEqual(projectedIdentifiers.count, 9)
        XCTAssertEqual(Set(projectedIdentifiers).count, projectedIdentifiers.count)
        XCTAssertEqual(list.scrollToPage(at: 2, animated: false), true)
        XCTAssertEqual(list.currentPage, 2)
    }

    func testSingleItemInfiniteRequestUsesFiniteEffectiveStyle() async {
        let list = makeList(style: .verticalInfinite)
        let section = PTSection(identifier: "single-section",
                                 rows: [PTRows(title: "Only", ID: "Cell", diffId: "only")])
        let loaded = expectation(description: "single item loaded")

        list.showCollectionDetail(collectionData: [section], animated: false) { _ in
            loaded.fulfill()
        }
        await fulfillment(of: [loaded], timeout: 2)

        XCTAssertEqual(list.totalPages, 1)
        XCTAssertEqual(list.effectiveScrollStyle, .verticalPaging)
        XCTAssertFalse(list.scrollToPage(at: 1, animated: false))
    }

    func testInfiniteConfigurationRejectsMoveInteractionWithoutChangingEffectiveMode() async {
        let configuration = PTCollectionViewConfig()
        configuration.refreshWithoutAnimation = true
        configuration.canMoveItem = true
        configuration.scrollConfiguration.style = .horizontalInfinite
        let list = PTCollectionView(viewConfig: configuration)
        let section = PTSection(identifier: "invalid-section",
                                 rows: [PTRows(title: "A", diffId: "a"), PTRows(title: "B", diffId: "b")])
        let loaded = expectation(description: "invalid combination handled")

        list.showCollectionDetail(collectionData: [section], animated: false) { _ in
            loaded.fulfill()
        }
        await fulfillment(of: [loaded], timeout: 2)

        XCTAssertEqual(list.lastScrollError, .incompatibleFeature("拖放"))
        XCTAssertEqual(list.effectiveScrollStyle, .normal)
        XCTAssertEqual(list.totalPages, 2)
    }
}
