// English: Verify the generated font catalog and its 5.x compatibility surface.
// Español: Verifica el catálogo de fuentes generado y su superficie compatible de 5.x.
// 中文：验证生成字体目录及其 5.x 兼容入口。

import XCTest
@testable import PToolsFontCatalogCore

@MainActor
final class PTFontCatalogTests: XCTestCase {
    func testCatalogHasUniqueNames() {
        let fonts = PTFontCatalog.allFonts
        XCTAssertFalse(fonts.isEmpty)
        XCTAssertEqual(Set(fonts.map(\.postScriptName)).count, fonts.count)
        XCTAssertTrue(fonts.allSatisfy { !$0.familyName.isEmpty })
    }

    func testFamilyAndPostScriptLookupUseTheSameCatalog() {
        let knownFont = PTFont.pingFangSCRegular
        XCTAssertEqual(PTFontCatalog.font(named: knownFont.postScriptName), knownFont)
        XCTAssertTrue(PTFontCatalog.fonts(family: knownFont.familyName).contains(knownFont))
        XCTAssertTrue(PTFontCatalog.contains(postScriptName: knownFont.postScriptName))
    }

}
