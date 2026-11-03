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


    func testTextViewExpandedActionUsesTextContainerPaddingAndScrollOffset() {
        let font = UIFont.systemFont(ofSize: 20)
        let content = PTRichText(String(repeating: "上一个段落\n", count: 7),
                                 .font(font))
            + PTRichText("  ", .font(font))
            + PTRichText("喜欢",
                         .font(font),
                         .action(PTTextActionID("textView")),
                         .roundedBackground(color: .yellow,
                                            cornerRadius: 5,
                                            insets: .init(top: 2, left: 4, bottom: 2, right: 4),
                                            hitTestInsets: .init(top: 4, left: 6, bottom: 4, right: 6)))
            + PTRichText("  完成", .font(font))
        let view = PTRichTextStyledTextView(frame: CGRect(x: 0, y: 0, width: 240, height: 90))
        view.font = font
        view.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        view.pt_apply(richText: content, interactionMode: .actionsOnly)
        view.layoutIfNeeded()
        let segments = PTRichTextRoundedBackgroundRenderer.layoutSegments(
            in: view.attributedText, size: view.textContainer.size,
            font: view.font, alignment: view.textAlignment,
            numberOfLines: view.textContainer.maximumNumberOfLines,
            lineBreakMode: view.textContainer.lineBreakMode,
            lineFragmentPadding: view.textContainer.lineFragmentPadding)
        guard let target = segments.first else {
            return XCTFail("Missing TextView target geometry")
        }
        // Scroll the action near the center of the viewport and hit painted
        // padding rather than the glyph's original bounds.
        view.setContentOffset(CGPoint(x: 0, y: max(0, target.rect.midY - 35)), animated: false)
        let touch = CGPoint(x: view.textContainerInset.left - view.contentOffset.x + target.rect.minX - 2,
                            y: view.textContainerInset.top - view.contentOffset.y + target.rect.midY)
        XCTAssertTrue(view.bounds.contains(touch))
        let controller = PTRichTextInteractionController(richText: content,
                                                         textView: view,
                                                         interactionMode: .actionsOnly)
        XCTAssertEqual(controller.actionEvent(at: touch, interaction: .tap)?.actionID,
                       PTTextActionID("textView"))
        XCTAssertEqual(controller.actionEvent(at: touch, interaction: .longPress)?.text,
                       "喜欢")
    }

    func testExternalSpacingAddsRealKerningWithoutChangingTextOrActionRange() {
        let action = PTTextActionID("spaced")
        let richText = PTRichText("我很", .font(.systemFont(ofSize: 20)))
            + PTRichText("喜欢",
                         .font(.systemFont(ofSize: 20)),
                         .roundedBackground(color: .yellow,
                                            cornerRadius: 6,
                                            insets: .init(top: 2, left: 3, bottom: 2, right: 4),
                                            leadingSpacing: 8,
                                            trailingSpacing: 11),
                         .action(action))
            + PTRichText("你。", .font(.systemFont(ofSize: 20)))
        let source = richText.value
        let spaced = PTRichTextRoundedBackgroundRenderer.textWithExternalSpacing(source)
        let decorated = PTRichTextRoundedBackgroundRenderer.textForDecoratedHost(source)

        XCTAssertEqual(spaced.string, "我很喜欢你。")
        XCTAssertEqual(spaced.length, source.length)
        XCTAssertEqual((spaced.attribute(.kern, at: 1, effectiveRange: nil) as? NSNumber)?.doubleValue,
                       11, accuracy: 0.001)
        XCTAssertEqual((spaced.attribute(.kern, at: 3, effectiveRange: nil) as? NSNumber)?.doubleValue,
                       15, accuracy: 0.001)
        XCTAssertNil(spaced.attribute(.kern, at: 0, effectiveRange: nil))
        XCTAssertNil(source.attribute(.kern, at: 1, effectiveRange: nil))
        XCTAssertNil(source.attribute(.kern, at: 3, effectiveRange: nil))
        XCTAssertEqual(spaced.attribute(PTRichText.actionAttributeKey, at: 2, effectiveRange: nil) as? String,
                       action.rawValue)
        XCTAssertEqual(decorated.string, source.string)
        XCTAssertNil(decorated.attribute(.backgroundColor, at: 2, effectiveRange: nil))
    }

    func testExternalSpacingIsIdempotentAcrossUIKitFoundationBridges() {
        let value = PTRichText("前")
            + PTRichText("喜欢",
                         .roundedBackground(color: .yellow, leadingSpacing: 7, trailingSpacing: 9))
            + PTRichText("后")
        let once = PTRichTextRoundedBackgroundRenderer.textWithExternalSpacing(value.value)
        let twice = PTRichTextRoundedBackgroundRenderer.textWithExternalSpacing(once)
        XCTAssertEqual(once.string, twice.string)
        XCTAssertEqual(once.attribute(.kern, at: 0, effectiveRange: nil) as? NSNumber,
                       twice.attribute(.kern, at: 0, effectiveRange: nil) as? NSNumber)
        XCTAssertEqual(once.attribute(.kern, at: 2, effectiveRange: nil) as? NSNumber,
                       twice.attribute(.kern, at: 2, effectiveRange: nil) as? NSNumber)

        let restored = PTRichText(once).value
        let third = PTRichTextRoundedBackgroundRenderer.textWithExternalSpacing(restored)
        XCTAssertEqual(third.attribute(.kern, at: 0, effectiveRange: nil) as? NSNumber,
                       once.attribute(.kern, at: 0, effectiveRange: nil) as? NSNumber)
        XCTAssertEqual(third.attribute(.kern, at: 2, effectiveRange: nil) as? NSNumber,
                       once.attribute(.kern, at: 2, effectiveRange: nil) as? NSNumber)
    }

    func testSpacingCombinesWithExistingKernAndAdjacentDecoratedRuns() {
        let value = PTRichText("前", .kern(2))
            + PTRichText("甲", .roundedBackground(color: .yellow,
                                                leadingSpacing: 4,
                                                trailingSpacing: 7))
            + PTRichText("乙", .roundedBackground(color: .green,
                                                leadingSpacing: 6,
                                                trailingSpacing: 3))
            + PTRichText("后")
        let spaced = PTRichTextRoundedBackgroundRenderer.textWithExternalSpacing(value.value)
        XCTAssertEqual((spaced.attribute(.kern, at: 0, effectiveRange: nil) as? NSNumber)?.doubleValue,
                       6, accuracy: 0.001)
        // Boundary 甲 -> 乙 carries both 甲 trailing and 乙 leading distance.
        XCTAssertEqual((spaced.attribute(.kern, at: 1, effectiveRange: nil) as? NSNumber)?.doubleValue,
                       13, accuracy: 0.001)
        XCTAssertEqual((spaced.attribute(.kern, at: 2, effectiveRange: nil) as? NSNumber)?.doubleValue,
                       3, accuracy: 0.001)
    }

    func testSpacingIsNotInsertedAcrossHardLineBreaksOrAtParagraphEdges() {
        let value = PTRichText("首行\n")
            + PTRichText("喜欢",
                         .roundedBackground(color: .yellow,
                                            leadingSpacing: 7,
                                            trailingSpacing: 8))
            + PTRichText("\n下一行")
        let source = value.value
        let spaced = PTRichTextRoundedBackgroundRenderer.textWithExternalSpacing(source)
        XCTAssertEqual(spaced.string, source.string)
        let range = (source.string as NSString).range(of: "喜欢")
        XCTAssertNil(spaced.attribute(.kern, at: range.location - 1, effectiveRange: nil))
        XCTAssertNil(spaced.attribute(.kern, at: NSMaxRange(range) - 1, effectiveRange: nil))
    }

    func testExternalSpacingNormalizesInvalidNumbersAndDecodesPriorStyles() {
        let text = PTRichText("喜欢",
                              .roundedBackground(color: .yellow,
                                                 leadingSpacing: -.infinity,
                                                 trailingSpacing: .nan))
        let style = PTTextRoundedBackgroundSpec.decode(
            text.value.attribute(PTRichText.roundedBackgroundAttributeKey,
                                 at: 0, effectiveRange: nil))
        XCTAssertEqual(style?.leadingSpacing, 0)
        XCTAssertEqual(style?.trailingSpacing, 0)

        let prior = PTRichText("旧",
                               .roundedBackground(color: .yellow))
        guard let data = prior.value.attribute(PTRichText.roundedBackgroundAttributeKey,
                                               at: 0,
                                               effectiveRange: nil) as? Data,
              var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return XCTFail("Expected Codable rounded-background style")
        }
        object.removeValue(forKey: "leadingSpacing")
        object.removeValue(forKey: "trailingSpacing")
        guard let legacyData = try? JSONSerialization.data(withJSONObject: object),
              let legacy = PTTextRoundedBackgroundSpec.decode(legacyData) else {
            return XCTFail("Previous rounded style must remain decodable")
        }
        XCTAssertNil(legacy.leadingSpacing)
        XCTAssertNil(legacy.trailingSpacing)
    }

    func testFlowLayoutUsesSpacingButPreservesSourceMapping() {
        let base = PTRichText("前", .font(.systemFont(ofSize: 20)))
            + PTRichText("喜欢",
                         .font(.systemFont(ofSize: 20)),
                         .roundedBackground(color: .yellow,
                                            leadingSpacing: 5,
                                            trailingSpacing: 8),
                         .numberOfLines(0),
                         .action(PTTextActionID("flowSpaced")))
            + PTRichText("后", .font(.systemFont(ofSize: 20)))
        let result = PTRichTextFlowLayoutEngine.layout(base, width: 160)
        XCTAssertEqual(result.renderedText.string, base.plainText)
        XCTAssertEqual(result.sourceMap.count, result.renderedText.length)
        let substring = (result.renderedText.string as NSString).range(of: "喜欢")
        XCTAssertEqual(result.sourceRange(for: substring),
                       (base.plainText as NSString).range(of: "喜欢"))
        XCTAssertEqual((result.renderedText.attribute(.kern, at: 0, effectiveRange: nil) as? NSNumber)?.doubleValue,
                       5, accuracy: 0.001)
        XCTAssertEqual((result.renderedText.attribute(.kern, at: 2, effectiveRange: nil) as? NSNumber)?.doubleValue,
                       8, accuracy: 0.001)
    }

    func testEmojiPrecedingStyledTextRemainsComposedCharacter() {
        let value = PTRichText("👨‍👩‍👧‍👦")
            + PTRichText("喜欢",
                         .roundedBackground(color: .yellow,
                                            leadingSpacing: 7))
            + PTRichText("你")
        let spaced = PTRichTextRoundedBackgroundRenderer.textWithExternalSpacing(value.value)
        let emoji = (spaced.string as NSString).rangeOfComposedCharacterSequence(at: 0)
        XCTAssertEqual(emoji.length, (value.plainText as NSString).range(of: "喜欢").location)
        XCTAssertEqual((spaced.attribute(.kern,
                                        at: emoji.location,
                                        effectiveRange: nil) as? NSNumber)?.doubleValue,
                       7, accuracy: 0.001)
        XCTAssertEqual(spaced.string, value.plainText)
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
