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
                       using decoder: PTModelDecoder = .init(),
                       defaults: PTJSONValue? = nil) throws -> Model {
        let lifecycle = Model.self as? any PTModelLifecycle.Type
        let merged = defaults.map { PTModelDefaultMerge.merge(defaults: $0, with: value) } ?? value
        // English: Keep direct Schema decoding identical to the canonical static codec path.
        // Español: Mantiene el decode directo de Schema idéntico a la ruta estática canónica.
        // 中文：让直接 Schema 解码与规范静态 codec 路径保持一致。
        let normalized = PTModelSchemaSupport.normalizedInput(merged, fields: metadata.fields)
        let input = try lifecycle?.ptWillDecode(normalized, using: decoder) ?? normalized
        let model = try decodeClosure(input, decoder.scoped(to: .root))
        try lifecycle?.ptDidDecode(input, using: decoder)
        try validator?.validate(model,
                                context: PTModelValidationContext(path: .root,
                                                                    session: decoder.session))
        return model
    }

    public func encode(_ model: Model,
                       using encoder: PTModelEncoder = .init()) throws -> PTJSONValue {
        let value = try encodeClosure(model, encoder)
        let lifecycle = Model.self as? any PTModelLifecycle.Type
        let output = try lifecycle?.ptWillEncode(value, using: encoder) ?? value
        try lifecycle?.ptDidEncode(output, using: encoder)
        try validator?.validate(model,
                                context: PTModelValidationContext(path: .root,
                                                                    session: encoder.session))
        return output
    }

    public func jsonSchema() -> PTJSONValue {
        var properties: [String: PTJSONValue] = [:]
        for field in metadata.fields {
            var descriptor: [String: PTJSONValue] = [
                "type": .string("object"),
                "x-pt-field": .string(field.name),
                "x-pt-required": .bool(field.required),
                "x-pt-flattened": .bool(field.flattened)
            ]
            if let path = field.path {
                descriptor["x-pt-path"] = .string(path.description)
            }
            if !field.annotations.isEmpty {
                descriptor["x-pt-annotations"] = .array(field.annotations.sorted().map(PTJSONValue.string))
            }
            properties[field.mapping.encodeKey] = .object(descriptor)
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

    // English: Class hierarchies opt out until their superclass schema is explicitly composed.
    // Español: Las jerarquías de clases se excluyen hasta componer explícitamente el esquema de la superclase.
    // 中文：类继承层级在显式合并父类 Schema 前，必须退出直接 Fast Path。
    static var ptUsesDirectPath: Bool { get }

    // English: A generated or hand-written schema may construct a model directly from scanned fields.
    // Español: Un esquema generado o escrito a mano puede construir el modelo directamente desde campos escaneados.
    // 中文：生成或手写 Schema 可以直接根据扫描字段构造模型，避免再次建立完整对象树。
    static func ptDirectDecode(_ fields: [String: PTJSONValue],
                               using decoder: PTModelDecoder) throws -> Self?

    // English: Generated schemas may provide field values for direct byte writing; manual schemas keep the tree fallback.
    // Español: Los esquemas generados pueden entregar valores para escritura directa; los esquemas manuales conservan el fallback de árbol.
    // 中文：生成的 Schema 可以提供字段值用于直接写字节，手写 Schema 继续使用树编码回退。
    static func ptDirectFieldValues(_ model: Self,
                                    using encoder: PTModelEncoder) throws -> [(PTModelFieldDescriptor, PTJSONValue?)]?
}

public extension PTStaticModel {
    static var ptUsesDirectPath: Bool { true }

    static func ptDirectDecode(_ fields: [String: PTJSONValue],
                               using decoder: PTModelDecoder) throws -> Self? {
        nil
    }

    static func ptDirectFieldValues(_ model: Self,
                                    using encoder: PTModelEncoder) throws -> [(PTModelFieldDescriptor, PTJSONValue?)]? {
        nil
    }
}

// English: Normalize wire keys and annotated paths before Codable sees a macro-generated model.
// Español: Normaliza las claves de transporte y rutas anotadas antes de entregar el modelo a Codable.
// 中文：在 Codable 解码宏生成模型前，先统一转换网络字段名和注解路径。
public enum PTModelSchemaSupport {
    // English: Resolve one descriptor through its typed path and aliases before field recovery.
    // Español: Resuelve un descriptor mediante su ruta tipada y sus alias antes de la recuperación.
    // 中文：字段恢复前，统一按类型化路径和别名解析字段值。
    public static func value(for field: PTModelFieldDescriptor,
                             in object: PTJSONValue) throws -> PTJSONValue? {
        if let path = field.path {
            let prefix = Array(path.components.dropLast())
            for key in field.mapping.decodeKeys {
                let candidate = PTJSONPath(prefix + [.key(key)])
                if let value = try object.value(at: candidate) {
                    return value
                }
            }
            return nil
        }
        return try object.aliasedValue(using: field.mapping)
    }

    public static func normalizedInput(_ value: PTJSONValue,
                                       fields: [PTModelFieldDescriptor]) -> PTJSONValue {
        guard case .object(var object) = value else { return value }
        var consumedKeys = Set<String>()
        for field in fields {
            consumedKeys.formUnion(field.mapping.decodeKeys)
            if let path = field.path {
                var foundAtPath = false
                for candidate in pathCandidates(for: path, mapping: field.mapping) {
                    if let nested = try? value.value(at: candidate) {
                        object[field.name] = nested
                        foundAtPath = true
                        break
                    }
                }
                if foundAtPath { continue }
            }
            guard object[field.name] == nil,
                  let source = field.mapping.decodeKeys.lazy.compactMap({ object[$0] }).first else { continue }
            object[field.name] = source
        }

        // English: Rebuild flattened nested objects from keys not claimed by ordinary fields.
        // Español: Reconstruye objetos anidados aplanados con las claves no reclamadas por campos normales.
        // 中文：使用普通字段未消费的 key 重建 Flat 字段对应的嵌套对象。
        for field in fields where field.flattened {
            if object[field.name] != nil { continue }
            let nested = object.filter { key, _ in
                !consumedKeys.contains(key) && key != field.name
            }
            guard !nested.isEmpty else { continue }
            object[field.name] = .object(nested)
            for key in nested.keys {
                object.removeValue(forKey: key)
            }
        }
        return .object(object)
    }

    // English: Alias lookup at a path changes only the final key and keeps the parent path typed.
    // Español: La búsqueda de alias en una ruta solo cambia la clave final y conserva tipado el camino padre.
    // 中文：路径别名只替换末级 key，父路径仍由类型化路径控制。
    private static func pathCandidates(for path: PTJSONPath,
                                      mapping: PTModelKeyMapping) -> [PTJSONPath] {
        guard let last = path.components.last,
              case .key = last else { return [path] }
        let prefix = Array(path.components.dropLast())
        return mapping.decodeKeys.map { PTJSONPath(prefix + [.key($0)]) }
    }

    public static func encodedOutput(_ value: PTJSONValue,
                                     fields: [PTModelFieldDescriptor]) throws -> PTJSONValue {
        guard case .object(var object) = value else { return value }
        for field in fields {
            guard let path = field.path,
                  let fieldValue = object.removeValue(forKey: field.mapping.encodeKey) else { continue }
            guard case .object(let nestedObject) = try placing(fieldValue,
                                                                at: path,
                                                                in: .object(object)) else {
                throw PTModelError.rootIsNotObject
            }
            object = nestedObject
        }
        return .object(object)
    }

    private static func placing(_ replacement: PTJSONValue,
                                at path: PTJSONPath,
                                in value: PTJSONValue) throws -> PTJSONValue {
        guard let component = path.components.first else { return replacement }
        let tail = PTJSONPath(Array(path.components.dropFirst()))
        switch (component, value) {
        case (.key(let key), .object(var object)):
            let current = object[key] ?? .object([:])
            object[key] = try placing(replacement, at: tail, in: current)
            return .object(object)
        case (.index(let index), .array(var array)):
            guard array.indices.contains(index) else {
                throw PTModelError.patchFailed("Array index out of bounds: \(index)")
            }
            array[index] = try placing(replacement, at: tail, in: array[index])
            return .array(array)
        default:
            throw PTModelError.pathTypeMismatch(path.description)
        }
    }
}

public enum PTStaticCodec {
    // English: Expose the byte-scanner contract so generated schemas can opt into direct field dispatch incrementally.
    // Español: Expone el contrato de escaneo de bytes para que los esquemas generados adopten el dispatch directo gradualmente.
    // 中文：暴露字节 Scanner 契约，让生成的 Schema 可以渐进接入直接字段分发。
    public static func decodeFields(_ data: Data,
                                   fields: [PTModelFieldDescriptor],
                                   using decoder: PTModelDecoder = .init()) throws -> [String: PTJSONValue] {
        try PTStaticFieldDispatcher.decodeValues(from: data, fields: fields, decoder: decoder)
    }

    public static func decode<Model: PTStaticModel, Source: PTModelSource>(
        _ type: Model.Type,
        from source: Source,
        using decoder: PTModelDecoder = .init()
    ) throws -> Model {
        try decode(type,
                   from: source,
                   using: decoder,
                   migration: nil,
                   sourceVersion: nil,
                   defaults: nil)
    }

    // English: Decode with an optional migration chain before schema normalization and direct construction.
    // Español: Decodifica con una cadena de migración opcional antes de normalizar y construir directamente.
    // 中文：在 Schema 归一化和直接构造前，可选执行版本迁移链。
    public static func decode<Model: PTStaticModel, Source: PTModelSource>(
        _ type: Model.Type,
        from source: Source,
        using decoder: PTModelDecoder = .init(),
        migration: PTModelMigrationChain?,
        sourceVersion: Int? = nil,
        defaults: PTJSONValue? = nil
    ) throws -> Model {
        if migration == nil,
           defaults == nil,
           Model.ptUsesDirectPath,
           let data = source as? Data,
           canUseDirectObjectPath(for: Model.ptSchema.metadata.fields) {
            let values = try decodeFields(data,
                                          fields: Model.ptSchema.metadata.fields,
                                          using: decoder)
            if (Model.self as? any PTModelLifecycle.Type) == nil,
               let model = try Model.ptDirectDecode(values, using: decoder) {
                return model
            }
            return try Model.ptSchema.decode(from: .object(values), using: decoder)
        }

        let input: PTJSONValue
        if migration == nil,
           let string = source as? String,
           Model.ptUsesDirectPath,
           canUseDirectObjectPath(for: Model.ptSchema.metadata.fields) {
            let values = try decodeFields(Data(string.utf8),
                                          fields: Model.ptSchema.metadata.fields,
                                          using: decoder)
            if (Model.self as? any PTModelLifecycle.Type) == nil,
               let model = try Model.ptDirectDecode(values, using: decoder) {
                return model
            }
            input = .object(values)
        } else {
            input = try decoder.jsonValue(from: source)
        }

        var migrated = input
        if let migration {
            guard let sourceVersion = sourceVersion ?? migration.sourceVersion(in: input) else {
                throw PTModelError.migrationFailed("A source schema version is required")
            }
            migrated = try migration.migrate(input,
                                             from: sourceVersion,
                                             to: Model.ptSchema.metadata.version)
        }

        let merged = defaults.map { PTModelDefaultMerge.merge(defaults: $0, with: migrated) } ?? migrated
        let normalized = PTModelSchemaSupport.normalizedInput(merged,
                                                               fields: Model.ptSchema.metadata.fields)
        if Model.ptUsesDirectPath,
           (Model.self as? any PTModelLifecycle.Type) == nil,
           case .object(let object) = normalized,
           let model = try Model.ptDirectDecode(object, using: decoder) {
            return model
        }
        return try Model.ptSchema.decode(from: normalized, using: decoder)
    }

    // English: Capture unknown members alongside a decoded model for forward-compatible consumers.
    // Español: Captura miembros desconocidos junto al modelo decodificado para consumidores compatibles hacia delante.
    // 中文：解码模型的同时捕获未知字段，支持向前兼容。
    public static func decodeWithExtras<Model: PTStaticModel, Source: PTModelSource>(
        _ type: Model.Type,
        from source: Source,
        using decoder: PTModelDecoder = .init(),
        migration: PTModelMigrationChain? = nil,
        sourceVersion: Int? = nil,
        defaults: PTJSONValue? = nil
    ) throws -> (model: Model, extras: PTExtras) {
        let input = try decoder.jsonValue(from: source)
        var migrated = input
        if let migration {
            guard let sourceVersion = sourceVersion ?? migration.sourceVersion(in: input) else {
                throw PTModelError.migrationFailed("A source schema version is required")
            }
            migrated = try migration.migrate(input,
                                             from: sourceVersion,
                                             to: Model.ptSchema.metadata.version)
        }
        let knownKeys = Set(Model.ptSchema.metadata.fields.flatMap { field in
            field.mapping.decodeKeys + [field.mapping.encodeKey, field.name]
        })
        let extras = try PTModelExtrasCodec.capture(migrated, knownKeys: knownKeys)
        let model = try decode(type,
                               from: source,
                               using: decoder,
                               migration: migration,
                               sourceVersion: sourceVersion,
                               defaults: defaults)
        return (model, extras)
    }

    public static func encode<Model: PTStaticModel>(
        _ model: Model,
        using encoder: PTModelEncoder = .init()
    ) throws -> Data {
        if let provider = model as? any PTExtrasProviding,
           !provider.ptExtras.isEmpty {
            return try encode(model, extras: provider.ptExtras, using: encoder)
        }
        if !encoder.prettyPrinted,
           Model.ptUsesDirectPath,
           canUseDirectObjectPath(for: Model.ptSchema.metadata.fields),
           let fields = try Model.ptDirectFieldValues(model, using: encoder) {
            return try PTStaticJSONWriter.data(fields: fields, using: encoder)
        }
        return try Model.ptSchema.encode(model, using: encoder).jsonData(prettyPrinted: encoder.prettyPrinted,
                                                                         sortedKeys: encoder.sortedKeys || encoder.canonical,
                                                                         canonicalPolicy: encoder.canonical ? encoder.canonicalPolicy : nil)
    }

    // English: Merge captured extras at the final object boundary without changing the model's canonical schema.
    // Español: Fusiona los extras capturados en el límite final del objeto sin cambiar el esquema canónico.
    // 中文：在最终对象边界合并已捕获的 extras，不改变模型的规范 Schema。
    public static func encode<Model: PTStaticModel>(
        _ model: Model,
        extras: PTExtras,
        using encoder: PTModelEncoder = .init()
    ) throws -> Data {
        let value = try PTModelExtrasCodec.merge(Model.ptSchema.encode(model, using: encoder), extras: extras)
        return try value.jsonData(prettyPrinted: encoder.prettyPrinted,
                                  sortedKeys: encoder.sortedKeys || encoder.canonical,
                                  canonicalPolicy: encoder.canonical ? encoder.canonicalPolicy : nil)
    }

    // English: Stream one static model directly to a sink when the generated schema exposes field values.
    // Español: Envía un modelo estático directamente a un sink cuando el esquema generado expone sus valores.
    // 中文：当生成的 Schema 提供字段值时，直接把单个静态模型写入 Sink。
    public static func write<Model: PTStaticModel, Sink: PTJSONByteSink>(
        _ model: Model,
        using encoder: PTModelEncoder = .init(),
        to sink: inout Sink
    ) throws {
        if !encoder.prettyPrinted,
           Model.ptUsesDirectPath,
           canUseDirectObjectPath(for: Model.ptSchema.metadata.fields),
           let fields = try Model.ptDirectFieldValues(model, using: encoder) {
            try PTStaticJSONWriter.write(fields: fields, using: encoder, to: &sink)
            return
        }
        try sink.write(try encode(model, using: encoder))
    }

    public static func jsonValue<Model: PTStaticModel>(
        _ model: Model,
        using encoder: PTModelEncoder = .init()
    ) throws -> PTJSONValue {
        try Model.ptSchema.encode(model, using: encoder)
    }

    private static func canUseDirectObjectPath(for fields: [PTModelFieldDescriptor]) -> Bool {
        fields.allSatisfy { $0.path == nil && !$0.flattened }
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
