//
//  PTModelFeatures.swift
//
// English: Foundation-only feature contracts for stringified values, Any bridging, transformers, and defaults.
// Español: Contratos de funciones basados solo en Foundation para valores stringified, puente Any, transformers y defaults.
// 中文：仅依赖 Foundation 的字符串化值、Any 桥接、转换器和默认值功能契约。
//

import Foundation

// English: Bridge untyped Foundation input at the compatibility boundary, never inside the static codec.
// Español: Convierte la entrada Foundation sin tipo en el límite de compatibilidad, nunca dentro del codec estático.
// 中文：只在兼容边界转换无类型 Foundation 输入，不让裸 Any 进入静态 codec。
public enum PTAnyJSONValueBridge {
    public static func jsonValue(_ value: Any) throws -> PTJSONValue {
        if let value = value as? PTJSONValue { return value }
        if value is NSNull { return .null }
        if let value = value as? String { return .string(value) }
        if let value = value as? Bool { return .bool(value) }
        if let value = value as? Int { return .number(try PTJSONNumber(String(value))) }
        if let value = value as? Int64 { return .number(try PTJSONNumber(String(value))) }
        if let value = value as? UInt64 { return .number(try PTJSONNumber(String(value))) }
        if let value = value as? Decimal {
            return .number(try PTJSONNumber(NSDecimalNumber(decimal: value).stringValue))
        }
        if let value = value as? Double {
            guard value.isFinite else { throw PTModelError.conversionFailed("Non-finite Double is not JSON") }
            return .number(try PTJSONNumber(String(value)))
        }
        if let value = value as? Float {
            guard value.isFinite else { throw PTModelError.conversionFailed("Non-finite Float is not JSON") }
            return .number(try PTJSONNumber(String(value)))
        }
        if let value = value as? [Any] {
            return .array(try value.map(jsonValue))
        }
        if let value = value as? [String: Any] {
            var result: [String: PTJSONValue] = [:]
            result.reserveCapacity(value.count)
            for (key, item) in value {
                result[key] = try jsonValue(item)
            }
            return .object(result)
        }
        if let value = value as? NSArray {
            return try jsonValue(value.compactMap { $0 })
        }
        if let value = value as? NSDictionary {
            var result: [String: PTJSONValue] = [:]
            result.reserveCapacity(value.count)
            for (key, item) in value {
                guard let key = key as? String else {
                    throw PTModelError.conversionFailed("NSDictionary keys must be String")
                }
                result[key] = try jsonValue(item as Any)
            }
            return .object(result)
        }
        throw PTModelError.unsupportedSource(String(reflecting: type(of: value)))
    }
}

// English: A typed wrapper stores a Codable value as one JSON string for legacy payload contracts.
// Español: Este wrapper guarda un valor Codable como una cadena JSON para contratos heredados.
// 中文：该包装器把 Codable 值编码成单个 JSON 字符串，兼容旧接口协议。
public struct PTStringifiedValue<Value: Codable & Sendable>: Codable, Sendable {
    public let value: Value

    public init(_ value: Value) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.value = try PTModelDecoder(policy: .strict).decode(Value.self, from: Data(string.utf8))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = try PTModelEncoder(canonical: true).encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw PTModelError.conversionFailed("Stringified JSON is not UTF-8")
        }
        try container.encode(string)
    }
}

// English: A transformer keeps custom value conversion typed and bidirectional at the schema boundary.
// Español: Un transformer mantiene tipada y bidireccional la conversión personalizada en el límite del esquema.
// 中文：转换器在 Schema 边界提供类型安全的双向自定义转换。
public struct PTModelValueTransformer<Value: Sendable>: Sendable {
    public let decode: @Sendable (PTJSONValue, PTModelDecoder) throws -> Value
    public let encode: @Sendable (Value, PTModelEncoder) throws -> PTJSONValue

    public init(decode: @escaping @Sendable (PTJSONValue, PTModelDecoder) throws -> Value,
                encode: @escaping @Sendable (Value, PTModelEncoder) throws -> PTJSONValue) {
        self.decode = decode
        self.encode = encode
    }
}

// English: Recursive default merge fills absent nested members while incoming payload values always win.
// Español: La fusión recursiva completa miembros anidados ausentes y siempre prioriza el payload entrante.
// 中文：递归默认合并补齐缺少的嵌套字段，并始终让输入 payload 覆盖默认值。
public enum PTModelDefaultMerge {
    public static func merge(defaults: PTJSONValue,
                             with incoming: PTJSONValue) -> PTJSONValue {
        guard case .object(let defaultObject) = defaults,
              case .object(let incomingObject) = incoming else {
            return incoming
        }
        var result = defaultObject
        for (key, value) in incomingObject {
            if let existing = result[key] {
                result[key] = merge(defaults: existing, with: value)
            } else {
                result[key] = value
            }
        }
        return .object(result)
    }
}

// English: The resolver protocol leaves discriminator ownership with the application while keeping the core typed.
// Español: El protocolo deja la propiedad del discriminator a la aplicación y mantiene tipado el núcleo.
// 中文：解析器协议把 discriminator 的归属留给业务，同时保持 Core 类型安全。
public protocol PTModelTypeResolver: Sendable {
    func resolveType(discriminator: PTJSONValue,
                     context: PTModelContext) throws -> any PTStaticModel.Type
}

public struct PTModelPolymorphicDescriptor: Sendable, Codable, Hashable, Equatable {
    public let discriminatorPath: PTJSONPath
    public let encodeDiscriminatorKey: String

    public init(discriminatorPath: PTJSONPath = .root,
                encodeDiscriminatorKey: String = "type") {
        self.discriminatorPath = discriminatorPath
        self.encodeDiscriminatorKey = encodeDiscriminatorKey
    }
}
