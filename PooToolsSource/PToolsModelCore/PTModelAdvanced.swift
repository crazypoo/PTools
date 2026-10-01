//
//  PTModelAdvanced.swift
//
// English: Foundation-only lifecycle, persistence, enum recovery, polymorphism, and extras contracts.
// Español: Contratos basados solo en Foundation para ciclo de vida, persistencia, enums, polimorfismo y extras.
// 中文：仅依赖 Foundation 的生命周期、持久化、枚举恢复、多态和扩展字段契约。
//

import Foundation

// English: Lifecycle hooks are value-based so they remain safe across actor boundaries.
// Español: Los hooks de ciclo de vida usan valores para mantenerse seguros entre actores.
// 中文：生命周期钩子只传递值类型，保证跨 actor 边界安全。
public protocol PTModelLifecycle: Sendable {
    static func ptWillDecode(_ value: PTJSONValue,
                             using decoder: PTModelDecoder) throws -> PTJSONValue
    static func ptDidDecode(_ value: PTJSONValue,
                            using decoder: PTModelDecoder) throws
    static func ptWillEncode(_ value: PTJSONValue,
                             using encoder: PTModelEncoder) throws -> PTJSONValue
    static func ptDidEncode(_ value: PTJSONValue,
                            using encoder: PTModelEncoder) throws
}

public extension PTModelLifecycle {
    static func ptWillDecode(_ value: PTJSONValue,
                             using decoder: PTModelDecoder) throws -> PTJSONValue { value }

    static func ptDidDecode(_ value: PTJSONValue,
                            using decoder: PTModelDecoder) throws {}

    static func ptWillEncode(_ value: PTJSONValue,
                             using encoder: PTModelEncoder) throws -> PTJSONValue { value }

    static func ptDidEncode(_ value: PTJSONValue,
                            using encoder: PTModelEncoder) throws {}
}

// English: Capture unknown object members without relying on reflection or mutable global state.
// Español: Captura miembros desconocidos sin reflexión ni estado global mutable.
// 中文：不依赖反射和可变全局状态，捕获对象中的未知字段。
public enum PTModelExtrasCodec {
    public static func capture(_ value: PTJSONValue,
                               knownKeys: Set<String>) throws -> PTExtras {
        guard case .object(let object) = value else {
            throw PTModelError.rootIsNotObject
        }
        return PTExtras(values: object.filter { !knownKeys.contains($0.key) })
    }

    public static func merge(_ value: PTJSONValue,
                             extras: PTExtras) throws -> PTJSONValue {
        guard case .object(let object) = value else {
            throw PTModelError.rootIsNotObject
        }
        return .object(extras.merged(into: object))
    }

    // English: Attach extras only to models that explicitly opt in; all other models remain unchanged.
    // Español: Adjunta extras solo a modelos que optan explícitamente; los demás modelos permanecen sin cambios.
    // 中文：只给显式选择的模型附加 extras，其余模型保持原样。
    public static func attach<Model: Sendable>(_ extras: PTExtras, to model: Model) -> Model {
        guard var storing = model as? any PTExtrasStoring else { return model }
        storing.ptExtras = extras
        return (storing as? Model) ?? model
    }
}

// English: Unknown enum cases are explicit instead of silently inventing invalid values.
// Español: Los casos desconocidos del enum son explícitos y no inventan valores inválidos.
// 中文：未知枚举值必须显式处理，不能静默生成无效值。
public protocol PTUnknownCaseRepresentable: RawRepresentable, Codable, Sendable
where RawValue: Codable & Sendable {
    static var ptUnknownCase: Self { get }
}

public enum PTEnumCodec {
    public static func decode<Value: PTUnknownCaseRepresentable>(
        _ type: Value.Type,
        from rawValue: Value.RawValue,
        unknownCase: Value? = nil
    ) throws -> Value {
        if let value = Value(rawValue: rawValue) { return value }
        if let unknownCase { return unknownCase }
        return Value.ptUnknownCase
    }

    public static func decode<Value: PTUnknownCaseRepresentable>(
        _ type: Value.Type,
        from value: PTJSONValue,
        decoder: PTModelDecoder = .init(),
        unknownCase: Value? = nil
    ) throws -> Value {
        let rawValue = try decoder.decode(Value.RawValue.self, from: value)
        return try decode(type, from: rawValue, unknownCase: unknownCase)
    }
}

// English: Registrations are immutable value data; callers can build one per schema and share it safely.
// Español: Los registros son datos valor inmutables; cada esquema puede compartirlos con seguridad.
// 中文：注册表是不可变值数据，每个 Schema 可安全复用自己的注册表。
public struct PTPolymorphicRegistry<Base: Sendable>: Sendable {
    private struct Entry: Sendable {
        let discriminator: String
        let decode: @Sendable (PTJSONValue, PTModelDecoder) throws -> Base
        let encode: @Sendable (Base, PTModelEncoder) throws -> PTJSONValue?
    }

    public let discriminatorKey: String
    private let entries: [Entry]

    public init(discriminatorKey: String = "type") {
        self.discriminatorKey = discriminatorKey
        self.entries = []
    }

    private init(discriminatorKey: String, entries: [Entry]) {
        self.discriminatorKey = discriminatorKey
        self.entries = entries
    }

    public func registering<Model: Codable & Sendable>(
        _ model: Model.Type,
        discriminator: String
    ) -> Self {
        let entry = Entry(
            discriminator: discriminator,
            decode: { value, decoder in
                let model = try decoder.decode(Model.self, from: value)
                guard let base = model as? Base else {
                    throw PTModelError.unsupportedFeature("\(Model.self) is not compatible with the polymorphic base")
                }
                return base
            },
            encode: { value, encoder in
                guard let model = value as? Model else { return nil }
                return try encoder.jsonValue(model)
            }
        )
        var updated = entries.filter { $0.discriminator != discriminator }
        updated.append(entry)
        return Self(discriminatorKey: discriminatorKey, entries: updated)
    }

    public func decode(_ value: PTJSONValue,
                       using decoder: PTModelDecoder = .init()) throws -> Base {
        guard case .object(let object) = value,
              case .string(let discriminator) = object[discriminatorKey],
              let entry = entries.first(where: { $0.discriminator == discriminator }) else {
            throw PTModelError.unsupportedFeature("Unknown polymorphic discriminator")
        }
        return try entry.decode(value, decoder)
    }

    // English: Resolve a discriminator at an explicit path before using the registry's stable wire key.
    // Español: Resuelve el discriminator en una ruta explícita antes de usar la clave estable del registro.
    // 中文：先从显式路径解析 discriminator，再复用注册表稳定的线路 key。
    public func decode(_ value: PTJSONValue,
                       descriptor: PTModelPolymorphicDescriptor,
                       using decoder: PTModelDecoder = .init()) throws -> Base {
        guard let discriminator = try value.value(at: descriptor.discriminatorPath) else {
            throw PTModelError.requiredValue(descriptor.discriminatorPath.description)
        }
        guard case .string(let type) = discriminator else {
            throw PTModelError.typeMismatch(expected: "string discriminator", actual: "non-string")
        }
        guard case .object(var object) = value else {
            throw PTModelError.rootIsNotObject
        }
        object[discriminatorKey] = .string(type)
        return try decode(.object(object), using: decoder)
    }

    public func encode(_ value: Base,
                       using encoder: PTModelEncoder = .init()) throws -> PTJSONValue {
        for entry in entries {
            if let encoded = try entry.encode(value, encoder) {
                guard case .object(var object) = encoded else {
                    throw PTModelError.typeMismatch(expected: "object", actual: "non-object")
                }
                object[discriminatorKey] = PTJSONValue.string(entry.discriminator)
                return .object(object)
            }
        }
        throw PTModelError.unsupportedFeature("No polymorphic encoder matched the value")
    }
}

// English: The actor owns file I/O and never shares mutable decoder state with callers.
// Español: El actor posee la E/S de archivos y nunca comparte estado mutable del decoder.
// 中文：actor 独占文件读写，不与调用方共享可变 decoder 状态。
public actor PTModelFileStore<Model: Codable & Sendable> {
    public let url: URL
    private let decoder: PTModelDecoder
    private let encoder: PTModelEncoder

    public init(url: URL,
                decoder: PTModelDecoder = .init(),
                encoder: PTModelEncoder = .init()) {
        self.url = url
        self.decoder = decoder
        self.encoder = encoder
    }

    public func load() throws -> Model? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try decoder.decode(Model.self, from: Data(contentsOf: url))
    }

    public func save(_ model: Model) throws {
        let data = try encoder.encode(model)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    public func remove() throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }
}
