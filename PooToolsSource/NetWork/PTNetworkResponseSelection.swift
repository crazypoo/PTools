//
//  PTNetworkResponseSelection.swift
//  PooTools
//
//  English: Keep response path selection and its diagnostics outside the transport facade.
//  Español: Mantiene la selección de rutas y sus diagnósticos fuera de la fachada de transporte.
//  中文：将响应路径选择及其诊断从 Network 传输门面中独立出来。
//

import Foundation
#if SWIFT_PACKAGE
import PToolsModelCore
#endif

struct PTNetworkResponseSelection: Sendable {
    let path: PTJSONPath
    let value: PTJSONValue

    static func select(root: PTJSONValue,
                       path: PTJSONPath) throws -> PTNetworkResponseSelection {
        do {
            return PTNetworkResponseSelection(path: path,
                                               value: try root.requiredValue(at: path))
        } catch let error as PTModelError {
            switch error {
            case .requiredValue:
                throw PTNetworkDecodeError.modelPathNotFound(path)
            case .pathTypeMismatch:
                throw PTNetworkDecodeError.modelPathTypeMismatch(path: path,
                                                                   expected: "JSON value",
                                                                   actual: "incompatible path component")
            default:
                throw error
            }
        }
    }
}

extension PTJSONValue {
    // English: Keep diagnostics value-typed so path failures never expose Foundation's dynamic JSON objects.
    // Español: Mantiene los diagnósticos tipados para que los fallos de ruta nunca expongan objetos JSON dinámicos de Foundation.
    // 中文：诊断信息保持值类型，路径失败不会暴露 Foundation 动态 JSON 对象。
    var ptNetworkTypeName: String {
        switch self {
        case .null: return "null"
        case .bool: return "Boolean"
        case .number: return "Number"
        case .string: return "String"
        case .array: return "Array"
        case .object: return "Object"
        }
    }
}
