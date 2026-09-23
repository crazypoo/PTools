import XCTest
import UIKit
@testable import PToolsSymbols

// English: Verify typed, dynamic, fallback, and catalog behavior without depending on a third-party symbol package.
// Español: Verifica el comportamiento tipado, dinámico, fallback y de catálogo sin depender de un paquete de terceros.
// 中文：验证类型化、动态、回退和目录行为，不再依赖第三方符号包。
@MainActor
final class PTSymbolTests: XCTestCase {
    func testRawAndChainedValues() {
        XCTAssertEqual(PTSymbol.trashCircle.rawValue, "trash.circle")
        XCTAssertEqual(PTSymbol.arrow.upBackwardAndArrowDownForward.rawValue,
                       "arrow.up.backward.and.arrow.down.forward")
        XCTAssertEqual(PTSymbol.line._3HorizontalDecreaseCircleFill.rawValue,
                       "line.3.horizontal.decrease.circle.fill")
    }

    func testCatalogContainsGeneratedEntries() {
        XCTAssertTrue(PTSymbolCatalog.allSymbols.contains { $0.symbol == .trashCircle })
        XCTAssertTrue(PTSymbolCatalog.allSymbols.contains { $0.symbol == .squareGrid3x1BelowLineGrid1x2 })
    }

    func testUnknownSymbolKeepsDynamicEscapeHatch() {
        let symbol = PTSymbol(rawValue: "future.system.symbol")
        XCTAssertEqual(symbol.rawValue, "future.system.symbol")
        XCTAssertEqual(PTSymbolFallback([symbol]).symbols, [symbol])
    }

    func testUnknownSymbolDoesNotCrashWithFallback() {
        let image = UIImage.pt_symbol(.init(rawValue: "future.symbol.that.does.not.exist"),
                                       fallback: .questionmarkDiamond)
        XCTAssertNotNil(image)
    }
}
