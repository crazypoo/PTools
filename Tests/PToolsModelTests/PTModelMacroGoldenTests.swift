//
//  PTModelMacroGoldenTests.swift
//
// English: Independent runtime golden checks for macro field discovery and inheritance metadata.
// Español: Comprobaciones golden independientes para el descubrimiento de campos y metadatos de herencia de macros.
// 中文：独立验证宏字段发现、包装器、结构映射和继承元数据。
//

import Foundation
import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import PToolsModelCore
import PToolsModel
@testable import PToolsModelMacroPlugin

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

@PTModel
struct PTInternalMacroFixture: Codable, Sendable, Equatable {
    let value: Int

    init(value: Int) {
        self.value = value
    }
}

@PTModel
public struct PTManualCodableMacroFixture: Codable, Sendable, Equatable {
    public let value: Int

    public init(value: Int) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

@PTSubclass
final class PTObjCMacroFixture: NSObject, Codable, PTStaticClassModel {
    @objc dynamic var value: String = ""

    required override init() {
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

final class PTModelMacroGoldenTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "PTModel": PTModelMacro.self,
        "PTSubclass": PTSubclassMacro.self
    ]

    func testDuplicateKeyDiagnosticGolden() {
        assertMacroExpansion(
            """
            @PTModel
            struct DuplicateKey {
                @PTKey("same") let first: Int
                @PTKey("same") let second: Int
            }
            """,
            expandedSource: """
            struct DuplicateKey {
                @PTKey("same") let first: Int
                @PTKey("same") let second: Int
            }

            extension DuplicateKey: PTStaticModel {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@PTModel has duplicate encoded key 'same'",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testObservationBoundaryDiagnosticGolden() {
        assertMacroExpansion(
            """
            @Observable
            @PTModel
            struct ObservedModel {
                let value: Int
            }
            """,
            expandedSource: """
            @Observable
            struct ObservedModel {
                let value: Int
            }

            extension ObservedModel: PTStaticModel {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@PTModel does not synthesize Observation storage; use a manual PTStaticModel schema for @Observable types",
                    line: 2,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testInvalidAnnotationCombinationDiagnosticGolden() {
        assertMacroExpansion(
            """
            @PTModel
            struct InvalidAnnotations {
                @PTFlat @PTPath("$.profile") let profile: String
            }
            """,
            expandedSource: """
            struct InvalidAnnotations {
                @PTFlat @PTPath("$.profile") let profile: String
            }

            extension InvalidAnnotations: PTStaticModel {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@PTFlat and @PTPath cannot be combined",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testGenericSubclassBoundaryDiagnosticGolden() {
        assertMacroExpansion(
            """
            class GenericBase {
            }

            @PTSubclass
            class GenericChild<Value>: GenericBase {
                var value: Value
            }
            """,
            expandedSource: """
            class GenericBase {
            }
            class GenericChild<Value>: GenericBase {
                var value: Value
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@PTSubclass does not support generic subclasses; use a concrete subclass or a manual PTStaticClassModel schema",
                    line: 4,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testInheritedFlattenedFieldBoundaryDiagnosticGolden() {
        assertMacroExpansion(
            """
            class FlatBase {
            }

            @PTSubclass
            class FlatChild: FlatBase {
                @PTFlat var profile: Profile
            }
            """,
            expandedSource: """
            class FlatBase {
            }
            class FlatChild: FlatBase {
                @PTFlat var profile: Profile
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@PTFlat is not supported on @PTSubclass fields because inherited flattened keys are ambiguous",
                    line: 4,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

    func testRepeatedAnnotationDiagnosticGolden() {
        assertMacroExpansion(
            """
            @PTModel
            struct RepeatedAnnotation {
                @PTKey("first") @PTKey("second") let value: Int
            }
            """,
            expandedSource: """
            struct RepeatedAnnotation {
                @PTKey("first") @PTKey("second") let value: Int
            }

            extension RepeatedAnnotation: PTStaticModel {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "PTModel annotations cannot be repeated on the same property",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(4)
        )
    }

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

    func testAccessGenericObjectiveCGolden() throws {
        XCTAssertEqual(PTInternalMacroFixture.ptSchema.metadata.name, "PTInternalMacroFixture")
        XCTAssertEqual(PTInternalMacroFixture.ptSchema.metadata.fields.map(\.name), ["value"])
        XCTAssertTrue(PTGenericMacroFixture<Int>.ptUsesDirectPath)
        XCTAssertFalse(PTObjCMacroFixture.ptClassUsesDirectPath)
        XCTAssertEqual(PTObjCMacroFixture.ptClassSchemaMetadata.fields.map(\.name), ["value"])
    }

    func testManualCodableGolden() throws {
        let value = PTManualCodableMacroFixture(value: 58)
        let encoded = try PTStaticCodec.encode(value)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), #"{"value":58}"#)
        let decoded = try PTStaticCodec.decode(PTManualCodableMacroFixture.self,
                                               from: encoded)
        XCTAssertEqual(decoded, value)
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
