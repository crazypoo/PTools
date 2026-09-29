import UIKit
import XCTest
import ptools
@testable import PooToolsPagingControl

@MainActor
final class PTSegmentedPagingTests: XCTestCase {
    func testMeasuredWidthIncludesBadgeAndSelectedFont() {
        let style = PTSegmentStyle(normalFont: .systemFont(ofSize: 14),
                                    selectedFont: .boldSystemFont(ofSize: 20),
                                    itemInsets: .zero,
                                    distribution: .intrinsic)
        let title = PTSegmentItem.title(id: "orders", "待付款")
        let withBadge = PTSegmentItem.title(id: "orders",
                                            "待付款",
                                            badgeDescriptor: PTSegmentBadgeDescriptor(content: .text("999+")))

        let titleWidth = PTMainSegmentCell.measuredWidth(item: title, style: style)
        let badgeWidth = PTMainSegmentCell.measuredWidth(item: withBadge, style: style)

        XCTAssertGreaterThan(badgeWidth, titleWidth)
        XCTAssertGreaterThanOrEqual(badgeWidth, titleWidth + 18)
    }

    func testSelectedScaleAndRenderedImageSideAreIncludedInMeasurement() {
        let style = PTSegmentStyle(normalFont: .systemFont(ofSize: 14),
                                    selectedFont: .boldSystemFont(ofSize: 14),
                                    itemHeight: 44,
                                    itemInsets: .zero,
                                    distribution: .intrinsic,
                                    selectedScale: 1.2)
        let image = UIImage(systemName: "star")!
        let item = PTSegmentItem.titleImage(id: "star", title: "收藏", image: image)

        let measured = PTMainSegmentCell.measuredWidth(item: item, style: style)
        let title = "收藏".size(withAttributes: [.font: style.selectedFont]).width
        let expectedMinimum = ceil(title * style.selectedScale + style.itemHeight - 12 + style.imageSpacing)

        XCTAssertGreaterThanOrEqual(measured, expectedMinimum)
    }

    func testIndicatorUsesItsOwnFixedWidthAndCustomPlacement() {
        let itemFrame = CGRect(x: 20, y: 0, width: 100, height: 44)
        let contentFrame = CGRect(x: 45, y: 0, width: 50, height: 44)
        let context = PTSegmentIndicatorContext(bounds: CGRect(x: 0, y: 0, width: 200, height: 44),
                                                 itemFrames: [AnyHashable("orders"): itemFrame],
                                                 selectedID: "orders",
                                                 placement: .bottom,
                                                 widthPolicy: .content,
                                                 contentFrames: [AnyHashable("orders"): contentFrame])
        let fixed = PTLineIndicator(widthPolicy: .fixed(30))
        fixed.prepare(context: context)

        XCTAssertEqual(fixed.frame.width, 30, accuracy: 0.001)
        XCTAssertEqual(fixed.frame.midX, itemFrame.midX, accuracy: 0.001)

        let custom = PTLineIndicator(placement: .custom { item, bounds in
            CGRect(x: item.minX, y: bounds.maxY - 5, width: item.width, height: 5)
        })
        custom.prepare(context: context)

        XCTAssertEqual(custom.frame, CGRect(x: itemFrame.minX,
                                            y: context.bounds.maxY - 5,
                                            width: itemFrame.width,
                                            height: 5))
    }

    func testContentIndicatorUsesContentFrameCenter() {
        let itemFrame = CGRect(x: 0, y: 0, width: 160, height: 44)
        let contentFrame = CGRect(x: 54, y: 0, width: 52, height: 44)
        let context = PTSegmentIndicatorContext(bounds: CGRect(x: 0, y: 0, width: 160, height: 44),
                                                 itemFrames: [AnyHashable("home"): itemFrame],
                                                 selectedID: "home",
                                                 widthPolicy: .content,
                                                 contentFrames: [AnyHashable("home"): contentFrame])
        let indicator = PTLineIndicator()
        indicator.prepare(context: context)

        XCTAssertEqual(indicator.frame.midX, contentFrame.midX, accuracy: 0.001)
        XCTAssertEqual(indicator.frame.width, contentFrame.width, accuracy: 0.001)
    }

    func testManualSegmentScrollDoesNotChangeSelection() {
        let segmentedView = PTSegmentedView(frame: CGRect(x: 0, y: 0, width: 240, height: 44))
        segmentedView.style = PTSegmentStyle(itemInsets: .zero, distribution: .intrinsic)
        segmentedView.apply(items: [
            .title(id: "a", "A"),
            .title(id: "b", "B"),
            .title(id: "c", "C")
        ], animatingDifferences: false)
        segmentedView.layoutIfNeeded()
        segmentedView.select(id: "a", animated: false)
        let originalSelection = segmentedView.selectionState.selectedID

        segmentedView.collectionView.setContentOffset(CGPoint(x: 80, y: 0), animated: false)
        segmentedView.scrollViewDidScroll(segmentedView.collectionView)
        segmentedView.scrollViewDidEndDragging(segmentedView.collectionView, willDecelerate: false)

        XCTAssertEqual(segmentedView.selectionState.selectedID, originalSelection)
    }

    func testDynamicBadgeKeepsStableSelectionID() {
        let segmentedView = PTSegmentedView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        let initial = PTSegmentItem.title(id: "orders",
                                          "待付款",
                                          badgeDescriptor: PTSegmentBadgeDescriptor(content: .number(1)))
        let updated = PTSegmentItem.title(id: "orders",
                                          "待付款",
                                          badgeDescriptor: PTSegmentBadgeDescriptor(content: .number(999)))
        let style = PTSegmentStyle(itemInsets: .zero, distribution: .intrinsic)

        segmentedView.style = style
        segmentedView.apply(items: [initial], animatingDifferences: false)
        let initialWidth = PTMainSegmentCell.measuredWidth(item: initial, style: style)
        segmentedView.apply(items: [updated], animatingDifferences: false)
        let updatedWidth = PTMainSegmentCell.measuredWidth(item: updated, style: style)

        XCTAssertEqual(segmentedView.selectionState.selectedID, AnyHashable("orders"))
        XCTAssertGreaterThan(updatedWidth, initialWidth)
    }

    func testProgrammaticSelectionEmitsOnceWhenAnimationFinishes() {
        let segmentedView = PTSegmentedView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        segmentedView.apply(items: [
            .title(id: "a", "A"),
            .title(id: "b", "B")
        ], animatingDifferences: false)
        var eventCount = 0
        segmentedView.onSelectionChanged = { _ in eventCount += 1 }

        segmentedView.select(id: "b", animated: true)
        segmentedView.scrollViewDidEndScrollingAnimation(segmentedView.collectionView)

        XCTAssertEqual(eventCount, 1)
        XCTAssertEqual(segmentedView.selectionState.selectedID, AnyHashable("b"))
    }

    func testJXCompatibilitySwitchesUseCanonicalPolicies() {
        var style = PTSegmentStyle()
        style.isTitleColorGradientEnabled = true
        style.isTitleZoomEnabled = true
        style.isSelectedAnimable = true
        style.isItemSpacingAverageEnabled = true

        XCTAssertEqual(style.titleColorTransition, .gradient)
        XCTAssertEqual(style.titleZoomTransition, .selectedScale)
        XCTAssertEqual(style.selectionTransition, .animated)
        XCTAssertEqual(style.spacingDistribution, .averageWhenPossible)
    }

    func testTypedBadgeUsesStyleConfigurationAndCoreDisplayRules() {
        var configuration = PTBadgeConfiguration()
        configuration.maximumNumber = 99
        let item = PTSegmentItem.title(
            id: "orders",
            "订单",
            badgeDescriptor: PTSegmentBadgeDescriptor(content: .number(120), configuration: configuration)
        )
        let style = PTSegmentStyle(itemInsets: .zero, distribution: .intrinsic)

        XCTAssertEqual(PTBadgeLayoutMetrics.displayText(for: .number(120), configuration: configuration), "99+")
        XCTAssertGreaterThan(PTMainSegmentCell.measuredWidth(item: item, style: style), 0)
    }

    func testInlineBadgeUsesTheSameMetricsAsOverlayBadge() {
        var configuration = PTBadgeConfiguration()
        configuration.maximumNumber = 99
        configuration.borderWidth = 1
        let inlineBadge = PTInlineBadgeView()
        inlineBadge.apply(content: .number(120), configuration: configuration, onRemove: nil)

        XCTAssertEqual(inlineBadge.intrinsicContentSize,
                       PTBadgeLayoutMetrics.size(for: .number(120), configuration: configuration))
        XCTAssertEqual(PTBadgeLayoutMetrics.displayText(for: .number(120), configuration: configuration), "99+")
    }

    func testAverageSpacingPreservesIntrinsicItemWidths() {
        let segmentedView = PTSegmentedView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        segmentedView.style = PTSegmentStyle(itemInsets: .zero,
                                              itemSpacing: 8,
                                              distribution: .intrinsic,
                                              spacingDistribution: .averageWhenPossible)
        let items = [
            PTSegmentItem.title(id: "a", "A"),
            PTSegmentItem.title(id: "b", "BBBB"),
            PTSegmentItem.title(id: "c", "CCCCCC")
        ]
        segmentedView.apply(items: items, animatingDifferences: false)
        segmentedView.layoutIfNeeded()

        guard let layout = segmentedView.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            XCTFail("Expected a flow layout")
            return
        }
        let widths = items.indices.map {
            segmentedView.collectionView(segmentedView.collectionView,
                                         layout: layout,
                                         sizeForItemAt: IndexPath(item: $0, section: 0)).width
        }
        XCTAssertGreaterThan(layout.minimumLineSpacing, 8)
        XCTAssertNotEqual(widths[0], widths[1])
        XCTAssertNotEqual(widths[1], widths[2])
    }

    func testAverageSpacingFallsBackToMinimumWhenContentDoesNotFit() {
        let segmentedView = PTSegmentedView(frame: CGRect(x: 0, y: 0, width: 80, height: 44))
        segmentedView.style = PTSegmentStyle(itemInsets: .zero,
                                              itemSpacing: 7,
                                              distribution: .intrinsic,
                                              spacingDistribution: .averageWhenPossible)
        segmentedView.apply(items: [
            .title(id: "a", "A very long title"),
            .title(id: "b", "Another long title")
        ], animatingDifferences: false)
        segmentedView.layoutIfNeeded()

        guard let layout = segmentedView.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            XCTFail("Expected a flow layout")
            return
        }
        XCTAssertEqual(layout.minimumLineSpacing, 7, accuracy: 0.001)
    }

    func testAverageSpacingDoesNotExpandEqualDistributionOrSingleItem() {
        let equalView = PTSegmentedView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        equalView.style = PTSegmentStyle(itemInsets: .zero,
                                         itemSpacing: 5,
                                         distribution: .equal,
                                         spacingDistribution: .averageWhenPossible)
        equalView.apply(items: [
            .title(id: "a", "A"),
            .title(id: "b", "B")
        ], animatingDifferences: false)
        equalView.layoutIfNeeded()

        let singleView = PTSegmentedView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        singleView.style = PTSegmentStyle(itemInsets: .zero,
                                          itemSpacing: 6,
                                          distribution: .intrinsic,
                                          spacingDistribution: .averageWhenPossible)
        singleView.apply(items: [.title(id: "single", "Single")], animatingDifferences: false)
        singleView.layoutIfNeeded()

        guard let equalLayout = equalView.collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
              let singleLayout = singleView.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            XCTFail("Expected flow layouts")
            return
        }
        XCTAssertEqual(equalLayout.minimumLineSpacing, 5, accuracy: 0.001)
        XCTAssertEqual(singleLayout.minimumLineSpacing, 6, accuracy: 0.001)
    }

    func testItemSeparatorDefaultKeepsLegacyAppearance() {
        let style = PTSegmentStyle()
        guard case .line(let configuration) = style.itemSeparatorStyle else {
            return XCTFail("The default separator must preserve the legacy line")
        }
        XCTAssertEqual(configuration.thickness, 1)
        XCTAssertEqual(configuration.topInset, 10)
        XCTAssertEqual(configuration.bottomInset, 10)
        if case .leading = configuration.placement {} else { XCTFail("Legacy placement must be leading") }
        if case .allItems = configuration.visibility {} else { XCTFail("Legacy visibility must be allItems") }

        let cell = PTMainSegmentCell(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        cell.configure(item: .title(id: "item", "标题"),
                       style: style,
                       selected: false,
                       layoutContext: PTSegmentCellLayoutContext(index: 0, itemCount: 3))
        cell.layoutIfNeeded()
        XCTAssertFalse(cell.lineView.isHidden)
    }

    func testItemSeparatorNoneAndBetweenItemsVisibility() {
        var noneStyle = PTSegmentStyle()
        noneStyle.itemSeparatorStyle = .none
        let noneCell = configuredSeparatorCell(style: noneStyle, index: 0, itemCount: 3)
        XCTAssertTrue(noneCell.lineView.isHidden)

        var leadingStyle = PTSegmentStyle()
        leadingStyle.itemSeparatorStyle = .line(.init(visibility: .betweenItems))
        XCTAssertTrue(configuredSeparatorCell(style: leadingStyle, index: 0, itemCount: 3).lineView.isHidden)
        XCTAssertFalse(configuredSeparatorCell(style: leadingStyle, index: 1, itemCount: 3).lineView.isHidden)
        XCTAssertFalse(configuredSeparatorCell(style: leadingStyle, index: 2, itemCount: 3).lineView.isHidden)
        XCTAssertTrue(configuredSeparatorCell(style: leadingStyle, index: 0, itemCount: 1).lineView.isHidden)

        var trailingStyle = PTSegmentStyle()
        trailingStyle.itemSeparatorStyle = .line(.init(placement: .trailing, visibility: .betweenItems))
        XCTAssertFalse(configuredSeparatorCell(style: trailingStyle, index: 0, itemCount: 3).lineView.isHidden)
        XCTAssertFalse(configuredSeparatorCell(style: trailingStyle, index: 1, itemCount: 3).lineView.isHidden)
        XCTAssertTrue(configuredSeparatorCell(style: trailingStyle, index: 2, itemCount: 3).lineView.isHidden)
    }

    func testItemSeparatorGeometryAndInvalidValuesAreSafe() {
        var style = PTSegmentStyle()
        style.itemSeparatorStyle = .line(.init(color: .systemRed,
                                               thickness: 2,
                                               topInset: 4,
                                               bottomInset: 8,
                                               placement: .trailing,
                                               visibility: .allItems))
        let cell = configuredSeparatorCell(style: style, index: 1, itemCount: 3)
        XCTAssertEqual(cell.lineView.backgroundColor, .systemRed)
        XCTAssertEqual(cell.lineView.frame.width, 2, accuracy: 0.001)
        XCTAssertEqual(cell.lineView.frame.minY, 4, accuracy: 0.001)
        XCTAssertEqual(cell.lineView.frame.height, 32, accuracy: 0.001)
        XCTAssertEqual(cell.lineView.frame.maxX, cell.contentView.bounds.maxX, accuracy: 0.001)

        var invalidStyle = PTSegmentStyle()
        invalidStyle.itemSeparatorStyle = .line(.init(thickness: .nan,
                                                       topInset: -.infinity,
                                                       bottomInset: .infinity))
        let invalidCell = PTMainSegmentCell(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        invalidCell.configure(item: .title(id: "invalid", "异常"),
                              style: invalidStyle,
                              selected: false,
                              layoutContext: PTSegmentCellLayoutContext(index: 0, itemCount: 1))
        invalidCell.layoutIfNeeded()
        XCTAssertEqual(invalidCell.lineView.frame.width, 1, accuracy: 0.001)
        XCTAssertEqual(invalidCell.lineView.frame.minY, 0, accuracy: 0.001)
        XCTAssertEqual(invalidCell.lineView.frame.height, 20, accuracy: 0.001)
    }

    func testItemSeparatorDoesNotAffectMeasurementOrTitleTransition() {
        let item = PTSegmentItem.title(id: "item", "标题")
        var lineStyle = PTSegmentStyle(itemInsets: .zero, distribution: .intrinsic)
        lineStyle.itemSeparatorStyle = .line(.init(thickness: 2))
        var noneStyle = lineStyle
        noneStyle.itemSeparatorStyle = .none

        XCTAssertEqual(PTMainSegmentCell.measuredWidth(item: item, style: lineStyle),
                       PTMainSegmentCell.measuredWidth(item: item, style: noneStyle))

        let cell = configuredSeparatorCell(style: lineStyle, index: 0, itemCount: 2)
        cell.applyTransition(selectedProgress: 1, style: lineStyle)
        XCTAssertEqual(cell.lineView.transform, .identity)
    }

    func testItemSeparatorReuseClearsPreviousStyle() {
        var style = PTSegmentStyle()
        style.itemSeparatorStyle = .line(.init(color: .systemRed,
                                               thickness: 2,
                                               placement: .trailing,
                                               visibility: .allItems))
        let cell = configuredSeparatorCell(style: style, index: 0, itemCount: 2)
        cell.prepareForReuse()

        XCTAssertTrue(cell.lineView.isHidden)
        XCTAssertEqual(cell.lineView.backgroundColor, .clear)
        XCTAssertEqual(cell.lineView.transform, .identity)
    }

    private func configuredSeparatorCell(style: PTSegmentStyle,
                                         index: Int,
                                         itemCount: Int) -> PTMainSegmentCell {
        let cell = PTMainSegmentCell(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        cell.configure(item: .title(id: "item-\(index)", "标题"),
                       style: style,
                       selected: false,
                       layoutContext: PTSegmentCellLayoutContext(index: index, itemCount: itemCount))
        cell.layoutIfNeeded()
        return cell
    }
}
