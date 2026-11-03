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
}
