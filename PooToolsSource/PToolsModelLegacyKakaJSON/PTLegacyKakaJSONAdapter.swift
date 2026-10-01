//
//  PTLegacyKakaJSONAdapter.swift
//
// English: Keep KakaJSON at an explicit optional compatibility boundary.
// Español: Mantiene KakaJSON en un límite de compatibilidad opcional y explícito.
// 中文：将 KakaJSON 保持在显式可选的兼容边界内。
//

import Foundation
import KakaJSON

public enum PTLegacyKakaJSONAdapter {
    // English: Keep legacy JSON operations behind this adapter so application targets never import KakaJSON directly.
    // Español: Mantiene las operaciones JSON heredadas detrás de este adaptador para que las aplicaciones no importen KakaJSON directamente.
    // 中文：将旧版 JSON 操作集中在适配器中，业务 Target 不再直接导入 KakaJSON。
    public static func decode<Model: Convertible>(_ type: Model.Type,
                                                   string: String) -> Model? {
        KakaJSON.model(from: string, type)
    }

    public static func decode<Model: Convertible>(_ type: Model.Type,
                                                   data: Data) throws -> Model {
        guard let model = KakaJSON.model(from: data, type) else {
            throw PTLegacyKakaJSONError.decodeFailed
        }
        return model
    }

    // English: Array and object helpers preserve the old wire shape during the staged migration.
    // Español: Los helpers de arrays y objetos conservan la forma antigua durante la migración por etapas.
    // 中文：数组和对象辅助方法在分阶段迁移期间保留旧 JSON 形状。
    public static func decodeArray<Model: Convertible>(_ type: Model.Type,
                                                       string: String) -> [Model]? {
        KakaJSON.modelArray(from: string, type)
    }

    public static func encode(_ value: Any, prettyPrinted: Bool = false) -> String? {
        JSONString(from: value, prettyPrinted: prettyPrinted)
    }

    public static func object(_ value: Any) -> [String: Any] {
        if let model = value as? Convertible { return JSONObject(from: model) }
        return value as? [String: Any] ?? [:]
    }

    // English: Expose alias registration without leaking KakaJSON property types to application code.
    // Español: Expone el registro de alias sin filtrar los tipos de propiedades de KakaJSON al código de la aplicación.
    // 中文：提供字段别名注册，但不把 KakaJSON 的属性类型泄漏到业务代码。
    public static func setModelKey(for type: Any.Type,
                                   transform: @escaping (String) -> String) {
        guard let modelType = type as? Convertible.Type else { return }
        ConvertibleConfig.setModelKey(for: modelType) { property in
            transform(property.name)
        }
    }

    public static func decode(_ type: Any.Type, data: Data) throws -> Any {
        guard let modelType = type as? Convertible.Type,
              let model = KakaJSON.model(from: data, type: modelType) else {
            throw PTLegacyKakaJSONError.decodeFailed
        }
        return model
    }

    // English: Type-erased array decoding keeps legacy collection models behind the same boundary.
    // Español: La decodificación de arrays con tipo borrado mantiene los modelos de colección heredados en el mismo límite.
    // 中文：类型擦除的数组解码让旧集合模型也统一留在同一兼容边界内。
    public static func decodeArray(_ type: Any.Type, string: String) -> [Any] {
        guard let modelType = type as? Convertible.Type else {
            return []
        }
        return KakaJSON.modelArray(from: string, type: modelType).map { $0 }
    }
}

public enum PTLegacyKakaJSONError: Error, LocalizedError, Sendable {
    case decodeFailed

    public var errorDescription: String? {
        "KakaJSON compatibility decoding failed."
    }
}
