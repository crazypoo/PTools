//
//  PTModelCoreTests.swift
//
// English: Regression coverage for the Foundation-only PTModel boundary.
// Español: Cobertura de regresión para el límite PTModel basado únicamente en Foundation.
// 中文：仅依赖 Foundation 的 PTModel 边界回归测试。
//

import Foundation
import XCTest
@testable import PToolsModelCore

final class PTModelCoreTests: XCTestCase {
    private struct User: Codable, Equatable {
        let id: Int
        let name: String
    }

    func testTopLevelModelAndArrayConversion() throws {
        let user = try User.pt.model(from: #"{"id":7,"name":"Jax"}"#)
        XCTAssertEqual(user, User(id: 7, name: "Jax"))

        let users = try User.pt.models(from: #"[{"id":7,"name":"Jax"}]"#)
        XCTAssertEqual(users, [User(id: 7, name: "Jax")])
    }

    func testFoundationDictionarySourceAndBidirectionalConversion() throws {
        let user = try User.pt.model(from: ["id": 8, "name": "PTools"] as [String: Any])
        XCTAssertEqual(user, User(id: 8, name: "PTools"))

        let json = try user.pt.jsonString()
        XCTAssertEqual(json, #"{"id":8,"name":"PTools"}"#)
        XCTAssertEqual(try user.pt.dictionary()["id"] as? Int, 8)
    }

    func testExactNumberAndDuplicateKeyPolicy() throws {
        let value = try PTJSONValue(jsonString: #"{"value":1234567890123456789.123456789}"#)
        guard case .object(let object) = value, case .number(let number) = object["value"] else {
            return XCTFail("Expected an exact JSON number")
        }
        XCTAssertEqual(number.rawRepresentation, "1234567890123456789.123456789")

        XCTAssertThrowsError(try PTJSONValue(jsonString: #"{"id":1,"id":2}"#, duplicateKeyPolicy: .reject))
        let last = try PTJSONValue(jsonString: #"{"id":1,"id":2}"#, duplicateKeyPolicy: .keepLast)
        XCTAssertEqual(last, .object(["id": .number(try PTJSONNumber("2"))]))
    }

    func testPresenceAndTopLevelFragments() throws {
        let presence: PTPresence<String> = .value("ok")
        let encoded = try PTModelEncoder().encode(presence)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), #""ok""#)

        let number = try PTModelDecoder(policy: .strict).decode(Int.self, from: Data("42".utf8))
        XCTAssertEqual(number, 42)
        let values = try PTModelDecoder(policy: .strict).decode([Int].self, from: Data("[1,2,3]".utf8))
        XCTAssertEqual(values, [1, 2, 3])
    }
}
