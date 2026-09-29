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

    private struct PresenceEnvelope: Codable, Equatable {
        let value: PTPresence<String>

        init(value: PTPresence<String>) {
            self.value = value
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            value = try container.decodePresence(String.self, forKey: .value)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value, forKey: .value)
        }

        private enum CodingKeys: String, CodingKey { case value }
    }

    private struct BoolEnvelope: Decodable, Equatable {
        let enabled: Bool
    }

    private struct IntEnvelope: Decodable, Equatable {
        let value: Int
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

        let firstDecoder = PTModelDecoder(policy: .strict, duplicateKeyPolicy: .keepFirst)
        let first = try firstDecoder.decode(IntEnvelope.self,
                                            from: Data(#"{"value":1,"value":2}"#.utf8))
        XCTAssertEqual(first, IntEnvelope(value: 1))
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

    func testPresenceOmitsMissingAndKeepsNull() throws {
        let encoder = PTModelEncoder()
        XCTAssertEqual(String(data: try encoder.encode(PresenceEnvelope(value: .missing)), encoding: .utf8), "{}")
        XCTAssertEqual(String(data: try encoder.encode(PresenceEnvelope(value: .null)), encoding: .utf8), #"{"value":null}"#)
        let decoded = try PTModelDecoder(policy: .strict).decode(PresenceEnvelope.self, from: Data(#"{}"#.utf8))
        XCTAssertTrue(decoded.value.isMissing)

        let nullStrategy = PTModelEncoder(nilStrategy: .null)
        let value: String? = nil
        struct OptionalEnvelope: Encodable {
            let value: String?
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(value, forKey: .value, nilStrategy: .null)
            }
            enum CodingKeys: String, CodingKey { case value }
        }
        _ = nullStrategy
        XCTAssertEqual(String(data: try encoder.encode(OptionalEnvelope(value: value)), encoding: .utf8), #"{}"#)
        XCTAssertEqual(String(data: try PTModelEncoder(nilStrategy: .null).encode(OptionalEnvelope(value: value)), encoding: .utf8), #"{"value":null}"#)
    }

    func testUnicodeSurrogateAndParserLimits() throws {
        let value = try PTJSONValue(jsonString: #"{"emoji":"\uD83D\uDE00"}"#)
        guard case .object(let object) = value, case .string(let emoji) = object["emoji"] else {
            return XCTFail("Expected a decoded surrogate pair")
        }
        XCTAssertEqual(emoji, "😀")
        XCTAssertThrowsError(try PTJSONValue(jsonString: #""\uD83D""#))

        let limits = PTModelLimits(maxInputBytes: 1024,
                                   maxDepth: 8,
                                   maxStringBytes: 3,
                                   maxCollectionCount: 2,
                                   maxObjectKeyCount: 2,
                                   maxNumberDigits: 3)
        XCTAssertThrowsError(try PTJSONValue(jsonString: #""1234""#, limits: limits))
        XCTAssertThrowsError(try PTJSONValue(jsonString: "[1,2,3]", limits: limits))
        XCTAssertThrowsError(try PTJSONValue(jsonString: "1234", limits: limits))
    }

    func testFoundationBooleanAndSafeCoercion() throws {
        let bool = try PTModelDecoder(policy: .compatible).decode(BoolEnvelope.self,
                                                                  from: ["enabled": NSNumber(value: true)] as [String: Any])
        XCTAssertEqual(bool, BoolEnvelope(enabled: true))
        let number = try PTModelDecoder(policy: .strict).decode(IntEnvelope.self,
                                                                from: ["value": NSNumber(value: Int64(1))] as [String: Any])
        XCTAssertEqual(number, IntEnvelope(value: 1))
        let scalar = try PTModelDecoder(policy: .compatible).decode(Int.self, from: "42")
        XCTAssertEqual(scalar, 42)
        XCTAssertThrowsError(try PTModelDecoder(policy: .compatible).decode(Int.self, from: "12abc"))
    }

    func testPathAliasesCollectionsDictionaryAndSet() throws {
        let json = try PTJSONValue(jsonString: #"{"items":[{"name":"one"}]}"#)
        let path = try PTJSONPath.parse("$.items[0].name")
        XCTAssertEqual(try json.requiredValue(at: path), .string("one"))
        let mapping = PTModelKeyMapping(decodeKeys: ["legacy_name", "name"], encodeKey: "name")
        let object = PTJSONValue.object(["legacy_name": .string("old"), "name": .string("new")])
        XCTAssertEqual(try object.aliasedValue(using: mapping), .string("new"))
        let aliased = try decoderForTests.decodeAliased(String.self,
                                                        from: object,
                                                        mapping: mapping)
        XCTAssertEqual(aliased, "new")

        let decoder = PTModelDecoder(policy: .compatible,
                                     dictionaryKeyStrategy: .losslessStringConvertible)
        let dictionary = try decoder.decodeDictionary(Int.self, String.self,
                                                       from: .object(["1": .string("one")]))
        XCTAssertEqual(dictionary[1], "one")
        let encoder = PTModelEncoder(dictionaryKeyStrategy: .losslessStringConvertible)
        XCTAssertEqual(try encoder.jsonValue(dictionary: [1: "one"]), .object(["1": .string("one")]))

        let setValue = try encoder.jsonValue(set: Set([3, 1, 2]))
        XCTAssertEqual(setValue, .array([.number(try PTJSONNumber("1")), .number(try PTJSONNumber("2")), .number(try PTJSONNumber("3"))]))
        XCTAssertThrowsError(try decoder.decodeSet(Int.self,
                                                    from: .array([.number(try PTJSONNumber("1")), .number(try PTJSONNumber("1"))]),
                                                    duplicatePolicy: .reject))

        XCTAssertEqual(try decoderForTests.decodeOptional(String.self,
                                                          from: .object([:]),
                                                          emptyObjectStrategy: .decodeAsNil), nil)
        XCTAssertEqual(try decoderForTests.decodeOptional(String.self,
                                                          from: .object([:]),
                                                          emptyObjectStrategy: .decodeAsDefault,
                                                          defaultValue: "default"), "default")
        if case .invalid(let path) = decoderForTests.decodeField(Int.self,
                                                                  from: .object(["value": .string("bad")]),
                                                                  key: "value") {
            XCTAssertEqual(path, "$.value")
        } else {
            XCTFail("Expected an invalid field state")
        }
    }

    private var decoderForTests: PTModelDecoder {
        PTModelDecoder(policy: .compatible, dictionaryKeyStrategy: .losslessStringConvertible)
    }

    func testByteSinkAndCodingSession() throws {
        var sink = PTDataByteSink()
        try PTModelEncoder().write(User(id: 1, name: "sink"), to: &sink)
        XCTAssertEqual(String(data: sink.data, encoding: .utf8), #"{"id":1,"name":"sink"}"#)

        var session = PTModelCodingSession()
        session.push(try PTJSONPath.parse("$.user"))
        XCTAssertEqual(session.currentPath.description, "$.user")
        XCTAssertEqual(session.pop()?.description, "$.user")
        XCTAssertEqual(session.currentPath, .root)

        try session.withFrame(try PTJSONPath.parse("$.nested")) { session in
            XCTAssertEqual(session.currentPath.description, "$.nested")
        }
        XCTAssertEqual(session.currentPath, .root)
    }
}
