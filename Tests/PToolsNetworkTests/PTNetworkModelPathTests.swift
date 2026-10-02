//
// English: Regression coverage for explicit typed response-root selection.
// Español: Cobertura de regresión para la selección explícita de la raíz de respuestas tipadas.
// 中文：覆盖类型化响应显式根路径选择的回归测试。
//

import Foundation
import XCTest
import PToolsModelCore
@testable import PooToolsNetWork

private struct PTNetworkPathUserFixture: Codable, Sendable, Equatable {
    let id: Int
    let name: String
}

final class PTNetworkModelPathTests: XCTestCase {
    func testRootModelPathKeepsExistingBehavior() throws {
        let payload = PTNetworkResponsePayload(data: Data(#"{"id":1,"name":"Root"}"#.utf8))

        let model = try PTNetworkResponseDecoder<PTNetworkPathUserFixture>
            .ptModel(PTNetworkPathUserFixture.self)
            .decode(payload)

        XCTAssertEqual(model, PTNetworkPathUserFixture(id: 1, name: "Root"))
    }

    func testDataPathDecodesWrappedModel() throws {
        let payload = PTNetworkResponsePayload(data: Data(#"{"code":200,"data":{"id":2,"name":"Data"}}"#.utf8))

        let model = try PTNetworkResponseDecoder<PTNetworkPathUserFixture>
            .ptModel(PTNetworkPathUserFixture.self, at: "$.data")
            .decode(payload)

        XCTAssertEqual(model.name, "Data")
    }

    func testDeepPathDecodesNestedArray() throws {
        let payload = PTNetworkResponsePayload(data: Data(#"{"result":{"payload":{"list":[{"id":3,"name":"A"},{"id":4,"name":"B"}]}}}"#.utf8))

        let models = try PTNetworkResponseDecoder<[PTNetworkPathUserFixture]>
            .ptModel([PTNetworkPathUserFixture].self, at: "$.result.payload.list")
            .decode(payload)

        XCTAssertEqual(models.map(\.id), [3, 4])
    }

    func testMissingPathIsTyped() throws {
        let payload = PTNetworkResponsePayload(data: Data(#"{"code":200}"#.utf8))

        XCTAssertThrowsError(try PTNetworkResponseDecoder<PTNetworkPathUserFixture>
            .ptModel(PTNetworkPathUserFixture.self, at: "$.data")
            .decode(payload)) { error in
                guard case .modelPathNotFound(let path) = error as? PTNetworkDecodeError else {
                    return XCTFail("Expected a typed missing-path error, got \(error)")
                }
                XCTAssertEqual(path, "$.data")
            }
    }

    func testWrongSelectedShapeIsTyped() throws {
        let payload = PTNetworkResponsePayload(data: Data(#"{"data":[]}"#.utf8))

        XCTAssertThrowsError(try PTNetworkResponseDecoder<PTNetworkPathUserFixture>
            .ptModel(PTNetworkPathUserFixture.self, at: "$.data")
            .decode(payload)) { error in
                guard case .modelPathTypeMismatch(let path, _, let actual) = error as? PTNetworkDecodeError else {
                    return XCTFail("Expected a typed path type error, got \(error)")
                }
                XCTAssertEqual(path, "$.data")
                XCTAssertEqual(actual, "Array")
            }
    }
}
