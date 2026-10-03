// English: Freeze the 5.x FontName forwarding contract while new code uses PTFontCatalog.
// Español: Congela el contrato de reenvío FontName de 5.x mientras el código nuevo usa PTFontCatalog.
// 中文：在新代码使用 PTFontCatalog 的同时，固定 5.x FontName 转发契约。

import XCTest
@testable import PToolsFontCatalogCore

@MainActor
final class PTFontCompatibilityTests: XCTestCase {
    func testLegacyFontNameForwardsToCatalog() {
        XCTAssertEqual(FontName.PingFangSCRegular, PTFont.pingFangSCRegular.postScriptName)
        XCTAssertEqual(FontName.fontNames(), PTFontCatalog.allFonts.map(\.postScriptName))
    }
}
