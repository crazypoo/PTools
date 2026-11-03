import Foundation
import UIKit
import XCTest
@testable import PToolsUIFoundation

// Rounded-background metadata, UIKit host fallbacks and line-fragment geometry.
@MainActor
final class PTRichTextRoundedBackgroundTests: XCTestCase {
    private func styledWord() -> PTRichText {
        PTRichText("喜欢",
                   .font(.systemFont(ofSize: 20)),
                   .roundedBackground(color: .systemYellow,
                                      cornerRadius: 6,
                                      insets: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4),
                                      borderColor: .orange,
                                      borderWidth: 1))
    }

    func testStyleSurvivesFoundationUIKitBridgingAndConcatenation() {
        let value = PTRichText("我很") + styledWord() + PTRichText("你。")
        XCTAssertEqual(value.plainText, "我很喜欢你。")

        let range = (value.plainText as NSString).range(of: "喜欢")
        let first = value.value
        let style = PTTextRoundedBackgroundSpec.decode(
            first.attribute(PTRichText.roundedBackgroundAttributeKey,
                            at: range.location,
                            effectiveRange: nil))
        XCTAssertNotNil(style)
        XCTAssertEqual(style?.radius, 6)
        XCTAssertEqual(style?.left, 4)
        XCTAssertEqual(style?.strokeWidth, 1)
        XCTAssertNotNil(first.attribute(.backgroundColor, at: range.location, effectiveRange: nil))

        let second = PTRichText(first).value
        let reconstructed = PTTextRoundedBackgroundSpec.decode(
            second.attribute(PTRichText.roundedBackgroundAttributeKey,
                             at: range.location,
                             effectiveRange: nil))
        XCTAssertEqual(style, reconstructed)
    }

    func testRangeMutationsKeepRoundedStyleOnOnlySelectedCharacters() {
        var value = PTRichText("我很喜欢你。")
        let range = (value.plainText as NSString).range(of: "喜欢")
        value.mergeAttributes([.roundedBackground(color: .green, cornerRadius: 4)],
                              in: range)
        let attrs = value.value
        XCTAssertNil(attrs.attribute(PTRichText.roundedBackgroundAttributeKey,
                                     at: 0,
                                     effectiveRange: nil))
        XCTAssertNotNil(attrs.attribute(PTRichText.roundedBackgroundAttributeKey,
                                        at: range.location,
                                        effectiveRange: nil))
        XCTAssertNil(attrs.attribute(PTRichText.roundedBackgroundAttributeKey,
                                     at: range.location + range.length,
                                     effectiveRange: nil))
    }

    func testStyledLabelUsesRoundedBackgroundWithoutRectangularDoublePaint() {
        let value = PTRichText("我很") + styledWord() + PTRichText("你。")
        let range = (value.plainText as NSString).range(of: "喜欢")

        let regular = UILabel()
        regular.pt_apply(richText: value)
        XCTAssertNotNil(regular.attributedText?.attribute(.backgroundColor,
                                                           at: range.location,
                                                           effectiveRange: nil))

        let styled = PTRichTextStyledLabel()
        styled.pt_apply(richText: value)
        XCTAssertNil(styled.attributedText?.attribute(.backgroundColor,
                                                      at: range.location,
                                                      effectiveRange: nil))
        XCTAssertNotNil(styled.attributedText?.attribute(PTRichText.roundedBackgroundAttributeKey,
                                                         at: range.location,
                                                         effectiveRange: nil))

        // Re-applying is idempotent and a plain value remains unchanged.
        styled.pt_apply(richText: value)
        XCTAssertNil(styled.attributedText?.attribute(.backgroundColor,
                                                      at: range.location,
                                                      effectiveRange: nil))
        XCTAssertNotNil(value.value.attribute(.backgroundColor,
                                             at: range.location,
                                             effectiveRange: nil))
    }

    func testStyledTextViewAndFlowLabelReceiveDecorationInsteadOfSquareFill() {
        let value = styledWord()
        let view = PTRichTextStyledTextView()
        view.pt_apply(richText: value)
        XCTAssertNil(view.attributedText.attribute(.backgroundColor, at: 0, effectiveRange: nil))

        let flow = PTRichTextFlowLabel(frame: CGRect(x: 0, y: 0, width: 140, height: 60))
        flow.pt_apply(richText: value)
        XCTAssertNil(flow.attributedText?.attribute(.backgroundColor, at: 0, effectiveRange: nil))
        XCTAssertNotNil(flow.attributedText?.attribute(PTRichText.roundedBackgroundAttributeKey,
                                                       at: 0,
                                                       effectiveRange: nil))
    }

    func testWrappedStyleCreatesIndependentRoundedSegments() {
        let content = PTRichText("一二三四五六七八九十",
                                 .font(.systemFont(ofSize: 20)),
                                 .roundedBackground(color: .yellow,
                                                    cornerRadius: 5))
        let rendered = PTRichTextRoundedBackgroundRenderer.textForDecoratedHost(content.value)
        let segments = PTRichTextRoundedBackgroundRenderer.layoutSegments(
            in: rendered,
            size: CGSize(width: 65, height: 240),
            font: .systemFont(ofSize: 20),
            alignment: .left,
            numberOfLines: 0,
            lineBreakMode: .byCharWrapping)

        XCTAssertGreaterThan(segments.count, 1)
        XCTAssertTrue(segments.allSatisfy { $0.rect.width > 0 && $0.rect.width <= 65 })
        XCTAssertGreaterThan(Set(segments.map { Int($0.rect.minY) }).count, 1)
    }

    func testSingleLineTruncationDoesNotPaintOtherLines() {
        let content = PTRichText("一二三四五六七八九十",
                                 .font(.systemFont(ofSize: 20)),
                                 .roundedBackground(color: .yellow, cornerRadius: 5))
        let segments = PTRichTextRoundedBackgroundRenderer.layoutSegments(
            in: content.value,
            size: CGSize(width: 65, height: 50),
            font: .systemFont(ofSize: 20),
            alignment: .left,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail)
        XCTAssertLessThanOrEqual(segments.count, 2)
        XCTAssertTrue(segments.allSatisfy { $0.rect.minY < 50 })
    }

    func testInvalidInsetsAndBorderWidthNormalizeToNonnegativeValues() {
        let value = PTRichText("文字",
                               .roundedBackground(color: .yellow,
                                                  cornerRadius: -.infinity,
                                                  insets: UIEdgeInsets(top: -2, left: .nan, bottom: 2, right: -1),
                                                  borderWidth: -.infinity))
        let style = PTTextRoundedBackgroundSpec.decode(
            value.value.attribute(PTRichText.roundedBackgroundAttributeKey,
                                  at: 0,
                                  effectiveRange: nil))
        XCTAssertEqual(style?.radius, 0)
        XCTAssertEqual(style?.top, 0)
        XCTAssertEqual(style?.left, 0)
        XCTAssertEqual(style?.bottom, 2)
        XCTAssertEqual(style?.right, 0)
        XCTAssertEqual(style?.strokeWidth, 0)
    }

    func testExtraHitInsetsSurviveBridgeAndNormalize() {
        let value = PTRichText("喜欢",
                               .roundedBackground(color: .yellow,
                                                  hitTestInsets: UIEdgeInsets(top: 9, left: 12,
                                                                              bottom: -4, right: .infinity)))
        let original = PTTextRoundedBackgroundSpec.decode(
            value.value.attribute(PTRichText.roundedBackgroundAttributeKey,
                                  at: 0, effectiveRange: nil))
        XCTAssertEqual(original?.hitTop, 9)
        XCTAssertEqual(original?.hitLeft, 12)
        XCTAssertEqual(original?.hitBottom, 0)
        XCTAssertEqual(original?.hitRight, 0)
        let restored = PTRichText(value.value)
        let roundTrip = PTTextRoundedBackgroundSpec.decode(
            restored.value.attribute(PTRichText.roundedBackgroundAttributeKey,
                                     at: 0, effectiveRange: nil))
        XCTAssertEqual(roundTrip?.hitInsets.left, 12)
        XCTAssertEqual(original, roundTrip)
    }

    func testPaintedPaddingAndExtraHitAreaTriggerExistingActionRange() {
        let action = PTTextActionID("like")
        let content = PTRichText("前  ", .font(.systemFont(ofSize: 20)))
            + PTRichText("喜欢",
                         .font(.systemFont(ofSize: 20)),
                         .action(action),
                         .roundedBackground(color: .systemYellow,
                                            cornerRadius: 6,
                                            insets: .init(top: 2, left: 5, bottom: 2, right: 5),
                                            hitTestInsets: .init(top: 5, left: 7, bottom: 5, right: 7)))
            + PTRichText("  后", .font(.systemFont(ofSize: 20)))
        let label = PTRichTextStyledLabel(frame: CGRect(x: 0, y: 0, width: 240, height: 55))
        label.font = .systemFont(ofSize: 20)
        label.pt_apply(richText: content)
        guard let segment = segments(in: label).first else {
            return XCTFail("Missing rounded background geometry")
        }
        let rect = label.textRect(forBounds: label.bounds,
                                  limitedToNumberOfLines: label.numberOfLines)
        let point = CGPoint(x: rect.minX + segment.rect.minX - 3,
                            y: rect.minY + segment.rect.midY)

        let registry = PTTextActionRegistry()
        let controller = PTRichTextInteractionController(richText: content,
                                                         label: label,
                                                         registry: registry,
                                                         interactionMode: .actionsOnly)
        let tapped = controller.actionEvent(at: point, interaction: .tap)
        XCTAssertEqual(tapped?.actionID, action)
        XCTAssertEqual(tapped?.text, "喜欢")
        XCTAssertEqual(tapped?.range, (content.plainText as NSString).range(of: "喜欢"))
        XCTAssertEqual(controller.actionEvent(at: point, interaction: .longPress)?.actionID, action)
        XCTAssertNotNil(PTRichTextRoundedBackgroundRenderer.actionIndex(at: point, on: label))
    }

    func testExpandedAreaDoesNotStealRealNeighborGlyph() {
        let content = PTRichText("前",
                                 .font(.systemFont(ofSize: 20)))
            + PTRichText("喜欢",
                         .font(.systemFont(ofSize: 20)),
                         .action(PTTextActionID("like")),
                         .roundedBackground(color: .yellow,
                                            insets: .init(top: 0, left: 8, bottom: 0, right: 8),
                                            hitTestInsets: .init(top: 0, left: 12, bottom: 0, right: 12)))
            + PTRichText("后", .font(.systemFont(ofSize: 20)))
        let label = PTRichTextStyledLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 55))
        label.font = .systemFont(ofSize: 20)
        label.pt_apply(richText: content)
        let controller = PTRichTextInteractionController(richText: content,
                                                         label: label,
                                                         interactionMode: .actionsOnly)
        let rect = label.textRect(forBounds: label.bounds,
                                  limitedToNumberOfLines: label.numberOfLines)
        // First CJK glyph is inside the extended target, but it isn't an Action.
        let neighbor = CGPoint(x: rect.minX + 10, y: rect.midY)
        XCTAssertNil(PTRichTextRoundedBackgroundRenderer.actionIndex(at: neighbor, on: label))
        XCTAssertNil(controller.actionEvent(at: neighbor, interaction: .tap))
    }

    func testNoActionNeverBecomesClickableFromBackgroundAlone() {
        let text = PTRichText("喜欢",
                              .roundedBackground(color: .yellow,
                                                 hitTestInsets: .init(top: 10, left: 10,
                                                                      bottom: 10, right: 10)))
        let label = PTRichTextStyledLabel(frame: CGRect(x: 0, y: 0, width: 150, height: 55))
        label.pt_apply(richText: text)
        let controller = PTRichTextInteractionController(richText: text,
                                                         label: label,
                                                         interactionMode: .actionsOnly)
        let rect = label.textRect(forBounds: label.bounds, limitedToNumberOfLines: 1)
        let point = CGPoint(x: rect.minX + 2, y: rect.midY)
        XCTAssertNil(controller.actionEvent(at: point, interaction: .tap))
        XCTAssertNil(PTRichTextRoundedBackgroundRenderer.actionIndex(at: point, on: label))
    }

    func testFlowLabelActionHitMapsBackToOriginalSourceWithAndWithoutFragments() {
        for useFragment in [false, true] {
            let word = PTRichText("喜欢",
                                  .font(.systemFont(ofSize: 20)),
                                  .roundedBackground(color: .yellow,
                                                     hitTestInsets: .init(top: 4, left: 6,
                                                                          bottom: 4, right: 6)),
                                  .action(PTTextActionID("flow")))
            let middle = useFragment
                ? PTRichText(word, .numberOfLines(0))
                : word
            let content = PTRichText("前  ", .font(.systemFont(ofSize: 20)))
                + middle
                + PTRichText("  后", .font(.systemFont(ofSize: 20)))
            let label = PTRichTextFlowLabel(frame: CGRect(x: 0, y: 0, width: 240, height: 60))
            label.font = .systemFont(ofSize: 20)
            label.pt_apply(richText: content,
                           actionRegistry: PTTextActionRegistry(),
                           interactionMode: .actionsOnly)
            guard let segment = segments(in: label).first else {
                XCTFail("Missing flow segment"); continue
            }
            let rect = label.textRect(forBounds: label.bounds,
                                      limitedToNumberOfLines: label.numberOfLines)
            let touch = CGPoint(x: rect.minX + segment.rect.minX - 3,
                                y: rect.minY + segment.rect.midY)
            let hit = label.flowHit(at: touch)
            XCTAssertEqual(hit?.id, PTTextActionID("flow"))
            XCTAssertEqual(hit?.sourceRange, (content.plainText as NSString).range(of: "喜欢"))
            XCTAssertEqual(hit?.text, "喜欢")
        }
    }

    private func segments(in label: UILabel) -> [PTTextRoundedBackgroundSegment] {
        guard let text = label.attributedText else { return [] }
        let rect = label.textRect(forBounds: label.bounds,
                                  limitedToNumberOfLines: label.numberOfLines)
        return PTRichTextRoundedBackgroundRenderer.layoutSegments(
            in: text, size: rect.size, font: label.font,
            alignment: label.textAlignment, numberOfLines: label.numberOfLines,
            lineBreakMode: label.lineBreakMode)
    }

}
