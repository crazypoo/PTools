import Foundation
import UIKit
import XCTest
@testable import PToolsUIFoundation

// English: Cover the Foundation-backed rich-text contract without depending on a third-party package.
// Español: Cubre el contrato de texto enriquecido basado en Foundation sin depender de un paquete externo.
// 中文：覆盖基于 Foundation 的富文本契约，不依赖第三方包。
final class PTRichTextCoreTests: XCTestCase {
    func testInterpolationAndUIKitBridge() {
        let word = "PTools"
        let value: PTRichText = "Hello \(word, PTTextAttribute.foreground(.systemBlue))"

        XCTAssertEqual(value.plainText, "Hello PTools")
        XCTAssertEqual(value.value.string, "Hello PTools")
        XCTAssertGreaterThan(value.value.length, value.plainText.count)
    }

    func testUnicodeRangeRejectsGraphemeSplits() {
        let family = "👨‍👩‍👧‍👦"
        let value = PTRichText(family + "中文")
        let familyLength = family.utf16.count

        XCTAssertEqual(value.validatedNSRange(NSRange(location: 0, length: familyLength)),
                       NSRange(location: 0, length: familyLength))
        XCTAssertNil(value.validatedNSRange(NSRange(location: 0, length: 1)))
        XCTAssertNil(value.validatedNSRange(NSRange(location: -1, length: 1)))
    }

    func testRegexMatchesAndReplacementUseStableRanges() {
        var value = PTRichText("A-1 A-2")
        let rule = PTTextMatchRule.regex(pattern: "A-[0-9]")

        XCTAssertEqual(value.matches(for: rule).map(\.text), ["A-1", "A-2"])

        value.replaceMatches(of: rule) { _ in PTRichText("X") }

        XCTAssertEqual(value.plainText, "X X")
    }

    func testMergeAndConcatenationKeepValueSemantics() {
        var value = PTRichText("first") + " second"
        value += PTRichText(" third")

        let range = value.range(of: "second")
        XCTAssertNotNil(range)
        if let range {
            value.mergeAttributes([.foreground(.systemRed)], in: range)
        }

        XCTAssertEqual(value.plainText, "first second third")
        XCTAssertEqual(value, PTRichText(value.value))
    }

    func testMarkdownInitialization() throws {
        let value = try PTRichText(markdown: "**PTools**")

        XCTAssertEqual(value.plainText, "PTools")
        XCTAssertFalse(value.isEmpty)
    }

    func testResultBuilderAndFragment() {
        let value = PTRichText {
            "Hello "
            PTTextFragment(PTRichText("PTools"))
            "!"
        }

        XCTAssertEqual(value.plainText, "Hello PTools!")
    }

    func testInvalidAttachmentSizeFallsBackToFiniteBounds() {
        let descriptor = PTTextAttachmentDescriptor(kind: .remote(URL(string: "https://example.com/image")!),
                                                     size: CGSize(width: .nan, height: .infinity))

        XCTAssertEqual(descriptor.size, CGSize(width: 1, height: 1))
    }

    // English: Keep image and video media sources on stable placeholder attachments before async loading.
    // Español: Mantiene las fuentes de imagen y vídeo en adjuntos de marcador estables antes de la carga asíncrona.
    // 中文：验证异步加载前图片和视频来源都保存在稳定的占位附件中。
    @MainActor
    func testRichMediaSourcesCreateStablePlaceholders() {
        let imageText = PTRichText.image(source: URL(string: "https://example.com/image.png")!,
                                         configuration: .init(estimatedAspectRatio: 1))
        let videoText = PTRichText.video(source: URL(fileURLWithPath: "/tmp/example.mp4"),
                                         configuration: .init(estimatedAspectRatio: 16.0 / 9.0))

        let imageAttachment = imageText.value.attribute(.attachment,
                                                         at: 0,
                                                         effectiveRange: nil) as? PTRichTextMediaTextAttachment
        let videoAttachment = videoText.value.attribute(.attachment,
                                                         at: 0,
                                                         effectiveRange: nil) as? PTRichTextMediaTextAttachment

        XCTAssertEqual(imageAttachment?.media.kind, .image)
        XCTAssertEqual(videoAttachment?.media.kind, .video)
        XCTAssertEqual(imageAttachment?.attachmentSize, CGSize(width: 1, height: 1))
        XCTAssertEqual(videoAttachment?.attachmentSize, CGSize(width: 160, height: 90))
        XCTAssertEqual(videoAttachment?.media.videoConfiguration?.thumbnailFrameNumber, 10)
    }

    // English: Verify one media action carries a stable ID instead of a non-Sendable source object.
    // Español: Verifica que una acción multimedia transporte un ID estable y no una fuente no Sendable.
    // 中文：验证媒体动作传递稳定 ID，而不是跨并发边界传递不可 Sendable 的来源对象。
    func testRichMediaActionIsValueTyped() {
        let id = UUID()
        let action = PTRichTextMediaAction.video(id: id)

        guard case .video(let receivedID) = action else {
            return XCTFail("Expected a video media action")
        }
        XCTAssertEqual(receivedID, id)
    }

    func testTenThousandActionRunsCanBeBuilt() {
        measure {
            var value = PTRichText("")
            for index in 0..<10_000 {
                value += PTRichText(string: "x", with: [.action(PTTextActionID("action-\(index)"))])
                value += " "
            }
            XCTAssertEqual(value.plainText.count, 20_000)
        }
    }
}
