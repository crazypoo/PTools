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
