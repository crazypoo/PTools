//
//  PTModelSchema.swift
//
// English: Manual static schemas provide the canonical PTModel path without reflection or third-party codecs.
// Español: Los esquemas estáticos manuales proporcionan la ruta canónica PTModel sin reflexión ni codecs de terceros.
// 中文：手写静态 Schema 提供不依赖反射和第三方 codec 的 PTModel 主路径。
//

import Foundation

public struct PTModelField<Model: Sendable, Value: Sendable>: Sendable {
    public let descriptor: PTModelFieldDescriptor
    private let getter: @Sendable (Model) -> Value

    public init(descriptor: PTModelFieldDescriptor,
                getter: @escaping @Sendable (Model) -> Value) {
        self.descriptor = descriptor
        self.getter = getter
    }

    public func value(from model: Model) -> Value {
        getter(model)
    }
}

public struct PTModelSchemaMetadata: Sendable, Codable, Hashable, Equatable {
    public let name: String
    public let version: Int
    public let fields: [PTModelFieldDescriptor]

    public init(name: String,
                version: Int = 1,
                fields: [PTModelFieldDescriptor] = []) {
        self.name = name
        self.version = max(1, version)
        self.fields = fields
    }
}

public struct PTModelSchema<Model: Codable & Sendable>: Sendable {
    public let metadata: PTModelSchemaMetadata
    private let decodeClosure: @Sendable (PTJSONValue, PTModelDecoder) throws -> Model
    private let encodeClosure: @Sendable (Model, PTModelEncoder) throws -> PTJSONValue
    private let validator: PTModelValidator<Model>?

    public init(name: String = String(reflecting: Model.self),
                version: Int = 1,
                fields: [PTModelFieldDescriptor] = [],
                decode: @escaping @Sendable (PTJSONValue, PTModelDecoder) throws -> Model,
                encode: @escaping @Sendable (Model, PTModelEncoder) throws -> PTJSONValue,
                validator: PTModelValidator<Model>? = nil) {
        self.metadata = PTModelSchemaMetadata(name: name, version: version, fields: fields)
        self.decodeClosure = decode
        self.encodeClosure = encode
        self.validator = validator
    }

    public func decode(from value: PTJSONValue,
                       using decoder: PTModelDecoder = .init()) throws -> Model {
        let model = try decodeClosure(value, decoder.scoped(to: .root))
        try validator?.validate(model,
                                context: PTModelValidationContext(path: .root,
                                                                    session: decoder.session))
        return model
    }

    public func encode(_ model: Model,
                       using encoder: PTModelEncoder = .init()) throws -> PTJSONValue {
        let value = try encodeClosure(model, encoder)
        try validator?.validate(model,
                                context: PTModelValidationContext(path: .root,
                                                                    session: encoder.session))
        return value
    }

    public func jsonSchema() -> PTJSONValue {
        var properties: [String: PTJSONValue] = [:]
        for field in metadata.fields {
            properties[field.mapping.encodeKey] = .object([
                "type": .string("object"),
                "x-pt-field": .string(field.name),
                "x-pt-required": .bool(field.required),
                "x-pt-flattened": .bool(field.flattened)
            ])
        }
        let required = metadata.fields.filter(\.required).map { PTJSONValue.string($0.mapping.encodeKey) }
        var result: [String: PTJSONValue] = [
            "$schema": .string("https://json-schema.org/draft/2020-12/schema"),
            "title": .string(metadata.name),
            "type": .string("object"),
            "properties": .object(properties)
        ]
        if let version = try? PTJSONNumber(String(metadata.version)) {
            result["x-pt-schema-version"] = .number(version)
        }
        if !required.isEmpty { result["required"] = .array(required) }
        return .object(result)
    }
}

public protocol PTStaticModel: Codable & Sendable {
    static var ptSchema: PTModelSchema<Self> { get }
}

public enum PTStaticCodec {
    public static func decode<Model: PTStaticModel, Source: PTModelSource>(
        _ type: Model.Type,
        from source: Source,
        using decoder: PTModelDecoder = .init()
    ) throws -> Model {
        try Model.ptSchema.decode(from: decoder.jsonValue(from: source), using: decoder)
    }

    public static func encode<Model: PTStaticModel>(
        _ model: Model,
        using encoder: PTModelEncoder = .init()
    ) throws -> Data {
        try Model.ptSchema.encode(model, using: encoder).jsonData(prettyPrinted: encoder.prettyPrinted,
                                                                  sortedKeys: encoder.sortedKeys || encoder.canonical)
    }

    public static func jsonValue<Model: PTStaticModel>(
        _ model: Model,
        using encoder: PTModelEncoder = .init()
    ) throws -> PTJSONValue {
        try Model.ptSchema.encode(model, using: encoder)
    }
}

public extension PTModelNamespace {
    func staticModel<Source: PTModelSource>(from source: Source,
                                            using decoder: PTModelDecoder = .init()) throws -> Model
    where Model: PTStaticModel {
        try PTStaticCodec.decode(Model.self, from: source, using: decoder)
    }

    func staticJSONData(using encoder: PTModelEncoder = .init()) throws -> Data
    where Model: PTStaticModel {
        guard let value else { throw PTModelError.invalidInput }
        return try PTStaticCodec.encode(value, using: encoder)
    }
}

// English: FNV-1a keeps schema key dispatch deterministic without unsafe runtime metadata.
// Español: FNV-1a mantiene determinista el despacho de claves del esquema sin metadatos runtime inseguros.
// 中文：FNV-1a 在不使用不安全运行时元数据的前提下提供稳定的 Schema key dispatch。
public enum PTStableKeyHash {
    public static func hash(_ key: String) -> UInt64 {
        var result: UInt64 = 14_695_981_039_346_656_037
        for byte in key.utf8 {
            result ^= UInt64(byte)
            result &*= 1_099_511_628_211
        }
        return result
    }
}
