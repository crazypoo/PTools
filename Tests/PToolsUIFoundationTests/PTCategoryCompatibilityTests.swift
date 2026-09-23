import Foundation
import XCTest
@testable import ptools

// English: Covers the dependency-free category replacements used by Core and UI modules.
// Español: Cubre los reemplazos de categorías sin dependencias usados por Core y los módulos de UI.
// 中文：覆盖 Core 和 UI 模块使用的无第三方依赖 Category 替代实现。
@MainActor
final class PTCategoryCompatibilityTests: XCTestCase {
    func testSequenceAndArrayHelpersPreserveOrder() throws {
        let values = ["a", "b", "a", "c"]

        XCTAssertEqual(values.removingDuplicates(by: { $0 }), ["a", "b", "c"])
        XCTAssertEqual(values.single(where: { $0 == "b" }), "b")
        XCTAssertNil(values.single(where: { $0 == "a" }))
        XCTAssertEqual(values.divided(by: { $0 == "a" }).matching, ["a", "a"])
        XCTAssertEqual(try [1, 2, 3].sorted(matching: { $0 }, by: <), [1, 2, 3])
    }

    func testDictionaryHelpersUseExplicitOrderingAndTypedPaths() throws {
        var dictionary: [String: Any] = ["profile": ["name": "PTools"]]

        XCTAssertEqual(dictionary.value(at: ["profile", "name"]) as? String, "PTools")
        XCTAssertTrue(dictionary.setValue("Swift 6", at: ["profile", "language"]))
        XCTAssertEqual(dictionary.value(at: ["profile", "language"]) as? String, "Swift 6")
        XCTAssertNotNil(dictionary.jsonData())
        XCTAssertEqual(["a": 1, "b": 1].keys(forValue: 1).sorted(), ["a", "b"])
    }

    func testOptionalRangeAndURLHelpers() {
        let empty: [String]? = []
        let nonEmpty: [String]? = ["value"]

        XCTAssertTrue(empty.isNilOrEmpty)
        XCTAssertEqual(nonEmpty.nonEmpty, ["value"])

        var numbers = [1, 2, 3]
        XCTAssertEqual(numbers.removeFirst(where: { $0 == 2 }), 2)
        XCTAssertEqual(numbers, [1, 3])

        let url = URL(string: "https://example.com/path?source=ptools")
        XCTAssertEqual(url?.queryValue(for: "source"), "ptools")
        XCTAssertEqual(url?.appendingQueryParameters(["version": "5.23.0"])?.queryValue(for: "version"), "5.23.0")
    }
}
