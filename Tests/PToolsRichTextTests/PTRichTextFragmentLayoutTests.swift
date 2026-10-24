import Foundation
import UIKit
import XCTest
@testable import PToolsUIFoundation

// English: Verify fragment metadata, UTF-16 editing boundaries, and the opt-in flow renderer.
// Español: Verifica metadatos de fragmentos, límites de edición UTF-16 y el renderer Flow opt-in.
// 中文：验证片段元数据、UTF-16 编辑边界和显式启用的 Flow 渲染器。
@MainActor
final class PTRichTextFragmentLayoutTests: XCTestCase {
    func testFragmentAttributesNormalizeAndRoundTripThroughUIKit() {
        let value = PTRichText(string: "fragment",
                               with: [.numberOfLines(-1),
                                      .fragmentLineBreakMode(.byTruncatingTail),
                                      .keepWithNextAttachment()])

        XCTAssertEqual(value.textFragmentRuns.count, 1)
        XCTAssertEqual(value.textFragmentRuns.first?.range,
                       NSRange(location: 0, length: value.value.length))
        XCTAssertEqual(value.textFragmentRuns.first?.layout.maxLines, 0)
        XCTAssertEqual(value.textFragmentRuns.first?.layout.lineBreakMode, .byTruncatingTail)
        XCTAssertTrue(value.textFragmentRuns.first?.layout.keepWithNextAttachment == true)

        let restored = PTRichText(value.value)
        XCTAssertEqual(restored.textFragmentRuns, value.textFragmentRuns)
    }

    func testFragmentRunsFollowConcatenationInsertionReplacementAndRemoval() {
        var value = PTRichText(string: "abcd", with: [.numberOfLines(1)])
        value += PTRichText(string: "ef", with: [.numberOfLines(2)])

        XCTAssertEqual(value.textFragmentRuns.map(\.range), [NSRange(location: 0, length: 4),
                                                               NSRange(location: 4, length: 2)])

        guard let insertionIndex = value.attributedRange(from: NSRange(location: 2, length: 0))?.lowerBound,
              let replacementRange = value.attributedRange(from: NSRange(location: 1, length: 2)) else {
            return XCTFail("Expected valid UTF-16 editing ranges")
        }
        value.insert(PTRichText(string: "X", with: [.numberOfLines(3)]), at: insertionIndex)
        XCTAssertEqual(value.textFragmentRuns.map(\.range), [NSRange(location: 0, length: 2),
                                                               NSRange(location: 2, length: 1),
                                                               NSRange(location: 3, length: 2),
                                                               NSRange(location: 5, length: 2)])

        let shiftedReplacementRange = value.attributedRange(from: NSRange(location: 1, length: 2)) ?? replacementRange
        value.replaceSubrange(shiftedReplacementRange, with: PTRichText("Y"))
        guard let removalRange = value.attributedRange(from: NSRange(location: 0, length: 1)) else {
            return XCTFail("应能找到待删除的片段范围")
        }
        value.removeSubrange(removalRange)
        XCTAssertTrue(value.textFragmentRuns.allSatisfy { NSMaxRange($0.range) <= value.value.length })
    }

    func testOnlyTheOrderFragmentIsLimitedAndFollowingAttachmentAndDateRemain() {
        let date = "\nCreated 2026-10-24 12:34"
        for maxLines in [0, 1, 2, 3] {
            let richText = makeOrderText(maxLines: maxLines, mode: .byTruncatingTail)
            let result = PTRichTextFlowLayoutEngine.layout(richText, width: 96)

            XCTAssertTrue(result.renderedText.string.contains("Created"))
            XCTAssertEqual(countAttachments(in: result.renderedText), 1)
            if maxLines > 0 {
                XCTAssertFalse(result.truncatedFragmentRanges.isEmpty)
            } else {
                XCTAssertTrue(result.truncatedFragmentRanges.isEmpty)
            }
            XCTAssertEqual(richText.plainText.hasSuffix(date), true)
        }
    }

    func testAllFragmentLineBreakModesProduceAStableSourceMap() {
        let modes: [NSLineBreakMode] = [.byWordWrapping,
                                         .byCharWrapping,
                                         .byClipping,
                                         .byTruncatingHead,
                                         .byTruncatingTail,
                                         .byTruncatingMiddle]
        for mode in modes {
            let richText = makeOrderText(maxLines: 1, mode: mode)
            let result = PTRichTextFlowLayoutEngine.layout(richText, width: 120)
            XCTAssertGreaterThan(result.renderedText.length, 0)
            XCTAssertEqual(result.sourceMap.count, result.renderedText.length)
            XCTAssertNotNil(result.sourceRange(for: NSRange(location: 0, length: 1)))
        }
    }

    func testFlowLabelUsesSharedRenderedLayoutWithoutChangingHostConfiguration() {
        let label = PTRichTextFlowLabel(frame: CGRect(x: 0, y: 0, width: 120, height: 100))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let richText = makeOrderText(maxLines: 1, mode: .byTruncatingTail)
        PTRichTextRenderer.apply(richText, to: label)

        XCTAssertEqual(label.numberOfLines, 0)
        XCTAssertEqual(label.lineBreakMode, .byWordWrapping)
        XCTAssertEqual(label.richText, richText)
        XCTAssertEqual(label.flowLayoutResult?.renderedText.string.contains("Created"), true)
    }

    private func makeOrderText(maxLines: Int,
                               mode: NSLineBreakMode) -> PTRichText {
        let order = PTRichText(string: "Order 20261024-PT-000000000000-Fragment-Test",
                               with: [.action(PTTextActionID("order")),
                                      .numberOfLines(maxLines),
                                      .fragmentLineBreakMode(mode),
                                      .keepWithNextAttachment()])
        let image = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        }
        let attachment = PTRichText(string: "\u{FFFC}",
                                    with: [.image(image, .custom(size: CGSize(width: 16, height: 16)))])
        return order + " " + attachment + "\nCreated 2026-10-24 12:34"
    }

    private func countAttachments(in value: NSAttributedString) -> Int {
        var count = 0
        value.enumerateAttribute(.attachment,
                                  in: NSRange(location: 0, length: value.length),
                                  options: []) { attachment, _, _ in
            if attachment != nil { count += 1 }
        }
        return count
    }
}
