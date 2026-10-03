//
// English: Regression coverage for explicit typed response-root selection.
// Español: Cobertura de regresión para la selección explícita de la raíz de respuestas tipadas.
// 中文：覆盖类型化响应显式根路径选择的回归测试。
//

import Foundation
import XCTest
import PToolsModelCore
import PToolsNetworkModelCore

private struct PTNetworkPathUserFixture: Codable, Sendable, Equatable {
    let id: Int
    let name: String
}

private struct PTNetworkPathNestedUserFixture: Codable, Sendable, Equatable {
    let id: Int
    let name: String
}

private struct PTNetworkPathEnvelopeFixture: Codable, Sendable, Equatable {
    let user: PTNetworkPathNestedUserFixture
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

    func testSelectedObjectWithInvalidFieldProducesModelDecodeError() throws {
        let payload = PTNetworkResponsePayload(data: Data(#"{"data":{"id":"not-an-int","name":"Invalid"}}"#.utf8))

        XCTAssertThrowsError(try PTNetworkResponseDecoder<PTNetworkPathUserFixture>
            .ptModel(PTNetworkPathUserFixture.self, at: "$.data")
            .decode(payload)) { error in
                guard case .modelDecodeFailed(let path, let message) = error as? PTNetworkDecodeError else {
                    return XCTFail("Expected a model decode error, got \(error)")
                }
                XCTAssertEqual(path, "$.data")
                XCTAssertTrue(message.contains("id"), "The field path must remain diagnosable: \(message)")
            }
    }

    func testNestedFieldFailureKeepsFullPath() throws {
        let payload = PTNetworkResponsePayload(data: Data(#"{"data":{"user":{"id":"not-an-int","name":"Nested"}}}"#.utf8))

        XCTAssertThrowsError(try PTNetworkResponseDecoder<PTNetworkPathEnvelopeFixture>
            .ptModel(PTNetworkPathEnvelopeFixture.self, at: "$.data")
            .decode(payload)) { error in
                guard case .modelDecodeFailed(let path, let message) = error as? PTNetworkDecodeError else {
                    return XCTFail("Expected a nested model decode error, got \(error)")
                }
                XCTAssertEqual(path, "$.data")
                XCTAssertTrue(message.contains("user"), "The nested field path must remain diagnosable: \(message)")
                XCTAssertTrue(message.contains("id"), "The nested field path must remain diagnosable: \(message)")
            }
    }

    func testRequiredFailureKeepsFieldPath() throws {
        let payload = PTNetworkResponsePayload(data: Data(#"{"data":{"name":"Missing ID"}}"#.utf8))

        XCTAssertThrowsError(try PTNetworkResponseDecoder<PTNetworkPathUserFixture>
            .ptModel(PTNetworkPathUserFixture.self, at: "$.data")
            .decode(payload)) { error in
                guard case .modelDecodeFailed(let path, let message) = error as? PTNetworkDecodeError else {
                    return XCTFail("Expected a required-field decode error, got \(error)")
                }
                XCTAssertEqual(path, "$.data")
                XCTAssertTrue(message.contains("id"), "The missing field path must remain diagnosable: \(message)")
            }
    }

    func testNumericOverflowKeepsFieldPath() throws {
        let payload = PTNetworkResponsePayload(data: Data(#"{"data":{"id":999999999999999999999999999999,"name":"Overflow"}}"#.utf8))

        XCTAssertThrowsError(try PTNetworkResponseDecoder<PTNetworkPathUserFixture>
            .ptModel(PTNetworkPathUserFixture.self, at: "$.data")
            .decode(payload)) { error in
                guard case .modelDecodeFailed(let path, let message) = error as? PTNetworkDecodeError else {
                    return XCTFail("Expected a numeric overflow decode error, got \(error)")
                }
                XCTAssertEqual(path, "$.data")
                XCTAssertTrue(message.contains("id"), "The overflow field path must remain diagnosable: \(message)")
            }
    }
}
