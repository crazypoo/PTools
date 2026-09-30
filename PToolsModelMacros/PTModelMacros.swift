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

private enum PTMacroSourceBuilder {
    static func typeName(from declaration: some DeclGroupSyntax) -> String? {
        if let declaration = declaration.as(StructDeclSyntax.self) {
            return declaration.name.text
        }
        if let declaration = declaration.as(ClassDeclSyntax.self) {
            return declaration.name.text
        }
        return nil
    }

    static func fields(from declaration: some DeclGroupSyntax) -> [String] {
        declaration.memberBlock.members.compactMap { member in
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  let binding = variable.bindings.first,
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  binding.accessorBlock == nil else {
                return nil
            }
            return name
        }
    }

    static func escaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    static func schemaMember(typeName: String, fields: [String]) -> DeclSyntax {
        let descriptors = fields.map {
            "PTModelFieldDescriptor(name: \"\(escaped($0))\")"
        }.joined(separator: ", ")
        let encodedFields = fields.map {
            "(PTModelFieldDescriptor(name: \"\(escaped($0))\"), try encoder.optionalJSONValue(model.\($0)))"
        }.joined(separator: ",\n                                                  ")
        return DeclSyntax(stringLiteral: """
        public static var ptSchema: PTModelSchema<\(typeName)> {
            PTModelSchema<\(typeName)>(name: "\(escaped(typeName))",
                                       fields: [\(descriptors)],
                                       decode: { value, decoder in
                                           try decoder.decode(\(typeName).self, from: value)
                                       },
                                       encode: { model, encoder in
                                           try encoder.object(fields: [
                                                  \(encodedFields)
                                           ])
                                       })
        }
        """)
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
                                                  fields: PTMacroSourceBuilder.fields(from: declaration))]
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
                                                  fields: PTMacroSourceBuilder.fields(from: declaration))]
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

@main
struct PToolsModelMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [PTModelMacro.self, PTSubclassMacro.self]
}
