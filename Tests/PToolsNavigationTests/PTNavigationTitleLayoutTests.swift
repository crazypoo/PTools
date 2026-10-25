import UIKit
import XCTest
@testable import ptools

@MainActor
private final class IntrinsicTitleView: UIView {
    let preferredSize: CGSize

    init(preferredSize: CGSize) {
        self.preferredSize = preferredSize
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize { preferredSize }
}

@MainActor
final class PTNavigationTitleLayoutTests: XCTestCase {
    private let visibleRect = CGRect(x: 0, y: 0, width: 390, height: 44)

    private func resolve(visibleRect: CGRect = CGRect(x: 0, y: 0, width: 390, height: 44),
                         leftWidth: CGFloat = 0,
                         rightWidth: CGFloat = 0,
                         desiredSize: CGSize = CGSize(width: 100, height: 32),
                         mode: PTNavigationTitleLayoutMode,
                         minimumEdgeInset: CGFloat = 16,
                         itemSpacing: CGFloat = 8) -> PTNavigationTitleLayoutResult {
        let input = PTNavigationTitleLayoutResolver.makeInput(
            visibleRect: visibleRect,
            leftWidth: leftWidth,
            rightWidth: rightWidth,
            desiredTitleSize: desiredSize,
            minimumEdgeInset: minimumEdgeInset,
            itemSpacing: itemSpacing,
            mode: mode
        )
        return PTNavigationTitleLayoutResolver.resolve(input)
    }

    func testNAV_TITLE_001_centerMeasuredUsesVisibleCenter() {
        let result = resolve(rightWidth: 44, mode: .centerMeasured)

        XCTAssertTrue(result.shouldDisplay)
        XCTAssertEqual(result.titleFrame.midX, visibleRect.midX, accuracy: 0.01)
    }

    func testNAV_TITLE_002_asymmetricButtonsDoNotOverlapCenteredTitle() {
        let result = resolve(leftWidth: 40,
                             rightWidth: 120,
                             desiredSize: CGSize(width: 300, height: 32),
                             mode: .centerMeasured)

        XCTAssertTrue(result.shouldDisplay)
        XCTAssertEqual(result.titleFrame.midX, visibleRect.midX, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(result.titleFrame.minX, 64)
        XCTAssertLessThanOrEqual(result.titleFrame.maxX, 246)
    }

    func testNAV_TITLE_003_noButtonsKeepsContentCentered() {
        let result = resolve(mode: .centerMeasured)

        XCTAssertTrue(result.shouldDisplay)
        XCTAssertEqual(result.titleFrame.midX, visibleRect.midX, accuracy: 0.01)
        XCTAssertEqual(result.titleFrame.width, 100, accuracy: 0.01)
    }

    func testNAV_TITLE_004_fillAvailableUsesRemainingSpace() {
        let result = resolve(leftWidth: 40, rightWidth: 120, mode: .fillAvailable)

        XCTAssertTrue(result.shouldDisplay)
        XCTAssertEqual(result.titleFrame.minX, 64, accuracy: 0.01)
        XCTAssertEqual(result.titleFrame.maxX, 246, accuracy: 0.01)
    }

    func testNAV_TITLE_005_wideTitleCompressesWithoutInvalidFrame() {
        let result = resolve(leftWidth: 40,
                             rightWidth: 40,
                             desiredSize: CGSize(width: 1_000, height: 32),
                             mode: .centerMeasured)

        XCTAssertTrue(result.shouldDisplay)
        XCTAssertTrue(result.isWidthCompressed)
        XCTAssertTrue(result.titleFrame.width.isFinite)
        XCTAssertGreaterThan(result.titleFrame.width, 0)
    }

    func testNAV_TITLE_006_fullyOccupiedRegionHidesSafely() {
        let result = resolve(visibleRect: CGRect(x: 0, y: 0, width: 300, height: 44),
                             leftWidth: 180,
                             rightWidth: 180,
                             mode: .centerMeasured)

        XCTAssertFalse(result.shouldDisplay)
        XCTAssertGreaterThanOrEqual(result.titleFrame.width, 0)
    }

    func testNAV_TITLE_007_validBoundsSurviveMissingIntrinsicSize() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
        let size = PTNavigationTitleSizeResolver.resolve(view: view, availableHeight: 44)

        XCTAssertEqual(size.width, 120, accuracy: 0.01)
        XCTAssertEqual(size.height, 20, accuracy: 0.01)
    }

    func testNAV_TITLE_008_missingSizeReturnsDeterministicSafeResult() {
        let result = resolve(desiredSize: .zero, mode: .centerMeasured)

        XCTAssertFalse(result.shouldDisplay)
        XCTAssertEqual(result.titleFrame, .zero)
    }

    func testNAV_TITLE_009_modesKeepTheirKnownSemantics() {
        let fixed = resolve(desiredSize: CGSize(width: 240, height: 32), mode: .centerFixed(100))
        let measured = resolve(desiredSize: CGSize(width: 100, height: 32), mode: .centerMeasured)
        let fill = resolve(desiredSize: CGSize(width: 1, height: 32), mode: .fillAvailable)

        XCTAssertEqual(fixed.titleFrame.width, 100, accuracy: 0.01)
        XCTAssertEqual(measured.titleFrame.width, 100, accuracy: 0.01)
        XCTAssertEqual(fill.titleFrame.width, 358, accuracy: 0.01)
    }

    func testNAV_TITLE_010_selectedVisiblePaneBoundsResult() {
        let pane = CGRect(x: 80, y: 0, width: 240, height: 44)
        let result = resolve(visibleRect: pane,
                             leftWidth: 32,
                             rightWidth: 32,
                             mode: .centerMeasured)

        XCTAssertTrue(result.shouldDisplay)
        XCTAssertTrue(pane.contains(result.titleFrame))
        XCTAssertEqual(result.titleFrame.midX, pane.midX, accuracy: 0.01)
    }

    func testNAV_TITLE_011_physicalLeftAndRightRemainSymmetricForRTLInput() {
        let left = resolve(leftWidth: 56, rightWidth: 24, mode: .centerMeasured)
        let right = resolve(leftWidth: 24, rightWidth: 56, mode: .centerMeasured)

        XCTAssertTrue(left.shouldDisplay)
        XCTAssertTrue(right.shouldDisplay)
        XCTAssertEqual(left.titleFrame.midX, right.titleFrame.midX, accuracy: 0.01)
        XCTAssertEqual(left.titleFrame.width, right.titleFrame.width, accuracy: 0.01)
    }

    func testNAV_TITLE_012_geometrySignatureChangesOnlyWithGeometry() {
        let input = PTNavigationTitleLayoutResolver.makeInput(
            visibleRect: visibleRect,
            leftWidth: 20,
            rightWidth: 30,
            desiredTitleSize: CGSize(width: 100, height: 32),
            minimumEdgeInset: 16,
            itemSpacing: 8,
            mode: .centerMeasured
        )
        let sameInput = PTNavigationTitleLayoutResolver.makeInput(
            visibleRect: visibleRect,
            leftWidth: 20,
            rightWidth: 30,
            desiredTitleSize: CGSize(width: 100, height: 32),
            minimumEdgeInset: 16,
            itemSpacing: 8,
            mode: .centerMeasured
        )
        let changedInput = PTNavigationTitleLayoutResolver.makeInput(
            visibleRect: CGRect(x: 0, y: 0, width: 430, height: 44),
            leftWidth: 20,
            rightWidth: 30,
            desiredTitleSize: CGSize(width: 100, height: 32),
            minimumEdgeInset: 16,
            itemSpacing: 8,
            mode: .centerMeasured
        )

        XCTAssertEqual(input, sameInput)
        XCTAssertNotEqual(input, changedInput)
    }

    func testNAV_TITLE_013_invalidNumbersAreNormalized() {
        let result = resolve(leftWidth: .infinity,
                             rightWidth: -10,
                             desiredSize: CGSize(width: CGFloat.nan, height: CGFloat.infinity),
                             mode: .centerMeasured,
                             minimumEdgeInset: CGFloat.nan,
                             itemSpacing: -CGFloat.infinity)

        XCTAssertFalse(result.titleFrame.minX.isNaN)
        XCTAssertFalse(result.titleFrame.minY.isNaN)
        XCTAssertFalse(result.titleFrame.width.isNaN)
        XCTAssertFalse(result.titleFrame.height.isNaN)
        XCTAssertTrue(result.titleFrame.width.isFinite)
        XCTAssertTrue(result.titleFrame.height.isFinite)
    }

    func testNAV_TITLE_014_switchingModesProducesMutuallyExclusiveFrames() {
        let center = resolve(leftWidth: 40, rightWidth: 40, mode: .centerMeasured)
        let fill = resolve(leftWidth: 40, rightWidth: 40, mode: .fillAvailable)
        let fixed = resolve(leftWidth: 40, rightWidth: 40, mode: .centerFixed(80))

        XCTAssertTrue(center.shouldDisplay)
        XCTAssertTrue(fill.shouldDisplay)
        XCTAssertTrue(fixed.shouldDisplay)
        XCTAssertEqual(center.titleFrame.midX, visibleRect.midX, accuracy: 0.01)
        XCTAssertEqual(fixed.titleFrame.midX, visibleRect.midX, accuracy: 0.01)
        XCTAssertGreaterThan(fill.titleFrame.width, fixed.titleFrame.width)
    }

    // English: Title regressions preserve preferred sizes while Large Title transitions temporarily hide or compress views.
    // Español: Las regresiones de título conservan los tamaños preferidos mientras Large Title oculta o comprime vistas temporalmente.
    // 中文：大标题转场暂时隐藏或压缩视图时，标题回归仍保留首选尺寸。
    func testLargeTitleZeroHeightTransitionDoesNotPoisonDesiredTitleSize() {
        let title = UILabel()
        title.text = "Large title"
        title.frame = CGRect(x: 0, y: 0, width: 1, height: 0)

        let size = PTNavigationTitleSizeResolver.resolve(view: title, availableHeight: 44)
        XCTAssertGreaterThan(size.width, 1)
        XCTAssertGreaterThan(size.height, 1)
    }

    func testTitleRemainsRestorableWhileLargeTitleAlphaIsZero() {
        let container = PTNavigationBarContainer(frame: CGRect(x: 0, y: 0, width: 390, height: 44))
        let title = IntrinsicTitleView(preferredSize: CGSize(width: 120, height: 32))
        container.titleContainer.alpha = 0

        let layout = container.navigationTitleLayout(for: title,
                                                      mode: .centerMeasured,
                                                      visibleRect: CGRect(x: 0, y: 0, width: 390, height: 44))
        XCTAssertTrue(layout.result.shouldDisplay)
        XCTAssertEqual(layout.result.titleFrame.width, 120, accuracy: 0.01)
    }

    func testLongTitleTruncatesWithoutShrinkingLeftItem() {
        let result = resolve(leftWidth: 60,
                             rightWidth: 44,
                             desiredSize: CGSize(width: 800, height: 32),
                             mode: .centerMeasured)

        XCTAssertTrue(result.shouldDisplay)
        XCTAssertTrue(result.isWidthCompressed)
        XCTAssertGreaterThanOrEqual(result.titleFrame.minX, 84 - 0.01)
    }

    func testCachedCompressedBoundsDoNotOverrideOriginalPreferredSize() {
        let title = IntrinsicTitleView(preferredSize: CGSize(width: 140, height: 32))
        title.bounds = CGRect(x: 0, y: 0, width: 1, height: 1)

        let size = PTNavigationTitleSizeResolver.resolve(view: title, availableHeight: 44)
        XCTAssertEqual(size.width, 140, accuracy: 0.01)
        XCTAssertEqual(size.height, 32, accuracy: 0.01)
    }

    func testAsymmetricLeftRightButtonsPreserveCenteringAfterResize() {
        let portrait = resolve(visibleRect: CGRect(x: 0, y: 0, width: 390, height: 44),
                               leftWidth: 68,
                               rightWidth: 24,
                               desiredSize: CGSize(width: 300, height: 32),
                               mode: .centerMeasured)
        let wide = resolve(visibleRect: CGRect(x: 0, y: 0, width: 430, height: 44),
                           leftWidth: 68,
                           rightWidth: 24,
                           desiredSize: CGSize(width: 300, height: 32),
                           mode: .centerMeasured)

        XCTAssertTrue(portrait.shouldDisplay)
        XCTAssertTrue(wide.shouldDisplay)
        XCTAssertEqual(portrait.titleFrame.midX, 195, accuracy: 0.01)
        XCTAssertEqual(wide.titleFrame.midX, 215, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(portrait.titleFrame.minX, 92 - 0.01)
        XCTAssertGreaterThanOrEqual(wide.titleFrame.minX, 92 - 0.01)
    }
}
