//
//  PTCoreCodable.swift
//  PToolsCore
//
// English: Foundation-only JSON values for typed boundaries that cannot carry Any.
// Español: Valores JSON basados solo en Foundation para límites tipados que no pueden transportar Any.
// 中文：为不能传递 Any 的类型化边界提供仅依赖 Foundation 的 JSON 值类型。
//

import Foundation

// English: Preserve JSON shape without exposing Foundation containers or dynamic dictionaries.
// Español: Conserva la forma JSON sin exponer contenedores de Foundation ni diccionarios dinámicos.
// 中文：保留 JSON 结构，同时不暴露 Foundation 容器或动态字典。
public enum PTJSONValue: Sendable, Equatable, Codable {
    case null
    case bool(Bool)
    case integer(Int64)
    case number(Double)
    case string(String)
    case array([PTJSONValue])
    case object([String: PTJSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([PTJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: PTJSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.typeMismatch(
                PTJSONValue.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Unsupported JSON value")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}
