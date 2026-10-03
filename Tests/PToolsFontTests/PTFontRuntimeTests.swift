// English: Validate lazy runtime discovery without assuming every catalog font exists on every iOS runtime.
// Español: Valida el descubrimiento diferido sin asumir que cada fuente del catálogo existe en cada runtime iOS.
// 中文：验证按需 Runtime 发现，不假设每个 iOS Runtime 都包含目录中的全部字体。

import XCTest
@testable import ptools

@MainActor
final class PTFontRuntimeTests: XCTestCase {
    func testRuntimeDiscoveryDoesNotDuplicatePostScriptNames() {
        let descriptors = PTFontRuntime.installedFonts
        XCTAssertEqual(Set(descriptors.map(\.postScriptName)).count, descriptors.count)
    }

    func testUnknownCatalogLookupReturnsNil() {
        XCTAssertNil(PTFontCatalog.font(named: "PTools.Unknown.Font"))
    }

    func testCanonicalRuntimeFontCanBeConstructedWhenInstalled() {
        let descriptor = PTFontRuntime.installedFonts.first
        XCTAssertNotNil(descriptor)
        if let descriptor {
            XCTAssertNotNil(UIFont(name: descriptor.postScriptName, size: 12))
        }
    }
}
