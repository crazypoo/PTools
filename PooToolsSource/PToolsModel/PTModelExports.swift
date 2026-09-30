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
@attached(member, names: named(ptSchema))
@attached(extension, conformances: PTStaticModel)
public macro PTModel() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTModelMacro")

// English: Generate the same static schema contract for a Codable subclass hierarchy.
// Español: Genera el mismo contrato de esquema estático para una jerarquía de subclases Codable.
// 中文：为 Codable 子类继承层级生成相同的静态 Schema 契约。
@attached(member, names: named(ptSchema))
@attached(extension, conformances: PTStaticModel)
public macro PTSubclass() = #externalMacro(module: "PToolsModelMacroPlugin", type: "PTSubclassMacro")
#endif
