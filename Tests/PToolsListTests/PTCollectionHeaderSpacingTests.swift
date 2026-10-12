import XCTest
import UIKit
@testable import ptools

// English: Keep a small reusable header so spacing tests exercise UIKit's real supplementary attributes.
// Español: Mantiene un header pequeño y reutilizable para que las pruebas usen atributos supplementary reales de UIKit.
// 中文：使用小型可复用 Header，让间距测试真正读取 UIKit 的 Supplementary 布局属性。
@MainActor
private final class PTCollectionSpacingTestHeader: UICollectionReusableView {
    static let reuseID = "PTCollectionSpacingTestHeader"
}

// English: Reuse the same lightweight view for footer frame measurements.
// Español: Reutiliza la misma vista ligera para medir los frames del footer.
// 中文：复用同一个轻量视图，测量 Footer 的布局 Frame。
@MainActor
private final class PTCollectionSpacingTestFooter: UICollectionReusableView {
    static let reuseID = "PTCollectionSpacingTestFooter"
}

@MainActor
final class PTCollectionHeaderSpacingTests: XCTestCase {
    private func makeList(viewType: PTCollectionViewType = .Normal,
                          headerHeight: CGFloat? = 44,
                          sectionInsets: NSDirectionalEdgeInsets? = nil,
                          headerSpacing: CGFloat = 0,
                          footerHeight: CGFloat? = nil,
                          footerSpacing: CGFloat = 0,
                          estimatedHeight: Bool = false) -> (PTCollectionView, PTSection) {
        let configuration = PTCollectionViewConfig()
        configuration.viewType = viewType
        configuration.itemHeight = 44
        configuration.rowCount = 2
        configuration.contentTopSpace = 0
        configuration.contentBottomSpace = 0
        configuration.cellLeadingSpace = 0
        configuration.cellTrailingSpace = 0
        configuration.sectionEdges = .zero
        configuration.decorationItemsType = .NoItems
        configuration.refreshWithoutAnimation = true

        let list = PTCollectionView(viewConfig: configuration)
        list.frame = CGRect(x: 0, y: 0, width: 320, height: 640)
        list.registerClassCells(classs: ["PTCollectionSpacingTestCell": UICollectionViewCell.self])
        list.registerSupplementaryView(classs: [PTCollectionSpacingTestHeader.reuseID: PTCollectionSpacingTestHeader.self],
                                       kind: UICollectionView.elementKindSectionHeader)
        list.registerSupplementaryView(classs: [PTCollectionSpacingTestFooter.reuseID: PTCollectionSpacingTestFooter.self],
                                       kind: UICollectionView.elementKindSectionFooter)
        list.cellInCollectionV2 = { collectionView, context in
            collectionView.dequeueReusableCell(withReuseIdentifier: "PTCollectionSpacingTestCell",
                                                for: context.indexPath)
        }
        list.headerInCollection = { _, collectionView, _, indexPath in
            collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                             withReuseIdentifier: PTCollectionSpacingTestHeader.reuseID,
                                                             for: indexPath)
        }
        list.footerInCollection = { _, collectionView, _, indexPath in
            collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                             withReuseIdentifier: PTCollectionSpacingTestFooter.reuseID,
                                                             for: indexPath)
        }

        let row = PTRows(title: "Cell", ID: "PTCollectionSpacingTestCell", diffId: "spacing-row")
        let section = PTSection(identifier: "spacing-section",
                                headerID: headerHeight == nil ? "" : PTCollectionSpacingTestHeader.reuseID,
                                headerHeight: headerHeight,
                                footerID: footerHeight == nil ? "" : PTCollectionSpacingTestFooter.reuseID,
                                footerHeight: footerHeight,
                                rows: [row])
        section.layoutConfiguration = PTSectionLayoutConfiguration(contentInsets: sectionInsets,
                                                                    headerSpacing: headerSpacing,
                                                                    footerSpacing: footerSpacing,
                                                                    itemHeight: estimatedHeight ? .estimated(44) : nil)
        return (list, section)
    }

    private func load(_ list: PTCollectionView, section: PTSection) async {
        let expectation = expectation(description: "collection content loaded")
        list.showCollectionDetail(collectionData: [section], animated: false) { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)
        await Task.yield()
        list.layoutIfNeeded()
        list.contentCollectionView.layoutIfNeeded()
    }

    private func attributes(in list: PTCollectionView) -> (UICollectionViewLayoutAttributes, UICollectionViewLayoutAttributes)? {
        let collectionView = list.contentCollectionView
        guard let header = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader,
                                                                                   at: IndexPath(item: 0, section: 0)),
              let cell = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) else {
            return nil
        }
        return (header, cell)
    }

    // English: Custom groups must not receive header height a second time as section padding.
    // Español: Los grupos personalizados no deben recibir la altura del header otra vez como padding de sección.
    // 中文：Custom 分组不能再次把 Header 高度当作 Section 内边距。
    func testCustomLayoutHeaderDoesNotAddDuplicateTopInset() async {
        let (list, section) = makeList(viewType: .Custom)
        list.customerLayoutWithEnvironment = { _, _, _ in
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                  heightDimension: .absolute(44)))
            return NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                        heightDimension: .absolute(44)),
                                                     subitems: [item])
        }
        await load(list, section: section)
        guard let (header, cell) = attributes(in: list) else {
            XCTFail("Header 或 Cell 布局属性不存在")
            return
        }
        XCTAssertLessThanOrEqual(abs(cell.frame.minY - header.frame.maxY), 1)
    }

    // English: Grid groups must keep header height in the boundary supplementary item only.
    // Español: Los grupos grid deben mantener la altura del header solo en el supplementary boundary.
    // 中文：Grid 分组必须只在 Boundary Supplementary 中保留 Header 高度。
    func testGridLayoutHeaderDoesNotAddDuplicateTopInset() async {
        let (list, section) = makeList(viewType: .Gird)
        await load(list, section: section)
        guard let (header, cell) = attributes(in: list) else {
            XCTFail("Header 或 Cell 布局属性不存在")
            return
        }
        XCTAssertLessThanOrEqual(abs(cell.frame.minY - header.frame.maxY), 1)
    }

    func testNormalLayoutHeaderDoesNotAddDuplicateTopInset() async {
        let (list, section) = makeList(viewType: .Normal)
        await load(list, section: section)
        guard let (header, cell) = attributes(in: list) else {
            XCTFail("Header 或 Cell 布局属性不存在")
            return
        }
        XCTAssertLessThanOrEqual(abs(cell.frame.minY - header.frame.maxY), 1)
    }

    func testConfiguredHeaderSpacingOccursOnce() async {
        let (list, section) = makeList(headerSpacing: 8)
        await load(list, section: section)
        guard let (header, cell) = attributes(in: list) else {
            XCTFail("Header 或 Cell 布局属性不存在")
            return
        }
        XCTAssertEqual(cell.frame.minY - header.frame.maxY, 8, accuracy: 1)
    }

    // English: Footer spacing must be reserved by the section instead of shifting the footer visually.
    // Español: El espaciado del footer debe reservarlo la sección, no moverlo solo visualmente.
    // 中文：Footer 间距必须由 Section 真实预留，而不是只移动 Footer 的视觉位置。
    func testConfiguredFooterSpacingOccursOnce() async {
        let (list, section) = makeList(headerHeight: nil, footerHeight: 28, footerSpacing: 8)
        await load(list, section: section)
        guard let footer = list.contentCollectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionFooter,
                                                                                                at: IndexPath(item: 0, section: 0)),
              let cell = list.contentCollectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) else {
            XCTFail("Footer 或 Cell 布局属性不存在")
            return
        }
        XCTAssertEqual(footer.frame.minY - cell.frame.maxY, 8, accuracy: 1)
    }

    func testSectionInsetsAreHonoredExactlyOnce() async {
        let (list, section) = makeList(headerHeight: nil,
                                       sectionInsets: NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 8, trailing: 0))
        await load(list, section: section)
        guard let cell = list.contentCollectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) else {
            XCTFail("Cell 布局属性不存在")
            return
        }
        XCTAssertEqual(cell.frame.minY, 12, accuracy: 1)
    }

    func testNoHeaderDoesNotReserveHeaderHeight() async {
        let (list, section) = makeList(headerHeight: nil)
        await load(list, section: section)
        guard let cell = list.contentCollectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) else {
            XCTFail("Cell 布局属性不存在")
            return
        }
        XCTAssertEqual(cell.frame.minY, 0, accuracy: 1)
    }

    func testHeaderHeightChangeInvalidatesLayoutCache() async {
        let (list, section) = makeList()
        await load(list, section: section)
        let oldVersion = section.layoutVersion
        section.headerHeight = 64
        list.invalidateSectionLayout(at: [0])
        await Task.yield()
        XCTAssertGreaterThan(section.layoutVersion, oldVersion)
    }

    func testCustomSupplementaryItemsRemainCompatible() async {
        let (list, section) = makeList(viewType: .Custom)
        list.customReuseViews = true
        list.customerReuseViews = { _, _ in
            [NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .absolute(44)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )]
        }
        list.customerLayout = { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                  heightDimension: .absolute(44)))
            return NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                        heightDimension: .absolute(44)),
                                                     subitems: [item])
        }
        await load(list, section: section)
        XCTAssertNotNil(attributes(in: list))
    }

    func testEstimatedHeightRetainsRequestedContentSpacing() async {
        let (list, section) = makeList(viewType: .Normal, sectionInsets: nil, estimatedHeight: true)
        section.layoutConfiguration?.topSpacing = 12
        await load(list, section: section)
        guard let cell = list.contentCollectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) else {
            XCTFail("Cell 布局属性不存在")
            return
        }
        XCTAssertEqual(cell.frame.minY, 12, accuracy: 1)
    }

    func testDecorationModesDoNotShiftContentUnexpectedly() async {
        let (list, section) = makeList(headerHeight: nil)
        list.viewConfig.decorationItemsType = .Normal
        list.viewConfig.decorationItemsEdges = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
        await load(list, section: section)
        guard let cell = list.contentCollectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) else {
            XCTFail("Cell 布局属性不存在")
            return
        }
        XCTAssertEqual(cell.frame.minY, 0, accuracy: 1)
    }

    func testNestedGridUsesEnvironmentWidth() async {
        let (list, section) = makeList(viewType: .Custom)
        var width: CGFloat = 0
        list.customerLayoutWithEnvironment = { _, _, environment in
            width = environment.container.contentSize.width
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                  heightDimension: .absolute(44)))
            return NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(max(1, width)),
                                                                                        heightDimension: .absolute(44)),
                                                     subitems: [item])
        }
        await load(list, section: section)
        XCTAssertGreaterThan(width, 0)
    }

    func testLayoutSwitchAndReloadDoNotReintroduceGap() async {
        let (list, section) = makeList(viewType: .Gird)
        await load(list, section: section)
        let expectation = expectation(description: "layout switched")
        list.switchLayout(to: .Normal, animated: false) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)
        list.reloadSections(at: [0], animated: false)
        await Task.yield()
        guard let (header, cell) = attributes(in: list) else {
            XCTFail("Header 或 Cell 布局属性不存在")
            return
        }
        XCTAssertLessThanOrEqual(abs(cell.frame.minY - header.frame.maxY), 1)
    }
}
