// English: Keep generated-catalog invariants separate from runtime availability tests.
// Español: Mantiene separadas las invariantes del catálogo generado de las pruebas de disponibilidad en runtime.
// 中文：将生成目录不变量与 Runtime 可用性测试分离。

import XCTest
@testable import ptools

@MainActor
final class PTFontGeneratedConsistencyTests: XCTestCase {
    func testGeneratedCatalogMatchesThePublishedCatalog() {
        XCTAssertEqual(PTFontCatalog.allFonts.count, PTFontCatalogGenerated.allFonts.count)
        XCTAssertEqual(PTFontCatalog.allFonts, PTFontCatalogGenerated.allFonts)
    }

    func testFamilyLookupContainsOnlyMatchingFamilies() {
        let family = PTFontCatalog.allFonts[0].familyName
        XCTAssertTrue(PTFontCatalog.fonts(family: family).allSatisfy { $0.familyName == family })
    }
}
