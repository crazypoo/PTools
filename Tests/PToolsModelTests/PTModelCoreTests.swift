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
import PToolsModel

#if SWIFT_PACKAGE
@PTModel
public struct PTMacroFixture: Codable, Sendable, Equatable {
    public let id: Int
    public let name: String
    public let note: String?
}
#endif

final class PTModelCoreTests: XCTestCase {
    private struct User: Codable, Equatable, Sendable {
        let id: Int
        let name: String
    }

    private struct PresenceEnvelope: Codable, Equatable, Sendable {
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

    private struct BoolEnvelope: Decodable, Equatable, Sendable {
        let enabled: Bool
    }

    private struct IntEnvelope: Decodable, Equatable, Sendable {
        let value: Int
    }

    struct StaticEnvelope: Codable, Equatable, Sendable, PTStaticModel {
        let id: Int
        let note: String?

        static let idField = PTModelFieldDescriptor(name: "id", required: true)
        static let noteField = PTModelFieldDescriptor(name: "note")

        static var ptSchema: PTModelSchema<StaticEnvelope> {
            PTModelSchema(name: "StaticEnvelope",
                          version: 2,
                          fields: [idField, noteField],
                          decode: { value, decoder in
                              try decoder.decode(StaticEnvelope.self, from: value)
                          },
                          encode: { model, encoder in
                              try encoder.object(fields: [
                                  (idField, encoder.jsonValue(model.id)),
                                  (noteField, model.note.map { try encoder.jsonValue($0) })
                              ])
                          })
        }
    }

    private struct StreamItem: Codable, Equatable, Sendable {
        let id: Int
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
        XCTAssertEqual(String(data: try encoder.encode(OptionalEnvelope(value: value)), encoding: .utf8), #"{"value":null}"#)
        XCTAssertEqual(String(data: try PTModelEncoder(nilStrategy: .null).encode(OptionalEnvelope(value: value)), encoding: .utf8), #"{"value":null}"#)

        struct SynthesizedOptionalEnvelope: Codable, Sendable {
            let value: String?
            let nested: [String?]
        }
        let synthesized = SynthesizedOptionalEnvelope(value: nil, nested: ["kept", nil])
        XCTAssertEqual(try PTModelEncoder(nilStrategy: .omit).jsonString(synthesized), #"{"nested":["kept",null]}"#)
        // English: Synthesized Codable keeps its established encodeIfPresent omission; schemas or explicit encodeNil opt into null.
        // Español: Codable sintetizado conserva la omisión de encodeIfPresent; los esquemas o encodeNil explícito permiten null.
        // 中文：合成 Codable 保持 encodeIfPresent 的既有省略行为；Schema 或显式 encodeNil 才选择输出 null。
        XCTAssertEqual(try PTModelEncoder(nilStrategy: .null).jsonString(synthesized), #"{"nested":["kept",null]}"#)
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

        try session.withFrame(PTJSONPath.parse("$.nested")) { session in
            XCTAssertEqual(session.currentPath.description, "$.nested")
        }
        XCTAssertEqual(session.currentPath, .root)
    }

    func testFieldRecoveryAndDiagnostics() async throws {
        let field = PTModelFieldDescriptor(name: "count", required: false)
        let recovery = PTFieldRecovery<Int>(defaultValue: 7,
                                            missingPolicy: .useDefault,
                                            nullPolicy: .useDefault,
                                            invalidPolicy: .useDefault)
        let decoder = PTModelDecoder(policy: .compatible)
        let object = PTJSONValue.object(["count": .string("not-a-number")])
        XCTAssertEqual(try decoder.resolveField(Int.self,
                                                from: object,
                                                field: field,
                                                recovery: recovery), 7)
        XCTAssertEqual(try decoder.resolveField(Int.self,
                                                from: .object([:]),
                                                field: field,
                                                recovery: recovery), 7)

        let required = PTFieldRecovery<Int>(missingPolicy: .error)
        XCTAssertThrowsError(try decoder.resolveField(Int.self,
                                                      from: .object([:]),
                                                      field: PTModelFieldDescriptor(name: "id", required: true),
                                                      recovery: required))

        let store = PTModelDiagnosticStore()
        let sink = store.sink
        sink.record(PTModelDiagnostic(code: "fixture", message: "recorded"))
        for _ in 0..<4 { await Task.yield() }
        let diagnostics = await store.diagnostics()
        XCTAssertEqual(diagnostics.map(\.code), ["fixture"])
    }

    func testStaticSchemaNilPoliciesAndJSONSchema() throws {
        let model = StaticEnvelope(id: 3, note: nil)
        let omitted = try PTStaticCodec.jsonValue(model, using: PTModelEncoder(nilStrategy: .omit))
        XCTAssertEqual(omitted, .object(["id": .number(try PTJSONNumber("3"))]))

        let nullSchema = PTModelSchema<StaticEnvelope>(name: "StaticEnvelope",
                                                        fields: [StaticEnvelope.idField,
                                                                 PTModelFieldDescriptor(name: "note", encoding: .null)],
                                                        decode: { value, decoder in
                                                            try decoder.decode(StaticEnvelope.self, from: value)
                                                        },
                                                        encode: { model, encoder in
                                                            try encoder.object(fields: [
                                                                (StaticEnvelope.idField, encoder.jsonValue(model.id)),
                                                                (PTModelFieldDescriptor(name: "note", encoding: .null), model.note.map { try encoder.jsonValue($0) })
                                                            ])
                                                        })
        XCTAssertEqual(try nullSchema.encode(model),
                       .object(["id": .number(try PTJSONNumber("3")), "note": .null]))

        let schema = StaticEnvelope.ptSchema.jsonSchema()
        guard case .object(let values) = schema else { return XCTFail("Expected JSON Schema object") }
        XCTAssertEqual(values["title"], .string("StaticEnvelope"))
        XCTAssertEqual(values["x-pt-schema-version"], .number(try PTJSONNumber("2")))
    }

    func testPatchDiffCloneConversionAndMigration() throws {
        let old: PTJSONValue = .object([
            "id": .number(try PTJSONNumber("1")),
            "profile": .object(["name": .string("old")])
        ])
        let new: PTJSONValue = .object([
            "id": .number(try PTJSONNumber("1")),
            "profile": .object(["name": .string("new"), "age": .number(try PTJSONNumber("18"))])
        ])
        let diff = PTModelDiff.make(from: old, to: new)
        XCTAssertEqual(try diff.applying(to: old), new)
        XCTAssertEqual(diff.operations.count, 2)

        let patch = PTModelPatch(operations: [
            .merge(path: try PTJSONPath.parse("$.profile"), value: .object(["active": .bool(true)])),
            .remove(path: try PTJSONPath.parse("$.profile.name"))
        ])
        let patched = try patch.applying(to: new)
        XCTAssertEqual(try patched.requiredValue(at: PTJSONPath.parse("$.profile.active")), .bool(true))
        XCTAssertThrowsError(try patched.requiredValue(at: PTJSONPath.parse("$.profile.name")))

        let migration = PTModelMigrationChain([
            PTModelMigration(fromVersion: 2, toVersion: 3) { value in
                guard case .object(var object) = value else { return value }
                object["v3"] = .bool(true)
                return .object(object)
            },
            PTModelMigration(fromVersion: 1, toVersion: 2) { value in
                guard case .object(var object) = value else { return value }
                object["v2"] = .bool(true)
                return .object(object)
            }
        ])
        let migrated = try migration.migrate(.object([:]), from: 1, to: 3)
        XCTAssertEqual(try migrated.requiredValue(at: PTJSONPath.parse("$.v2")), .bool(true))
        XCTAssertEqual(try migrated.requiredValue(at: PTJSONPath.parse("$.v3")), .bool(true))
        XCTAssertThrowsError(try migration.migrate(migrated, from: 3, to: 1))

        let source = User(id: 4, name: "clone")
        XCTAssertEqual(try PTModelClone.clone(source), source)
        let converted = try PTModelConverter.convert(source, to: User.self)
        XCTAssertEqual(converted, source)
    }

    func testScannerFoundationCodecsAndExtras() throws {
        var scanner = try PTJSONScanner(data: Data(#"{"known":1,"unknown":{"items":[1,2,3]}}"#.utf8))
        try scanner.skipUnknownSubtree()
        XCTAssertTrue(scanner.isAtEnd)

        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let dateValue = try PTModelFoundationCodec.date(date, strategy: .secondsSince1970)
        XCTAssertEqual(try PTModelFoundationCodec.date(from: dateValue, strategy: .secondsSince1970), date)
        let bytes = Data("PTools".utf8)
        let bytesValue = try PTModelFoundationCodec.data(bytes, strategy: .utf8)
        XCTAssertEqual(try PTModelFoundationCodec.data(from: bytesValue, strategy: .utf8), bytes)
        let deferredBytes = try PTModelFoundationCodec.data(bytes, strategy: .deferredToData)
        let expectedDeferredBytes = try bytes.map { byte -> PTJSONValue in
            .number(try PTJSONNumber(String(byte)))
        }
        XCTAssertEqual(deferredBytes, .array(expectedDeferredBytes))
        XCTAssertEqual(try PTModelFoundationCodec.data(from: deferredBytes, strategy: .deferredToData), bytes)
        let url = URL(string: "https://example.com/a")!
        XCTAssertEqual(try PTModelFoundationCodec.url(from: PTModelFoundationCodec.url(url)), url)

        let extras = PTExtras(values: ["future": .string("kept")])
        XCTAssertEqual(extras.merged(into: ["id": .number(try PTJSONNumber("1"))])["future"], .string("kept"))
    }

    func testStreamingDecodeAndEncode() async throws {
        let decoder = PTModelStreamDecoder<StreamItem>(jsonString: "[{\"id\":1},{\"id\":2},{\"id\":3}]")
        var decoded: [StreamItem] = []
        for try await item in decoder {
            decoded.append(item)
        }
        XCTAssertEqual(decoded.map(\.id), [1, 2, 3])

        let sourceItems = decoded
        let sequence = AsyncStream<StreamItem> { continuation in
            for item in sourceItems { continuation.yield(item) }
            continuation.finish()
        }
        let encoded = try await PTModelStreamEncoder<StreamItem>().encode(sequence)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), "[{\"id\":1},{\"id\":2},{\"id\":3}]")
        XCTAssertThrowsError(try PTModelDecoder().decode(StreamItem.self, from: Data("bad".utf8)))
    }

    func testConcurrentSessionsStayIndependent() async throws {
        let decoder = PTModelDecoder(policy: .strict)
        let encoder = PTModelEncoder()
        let input = Data(#"{"id":9,"name":"parallel"}"#.utf8)
        let values = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<100 {
                group.addTask {
                    guard let value = try? decoder.decode(User.self, from: input),
                          value == User(id: 9, name: "parallel"),
                          let output = try? encoder.encode(value) else { return false }
                    return !output.isEmpty
                }
            }
            var result: [Bool] = []
            for await value in group { result.append(value) }
            return result
        }
        XCTAssertEqual(values.count, 100)
        XCTAssertTrue(values.allSatisfy { $0 })
    }

#if SWIFT_PACKAGE
    func testMacroGeneratesStaticSchema() throws {
        let value = PTMacroFixture(id: 8, name: "macro", note: nil)
        let json = try PTStaticCodec.jsonValue(value)
        XCTAssertEqual(json, .object([
            "id": .number(try PTJSONNumber("8")),
            "name": .string("macro")
        ]))
        XCTAssertEqual(try PTStaticCodec.jsonValue(value, using: PTModelEncoder(nilStrategy: .null)), .object([
            "id": .number(try PTJSONNumber("8")),
            "name": .string("macro"),
            "note": .null
        ]))
        XCTAssertEqual(try PTStaticCodec.decode(PTMacroFixture.self, from: json), value)
        XCTAssertEqual(PTMacroFixture.ptSchema.metadata.fields.map(\.name), ["id", "name", "note"])
    }
#endif

}
