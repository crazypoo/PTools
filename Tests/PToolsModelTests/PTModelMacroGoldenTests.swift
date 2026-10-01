//
//  PTModelMacroGoldenTests.swift
//
// English: Independent runtime golden checks for macro field discovery and inheritance metadata.
// Español: Comprobaciones golden independientes para el descubrimiento de campos y metadatos de herencia de macros.
// 中文：独立验证宏字段发现、包装器、结构映射和继承元数据。
//

import Foundation
import XCTest
@testable import PToolsModelCore
import PToolsModel

#if SWIFT_PACKAGE
@PTModel
public struct PTSchemaBoundaryMacroFixture: Codable, Sendable, Equatable {
    @PTPolymorphic
    public let kind: String
    @PTExtras
    public let payload: String

    public init(kind: String, payload: String) {
        self.kind = kind
        self.payload = payload
    }
}

final class PTModelMacroGoldenTests: XCTestCase {
    func testFieldDiscoveryGolden() throws {
        let fields = PTComposedWrappedMacroFixture.ptSchema.metadata.fields
        XCTAssertEqual(fields.map(\.name), ["value"])
        XCTAssertTrue(fields[0].annotations.contains("PTTestBox"))
        XCTAssertTrue(fields[0].annotations.contains("PTClampedBox"))

        let structured = PTStructuredMacroFixture.ptSchema.metadata.fields
        XCTAssertEqual(structured.map(\.name), ["note", "profile"])
        XCTAssertEqual(structured[0].path?.description, "$.meta.note")
        XCTAssertTrue(structured[1].flattened)

        let defaulted = PTMacroPolicyFixture.ptSchema.metadata.fields.first { $0.name == "count" }
        XCTAssertEqual(defaulted?.defaultExpression, "7")
    }

    func testInheritanceGolden() throws {
        let fields = PTMacroGrandchildFixture.ptClassSchemaMetadata.fields
        XCTAssertEqual(fields.map(\.name), ["baseID", "label", "rank"])
        XCTAssertEqual(fields.filter(\.isInherited).map(\.name), ["baseID", "label"])
        XCTAssertTrue(PTMacroGrandchildFixture.ptClassUsesDirectPath)
        XCTAssertFalse(PTMacroImmutableFixture.ptClassUsesDirectPath)
    }

    func testStructuredDirectPathGolden() throws {
        let input = Data(#"{"meta":{"note":"nested"},"name":"PTools","age":18}"#.utf8)
        let decoded = try PTStaticCodec.decode(PTStructuredMacroFixture.self, from: input)
        XCTAssertEqual(decoded.note, "nested")
        XCTAssertEqual(decoded.profile, PTFlatProfile(name: "PTools", age: 18))

        let output = try PTStaticCodec.jsonValue(decoded)
        XCTAssertEqual(output, .object([
            "meta": .object(["note": .string("nested")]),
            "name": .string("PTools"),
            "age": .number(try PTJSONNumber("18"))
        ]))
    }

    func testAnnotationBoundaryGolden() throws {
        XCTAssertFalse(PTSchemaBoundaryMacroFixture.ptUsesDirectPath)
        let fields = PTSchemaBoundaryMacroFixture.ptSchema.metadata.fields
        XCTAssertEqual(fields.map(\.name), ["kind", "payload"])
        XCTAssertTrue(fields[0].annotations.contains("PTPolymorphic"))
        XCTAssertTrue(fields[1].annotations.contains("PTExtras"))

        guard case .object(let schema) = PTSchemaBoundaryMacroFixture.ptSchema.jsonSchema(),
              case .object(let properties) = schema["properties"],
              case .object(let kind) = properties["kind"] else {
            return XCTFail("Expected annotation schema metadata")
        }
        XCTAssertEqual(kind["x-pt-polymorphic"], .bool(true))
    }

    func testKeyPolicyPrecedenceGolden() throws {
        let decoder = PTModelDecoder(keyPolicy: PTModelKeyPolicy(global: .camelCase,
                                                                  model: .snakeCase,
                                                                  superclass: .exact))
        let normalized = PTModelSchemaSupport.normalizedInput(
            .object(["user_id": .number(try PTJSONNumber("42"))]),
            fields: PTKeyPolicyMacroFixture.ptSchema.metadata.fields,
            keyPolicy: decoder.keyPolicy)
        XCTAssertEqual(normalized, .object(["user_id": .number(try PTJSONNumber("42")),
                                            "userID": .number(try PTJSONNumber("42"))]))
        let decoded = try PTStaticCodec.decode(PTKeyPolicyMacroFixture.self,
                                              from: Data(#"{"user_id":42}"#.utf8),
                                              using: decoder)
        XCTAssertEqual(decoded.userID, 42)

        let encoded = try PTStaticCodec.jsonValue(decoded,
                                                   using: PTModelEncoder(keyPolicy: PTModelKeyPolicy(global: .snakeCase)))
        XCTAssertEqual(encoded, .object(["user_id": .number(try PTJSONNumber("42"))]))

        let parent = PTModelFieldDescriptor(name: "parentID")
        let child = PTModelFieldDescriptor(name: "childID")
        let merged = PTModelSchemaSupport.mergedFields(parent: [parent], own: [child])
        let policy = PTModelKeyPolicy(global: .camelCase,
                                      model: .snakeCase,
                                      superclass: .exact)
        XCTAssertEqual(policy.candidates(for: merged.fields[0]), ["parentID"])
        XCTAssertTrue(policy.candidates(for: merged.fields[1]).contains("child_id"))
    }
}
#endif
