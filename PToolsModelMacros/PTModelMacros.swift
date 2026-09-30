//
//  PTModelMacros.swift
//
// English: Lightweight Swift macros generate schema metadata while keeping codec behavior in PTModelCore.
// Español: Estas macros ligeras generan metadatos de esquema y mantienen el comportamiento del codec en PTModelCore.
// 中文：轻量 Swift 宏只生成 Schema 元数据，具体 codec 行为仍由 PTModelCore 负责。
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum PTMacroSourceBuilder {
    struct FieldInfo {
        let name: String
        let typeName: String
        let wireKey: String
        let path: String?
        let defaultExpression: String?
        let required: Bool
        let flattened: Bool
        let lossy: Bool
        let stringified: Bool
        let annotations: [String]
        let encoding: String
        let missing: String
        let null: String
        let invalid: String
    }

    static func typeName(from declaration: some DeclGroupSyntax) -> String? {
        if let declaration = declaration.as(StructDeclSyntax.self) {
            return declaration.name.text
        }
        if let declaration = declaration.as(ClassDeclSyntax.self) {
            return declaration.name.text
        }
        return nil
    }

    static func fields(from declaration: some DeclGroupSyntax) throws -> [FieldInfo] {
        var result: [FieldInfo] = []
        let codingKeys = codingKeyMap(from: declaration)
        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }
            guard variable.bindings.count == 1,
                  let binding = variable.bindings.first,
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                throw MacroExpansionErrorMessage("@PTModel requires one named stored property per declaration")
            }
            let typeName = binding.typeAnnotation?.type.trimmedDescription
                ?? inferredTypeName(from: binding.initializer?.value)
            guard let typeName else {
                throw MacroExpansionErrorMessage("@PTModel requires an explicit type for properties without a supported literal initializer")
            }
            guard binding.accessorBlock == nil else {
                throw MacroExpansionErrorMessage("@PTModel does not support computed properties or property observers")
            }
            let modifiers = Set(variable.modifiers.map(\.name.text))
            guard modifiers.isDisjoint(with: ["static", "class", "lazy", "weak", "unowned"]) else {
                throw MacroExpansionErrorMessage("@PTModel only supports stored instance properties")
            }
            let attributes = variable.attributes.compactMap { element -> AttributeSyntax? in
                guard case .attribute(let attribute) = element else { return nil }
                return attribute
            }
            let names = attributes.map { $0.attributeName.trimmedDescription }
            if names.contains("PTIgnored") {
                if names.contains(where: { $0.hasPrefix("PT") && $0 != "PTIgnored" }) {
                    throw MacroExpansionErrorMessage("@PTIgnored cannot be combined with another PTModel field annotation")
                }
                continue
            }
            let wireKey = attributes.first(where: { $0.attributeName.trimmedDescription == "PTKey" })
                .flatMap(firstStringArgument) ?? codingKeys[name] ?? name
            let path = attributes.first(where: { $0.attributeName.trimmedDescription == "PTPath" })
                .flatMap(firstStringArgument)
            let defaultAttribute = attributes.first(where: { $0.attributeName.trimmedDescription == "PTDefault" })
            let defaultExpression = defaultAttribute.flatMap(argumentSource)
                ?? (defaultAttribute == nil ? nil : binding.initializer?.value.trimmedDescription)
            let required = names.contains("PTRequired")
            let flattened = names.contains("PTFlat")
            if flattened && path != nil {
                throw MacroExpansionErrorMessage("@PTFlat and @PTPath cannot be combined")
            }
            if required && defaultAttribute != nil {
                throw MacroExpansionErrorMessage("@PTRequired cannot be combined with @PTDefault")
            }
            if defaultAttribute != nil && defaultExpression == nil && !typeName.hasSuffix("?") {
                throw MacroExpansionErrorMessage("@PTDefault requires an argument or a property initializer for non-optional fields")
            }
            result.append(FieldInfo(name: name,
                                    typeName: typeName,
                                    wireKey: wireKey,
                                    path: path,
                                    defaultExpression: defaultExpression,
                                    required: required,
                                    flattened: flattened,
                                    lossy: names.contains("PTLossy"),
                                    stringified: names.contains("PTStringified"),
                                    annotations: names.filter { $0.hasPrefix("PT") },
                                    encoding: required ? ".required" : ".inherit",
                                    missing: defaultAttribute != nil ? ".useDefault" : ".useDefault",
                                    null: defaultAttribute != nil ? ".useDefault" : ".useNil",
                                    invalid: names.contains("PTLossy") ? ".useNil" : ".error"))
        }
        return result
    }

    private static func inferredTypeName(from expression: ExprSyntax?) -> String? {
        guard let expression else { return nil }
        let value = expression.trimmedDescription
        if value == "true" || value == "false" { return "Bool" }
        if value.hasPrefix("\"") && value.hasSuffix("\"") { return "String" }
        if value.contains(".") && Double(value) != nil { return "Double" }
        if Int(value) != nil { return "Int" }
        return nil
    }

    private static func codingKeyMap(from declaration: some DeclGroupSyntax) -> [String: String] {
        var result: [String: String] = [:]
        let source = declaration.memberBlock.description
        for line in source.split(whereSeparator: \.isNewline) {
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.hasPrefix("case "),
                  let equals = text.firstIndex(of: "="),
                  let firstQuote = text[equals...].firstIndex(of: "\""),
                  let lastQuote = text[...].lastIndex(of: "\""),
                  firstQuote < lastQuote else { continue }
            let property = text.dropFirst(5).prefix { $0 != " " && $0 != "=" && $0 != "," }
            guard !property.isEmpty else { continue }
            let valueStart = text.index(after: firstQuote)
            result[String(property)] = String(text[valueStart..<lastQuote])
        }
        return result
    }

    private static func firstStringArgument(_ attribute: AttributeSyntax) -> String? {
        let source = attribute.arguments?.description ?? ""
        guard let firstQuote = source.firstIndex(of: "\""),
              let lastQuote = source.lastIndex(of: "\""),
              firstQuote < lastQuote else { return nil }
        let value = source[source.index(after: firstQuote)..<lastQuote]
        return String(value)
    }

    private static func argumentSource(_ attribute: AttributeSyntax) -> String? {
        let source = attribute.arguments?.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !source.isEmpty else { return nil }
        if source.first == "(" && source.last == ")" {
            let start = source.index(after: source.startIndex)
            let end = source.index(before: source.endIndex)
            let value = source[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : String(value)
        }
        return source
    }

    static func escaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    static func schemaMember(typeName: String,
                             fields: [FieldInfo],
                             supportsMemberwiseInit: Bool) -> DeclSyntax {
        let decodeFields = fields.map {
            let decodeKeys = $0.wireKey == $0.name
                ? "[\"\(escaped($0.name))\"]"
                : "[\"\(escaped($0.wireKey))\", \"\(escaped($0.name))\"]"
            let path = $0.path.map { "try? PTJSONPath.parse(\"\(escaped($0))\")" } ?? "nil"
            let annotations = "[" + $0.annotations.map { "\"\(escaped($0))\"" }.joined(separator: ", ") + "]"
            return "PTModelFieldDescriptor(name: \"\(escaped($0.name))\", mapping: PTModelKeyMapping(decodeKeys: \(decodeKeys), encodeKey: \"\(escaped($0.wireKey))\"), encoding: \($0.encoding), missing: \($0.missing), null: \($0.null), invalid: \($0.invalid), required: \($0.required), flattened: \($0.flattened), path: \(path), annotations: Set(\(annotations)))"
        }.joined(separator: ", ")
        let encodedFields = fields.map {
            let decodeKeys = $0.wireKey == $0.name
                ? "[\"\(escaped($0.name))\"]"
                : "[\"\(escaped($0.wireKey))\", \"\(escaped($0.name))\"]"
            let path = $0.path.map { "try? PTJSONPath.parse(\"\(escaped($0))\")" } ?? "nil"
            let annotations = "[" + $0.annotations.map { "\"\(escaped($0))\"" }.joined(separator: ", ") + "]"
            let descriptor = "PTModelFieldDescriptor(name: \"\(escaped($0.name))\", mapping: PTModelKeyMapping(decodeKeys: \(decodeKeys), encodeKey: \"\(escaped($0.wireKey))\"), encoding: \($0.encoding), missing: \($0.missing), null: \($0.null), invalid: \($0.invalid), required: \($0.required), flattened: \($0.flattened), path: \(path), annotations: Set(\(annotations)))"
            let value = $0.stringified
                ? "try encoder.optionalJSONValue(PTStringifiedValue(model.\($0.name)))"
                : "try encoder.optionalJSONValue(model.\($0.name))"
            return "(\(descriptor), \(value))"
        }.joined(separator: ",\n                                                  ")
        // English: Structs can use their memberwise initializer for the direct scanner path; classes keep the Codable fallback.
        // Español: Las estructuras pueden usar su inicializador memberwise para el scanner directo; las clases conservan el fallback Codable.
        // 中文：结构体可以使用成员初始化器接入直接 Scanner，类继续使用 Codable 回退，避免猜测构造器签名。
        let directDecodeBody = fields.map { field in
            let source = "fields[\"\(escaped(field.wireKey))\"] ?? fields[\"\(escaped(field.name))\"]"
            let isOptional = field.typeName.hasSuffix("?")
            let decodeTypeName = isOptional
                ? String(field.typeName.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                : field.typeName
            let decodedValue: String
            if field.stringified {
                decodedValue = "try PTModelFoundationCodec.decodeStringified(\(decodeTypeName).self, from: raw, decoder: decoder)"
            } else if field.lossy,
                      let collection = lossyCollectionExpression(for: decodeTypeName) {
                decodedValue = "try \(collection)"
            } else if field.required || !isOptional {
                decodedValue = "try decoder.decode(\(decodeTypeName).self, from: raw)"
            } else {
                decodedValue = "try decoder.decodeOptional(\(decodeTypeName).self, from: raw)"
            }
            if let defaultExpression = field.defaultExpression {
                return "let \(field.name): \(field.typeName) = if let raw = \(source) { \(decodedValue) } else { \(defaultExpression) }"
            }
            if field.required || !isOptional {
                let missingValue = field.lossy && lossyCollectionExpression(for: decodeTypeName) != nil
                    ? "try decoder.decode(\(decodeTypeName).self, from: PTJSONValue.array([]))"
                    : "try decoder.decode(\(decodeTypeName).self, from: PTJSONValue.null)"
                return "let \(field.name): \(field.typeName) = if let raw = \(source) { \(decodedValue) } else { \(missingValue) }"
            }
            return "let \(field.name): \(field.typeName) = if let raw = \(source) { \(decodedValue) } else { nil }"
        }.joined(separator: "\n            ")
        let directDecodeArguments = fields.map { "\($0.name): \($0.name)" }.joined(separator: ", ")
        let directDecode = supportsMemberwiseInit ? """

        public static func ptDirectDecode(_ fields: [String: PTJSONValue], using decoder: PTModelDecoder) throws -> \(typeName)? {
            \(directDecodeBody)
            return \(typeName)(\(directDecodeArguments))
        }
        """ : ""
        let directPathFlag = supportsMemberwiseInit
            ? "public static var ptUsesDirectPath: Bool { true }"
            : "public static var ptUsesDirectPath: Bool { false }"
        return DeclSyntax(stringLiteral: """
        \(directPathFlag)

        public static var ptSchema: PTModelSchema<\(typeName)> {
            let fields: [PTModelFieldDescriptor] = [\(decodeFields)]
            return PTModelSchema<\(typeName)>(name: "\(escaped(typeName))",
                                       fields: fields,
                                       decode: { value, decoder in
                                           try decoder.decode(\(typeName).self,
                                                              from: PTModelSchemaSupport.normalizedInput(value, fields: fields))
                                       },
                                       encode: { model, encoder in
                                           try PTModelSchemaSupport.encodedOutput(encoder.object(fields: [
                                                  \(encodedFields)
                                           ]), fields: fields)
                                       })
        }

        public static func ptDirectFieldValues(_ model: \(typeName), using encoder: PTModelEncoder) throws -> [(PTModelFieldDescriptor, PTJSONValue?)]? {
            let fields = ptSchema.metadata.fields
            return [
                \(fields.enumerated().map {
                    let value = $0.element.stringified
                        ? "try encoder.optionalJSONValue(PTStringifiedValue(model.\($0.element.name)))"
                        : "try encoder.optionalJSONValue(model.\($0.element.name))"
                    return "(fields[\($0.offset)], \(value))"
                }.joined(separator: ",\n                "))
            ]
        }
        \(directDecode)
        """)
    }

    private static func lossyCollectionExpression(for typeName: String) -> String? {
        guard typeName.hasPrefix("[") && typeName.hasSuffix("]") else { return nil }
        let inner = String(typeName.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !inner.isEmpty else { return nil }
        if inner.hasSuffix("?") {
            let element = String(inner.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            return "decoder.decodeOptionalArray(\(element).self, from: raw, strategy: .preserveIndexAsNil)"
        }
        return "decoder.decodeArray(\(inner).self, from: raw, strategy: .skipInvalid)"
    }
}

public struct PTModelMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let typeName = PTMacroSourceBuilder.typeName(from: declaration) else {
            throw MacroExpansionErrorMessage("@PTModel can only be attached to a struct or class")
        }
        return [PTMacroSourceBuilder.schemaMember(typeName: typeName,
                                                  fields: try PTMacroSourceBuilder.fields(from: declaration),
                                                  supportsMemberwiseInit: declaration.as(StructDeclSyntax.self) != nil)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard PTMacroSourceBuilder.typeName(from: declaration) != nil else {
            throw MacroExpansionErrorMessage("@PTModel can only be attached to a struct or class")
        }
        return [try ExtensionDeclSyntax("extension \(type.trimmed): PTStaticModel {}")]
    }
}

public struct PTSubclassMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let typeName = PTMacroSourceBuilder.typeName(from: declaration) else {
            throw MacroExpansionErrorMessage("@PTSubclass can only be attached to a class")
        }
        return [PTMacroSourceBuilder.schemaMember(typeName: typeName,
                                                  fields: try PTMacroSourceBuilder.fields(from: declaration),
                                                  supportsMemberwiseInit: false)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@PTSubclass can only be attached to a class")
        }
        return [try ExtensionDeclSyntax("extension \(type.trimmed): PTStaticModel {}")]
    }
}

public struct PTFieldAnnotationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // English: Marker annotations only feed the enclosing PTModel macro; they emit no runtime declarations.
        // Español: Las anotaciones marcador solo alimentan a PTModel y no emiten declaraciones de runtime.
        // 中文：标记注解只供 PTModel 宏读取，不生成运行时声明。
        []
    }
}

@main
struct PToolsModelMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [PTModelMacro.self, PTSubclassMacro.self, PTFieldAnnotationMacro.self]
}
