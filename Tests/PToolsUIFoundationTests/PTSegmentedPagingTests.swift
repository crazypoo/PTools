import UIKit
import XCTest
@testable import PooToolsPagingControl

@MainActor
final class PTSegmentedPagingTests: XCTestCase {
    func testMeasuredWidthIncludesBadgeAndSelectedFont() {
        let style = PTSegmentStyle(normalFont: .systemFont(ofSize: 14),
                                    selectedFont: .boldSystemFont(ofSize: 20),
                                    itemInsets: .zero,
                                    distribution: .intrinsic)
        let title = PTSegmentItem.title(id: "orders", "待付款")
        let withBadge = PTSegmentItem.title(id: "orders", "待付款", badge: PTSegmentBadge(text: "999+"))

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
        let expectedMinimum = ceil((title + style.itemHeight - 12 + style.imageSpacing) * style.selectedScale)

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
        let initial = PTSegmentItem.title(id: "orders", "待付款", badge: PTSegmentBadge(text: "1"))
        let updated = PTSegmentItem.title(id: "orders", "待付款", badge: PTSegmentBadge(text: "999+"))
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
}
