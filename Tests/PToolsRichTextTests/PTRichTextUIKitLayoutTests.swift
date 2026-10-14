import Foundation
import UIKit
import XCTest
@testable import PToolsUIFoundation

// English: Exercise real UILabel layout instead of checking only attributed-string metadata.
// Español: Comprueba el layout real de UILabel en lugar de validar solo metadatos del texto.
// 中文：使用真实 UILabel 布局验证，而不是只检查富文本元数据。
@MainActor
final class PTRichTextUIKitLayoutTests: XCTestCase {
    func testInlineAttachmentWrapsAtRealLabelSize() {
        withLabel(width: 366, height: 120) { label in
            let value = makeRichText(offset: -7)
            PTRichTextRenderer.apply(value, to: label)

            XCTAssertEqual(label.bounds.size, CGSize(width: 366, height: 120))
            XCTAssertGreaterThanOrEqual(lineCount(for: label), 2)
            XCTAssertGreaterThan(label.sizeThatFits(label.bounds.size).height, 24)
        }
    }

    func testAttachmentBaselineIsNormalizedOnlyForDisplayedCopy() {
        let value = makeRichText(offset: -7)
        let model = value.value
        let modelOffset = model.attribute(.baselineOffset, at: 0, effectiveRange: nil) as? NSNumber
        XCTAssertEqual(modelOffset?.doubleValue, -7, accuracy: 0.001)

        let prepared = PTRichTextLabelRendering.prepare(model)
        XCTAssertNil(prepared.attribute(.baselineOffset, at: 0, effectiveRange: nil))
        guard let attachment = prepared.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment else {
            return XCTFail("Expected prepared image attachment")
        }
        XCTAssertEqual(attachment.bounds.origin.y, -7, accuracy: 0.001)
    }

    func testZeroAndPositiveBaselineKeepTheirOwnVisualOffset() {
        for offset in [-7 as CGFloat, 0, 7] {
            let value = makeRichText(offset: offset).value
            let prepared = PTRichTextLabelRendering.prepare(value)
            guard let attachment = prepared.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment else {
                return XCTFail("Expected prepared image attachment")
            }
            XCTAssertEqual(attachment.bounds.origin.y, offset, accuracy: 0.001)
            XCTAssertNil(prepared.attribute(.baselineOffset, at: 0, effectiveRange: nil))
        }
    }

    func testCallerLineCountAndBreakModeAreNotChanged() {
        withLabel(width: 280, height: 64) { label in
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            PTRichTextRenderer.apply(makeRichText(offset: -7), to: label)
            XCTAssertEqual(label.numberOfLines, 1)
            XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)

            label.numberOfLines = 2
            label.lineBreakMode = .byCharWrapping
            PTRichTextRenderer.apply(makeRichText(offset: 7), to: label)
            XCTAssertEqual(label.numberOfLines, 2)
            XCTAssertEqual(label.lineBreakMode, .byCharWrapping)
        }
    }

    func testRendererIsIdempotentAndKeepsActionRange() {
        let value = makeRichText(offset: -7, includesAction: true)
        let first = PTRichTextLabelRendering.prepare(value.value)
        let second = PTRichTextLabelRendering.prepare(first)
        XCTAssertEqual(first.string, second.string)
        XCTAssertEqual(first.length, second.length)
        XCTAssertEqual(first.attribute(PTRichText.actionAttributeKey,
                                       at: first.length - 1,
                                       effectiveRange: nil) as? String,
                       "rule")
        let firstAttachment = first.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment
        let secondAttachment = second.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment
        XCTAssertEqual(firstAttachment?.bounds, secondAttachment?.bounds)
    }

    func testActionOnWrappedLineUsesDisplayedLayout() {
        withLabel(width: 280, height: 120) { label in
            let value = makeRichText(offset: -7, includesAction: true)
            let registry = PTTextActionRegistry()
            PTRichTextRenderer.apply(value,
                                     to: label,
                                     actionRegistry: registry,
                                     interactionMode: .actionsOnly)
            guard let displayed = label.attributedText else {
                return XCTFail("Expected displayed attributed text")
            }
            let actionText = "点击规则"
            let actionRange = displayed.string.nsRange(of: actionText)
            XCTAssertNotEqual(actionRange.location, NSNotFound)
            guard actionRange.location != NSNotFound else { return }

            let textRect = label.textRect(forBounds: label.bounds,
                                          limitedToNumberOfLines: label.numberOfLines)
            let storage = NSTextStorage(attributedString: displayed)
            let layout = NSLayoutManager()
            let container = NSTextContainer(size: textRect.size)
            container.lineFragmentPadding = 0
            container.maximumNumberOfLines = label.numberOfLines
            container.lineBreakMode = label.lineBreakMode
            layout.addTextContainer(container)
            storage.addLayoutManager(layout)
            layout.ensureLayout(for: container)
            let glyphRange = layout.glyphRange(forCharacterRange: actionRange, actualCharacterRange: nil)
            let actionRect = layout.boundingRect(forGlyphRange: glyphRange, in: container)
            let point = CGPoint(x: textRect.minX + actionRect.midX,
                                y: textRect.minY + actionRect.midY)
            let controller = PTRichTextInteractionController(richText: value,
                                                              label: label,
                                                              registry: registry,
                                                              interactionMode: .actionsOnly)
            XCTAssertEqual(controller.actionEvent(at: point, interaction: .tap)?.actionID,
                           PTTextActionID("rule"))
        }
    }

    func testRemoteReplacementKeepsAttachmentContract() {
        let url = URL(string: "https://example.com/image.png")!
        let value = PTRichText.image(url,
                                     .custom(size: CGSize(width: 24, height: 24)),
                                     baselineOffset: -7)
        let remote = value.value.attribute(.attachment, at: 0, effectiveRange: nil) as? PTRemoteImageTextAttachment
        XCTAssertNotNil(remote)
        let replacement = remote?.resolvedAttachment(with: makeImage(size: CGSize(width: 24, height: 24)))
        let updated = NSMutableAttributedString(attributedString: value.value)
        if let replacement {
            updated.addAttribute(.attachment, value: replacement, range: NSRange(location: 0, length: 1))
        }
        let prepared = PTRichTextLabelRendering.prepare(updated)
        let resolved = prepared.attribute(.attachment, at: 0, effectiveRange: nil) as? PTRemoteImageTextAttachment
        XCTAssertEqual(resolved?.mediaID, remote?.mediaID)
        XCTAssertEqual(resolved?.bounds.origin.y, -7, accuracy: 0.001)
        XCTAssertNil(prepared.attribute(.baselineOffset, at: 0, effectiveRange: nil))
    }

    private func makeRichText(offset: CGFloat, includesAction: Bool = false) -> PTRichText {
        let image = PTTextAttribute.image(makeImage(),
                                          .custom(size: CGSize(width: 24, height: 24)),
                                          baselineOffset: offset)
        var value = PTRichText(string: "\u{FFFC}", with: [image])
        value += PTRichText(" 标题与描述 mixed text that is intentionally long enough to wrap ",
                            with: [.font(.systemFont(ofSize: 14, weight: .bold))])
        if includesAction {
            value += PTRichText("点击规则", with: [.action(PTTextActionID("rule")),
                                                   .foreground(.systemBlue),
                                                   .font(.systemFont(ofSize: 14))])
        } else {
            value += PTRichText("普通文本", with: [.font(.systemFont(ofSize: 14))])
        }
        return PTRichText(wrap: .embedding(value),
                          .paragraph(.lineBreakMode(.byWordWrapping)))
    }

    private func makeImage(size: CGSize = CGSize(width: 24, height: 24)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func withLabel(width: CGFloat,
                           height: CGFloat,
                           _ body: (UILabel) -> Void) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let controller = UIViewController()
        window.rootViewController = controller
        window.isHidden = false
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: height))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        controller.view.addSubview(label)
        controller.view.layoutIfNeeded()
        body(label)
        window.isHidden = true
    }

    private func lineCount(for label: UILabel) -> Int {
        guard let attributedText = label.attributedText, attributedText.length > 0 else { return 0 }
        let textRect = label.textRect(forBounds: label.bounds,
                                      limitedToNumberOfLines: label.numberOfLines)
        let storage = NSTextStorage(attributedString: attributedText)
        let layout = NSLayoutManager()
        let container = NSTextContainer(size: textRect.size)
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = label.numberOfLines
        container.lineBreakMode = label.lineBreakMode
        layout.addTextContainer(container)
        storage.addLayoutManager(layout)
        layout.ensureLayout(for: container)
        var ranges = Set<String>()
        for glyph in 0..<layout.numberOfGlyphs {
            var range = NSRange(location: 0, length: 0)
            _ = layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: &range)
            ranges.insert("\(range.location):\(range.length)")
        }
        return ranges.count
    }
}

private extension String {
    func nsRange(of substring: String) -> NSRange {
        (self as NSString).range(of: substring)
    }
}
