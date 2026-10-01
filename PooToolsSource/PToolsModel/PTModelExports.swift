//
//  PTModelExports.swift
//
// English: Re-export the Foundation-only PTModel product as the high-level entry point.
// Español: Reexporta el producto PTModel basado solo en Foundation como entrada de alto nivel.
// 中文：将仅依赖 Foundation 的 PTModel 产品重新导出为高级入口。
//

#if SWIFT_PACKAGE
@_exported import PToolsModelCore
#endif

#if SWIFT_PACKAGE
// English: Generate a manual-schema-compatible PTStaticModel entry point for SwiftPM clients.
// Español: Genera un punto de entrada PTStaticModel compatible con esquemas manuales para clientes SwiftPM.
// 中文：为 SwiftPM 客户端生成兼容手写 Schema 的 PTStaticModel 入口。
@attached(member, names: arbitrary)
@attached(extension, conformances: PTStaticModel, names: arbitrary)
public macro PTModel() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTModelMacro")

// English: Generate the same static schema contract for a Codable subclass hierarchy.
// Español: Genera el mismo contrato de esquema estático para una jerarquía de subclases Codable.
// 中文：为 Codable 子类继承层级生成相同的静态 Schema 契约。
@attached(member, names: arbitrary)
@attached(extension, names: arbitrary)
public macro PTSubclass() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTSubclassMacro")

// English: Field annotations are intentionally marker macros; PTModel consumes their syntax into static descriptors.
// Español: Las anotaciones de campo son macros marcador; PTModel consume su sintaxis en descriptores estáticos.
// 中文：字段注解故意保持为标记宏，由 PTModel 将语法转换为静态描述器。
@attached(peer)
public macro PTKey(_ value: String) = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTPath(_ value: String) = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTDefault() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTDefault(_ value: Int) = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTDefault(_ value: Double) = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTDefault(_ value: Bool) = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTDefault(_ value: String) = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTRequired() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTIgnored() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTFlat() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTLossy() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTStringified() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTTransform() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTValidate() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTPolymorphic() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
@attached(peer)
public macro PTExtras() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTFieldAnnotationMacro")
#endif
