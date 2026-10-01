//
//  PTModelRuntime.swift
//
// English: Patch, diff, clone, conversion, extras, and schema migration primitives for PTModel.
// Español: Primitivas de parche, diff, clonación, conversión, extras y migración de esquemas para PTModel.
// 中文：PTModel 的 Patch、Diff、Clone、模型转换、未知字段和 Schema 迁移基础能力。
//

import Foundation

public enum PTModelPatchOperation: Sendable, Codable, Hashable, Equatable {
    case set(path: PTJSONPath, value: PTJSONValue)
    case remove(path: PTJSONPath)
    case merge(path: PTJSONPath, value: PTJSONValue)
}

public struct PTModelPatch: Sendable, Codable, Hashable, Equatable {
    public let operations: [PTModelPatchOperation]

    public init(operations: [PTModelPatchOperation] = []) {
        self.operations = operations
    }

    public var isEmpty: Bool { operations.isEmpty }

    public func applying(to value: PTJSONValue) throws -> PTJSONValue {
        var result = value
        for operation in operations {
            switch operation {
            case .set(let path, let replacement):
                result = try result.replacingValue(at: path, with: replacement)
            case .remove(let path):
                result = try result.removingValue(at: path)
            case .merge(let path, let replacement):
                guard case .object(let incoming) = replacement else {
                    throw PTModelError.patchFailed("Merge requires an object value")
                }
                let existing = try result.value(at: path)
                guard case .object(let current)? = existing else {
                    throw PTModelError.patchFailed("Merge path is not an object: \(path.description)")
                }
                result = try result.replacingValue(at: path, with: .object(current.merging(incoming) { _, new in new }))
            }
        }
        return result
    }

    public func applying<Model: Codable & Sendable>(to model: Model,
                                                    decoder: PTModelDecoder = .init(),
                                                    encoder: PTModelEncoder = .init()) throws -> Model {
        let source = try encoder.jsonValue(model)
        let patched = try applying(to: source)
        return try decoder.decode(Model.self, from: patched)
    }
}

public extension PTModelPatch {
    // English: Missing means "no update"; null and value remain explicit patch operations.
    // Español: Missing significa «sin actualización»; null y value siguen siendo operaciones explícitas.
    // 中文：missing 表示“不更新”；null 和 value 才转换为显式 Patch 操作。
    static func fromPresence<Value: Codable & Sendable & Equatable>(
        _ presence: PTPresence<Value>,
        at path: PTJSONPath,
        encoder: PTModelEncoder = .init()
    ) throws -> PTModelPatch {
        switch presence {
        case .missing:
            return PTModelPatch()
        case .null:
            return PTModelPatch(operations: [.set(path: path, value: .null)])
        case .value(let value):
            return PTModelPatch(operations: [.set(path: path, value: try encoder.jsonValue(value))])
        }
    }

    static func fromPresence<Value: Codable & Sendable & Equatable>(
        _ presence: PTPresence<Value>,
        key: String,
        encoder: PTModelEncoder = .init()
    ) throws -> PTModelPatch {
        try fromPresence(presence, at: PTJSONPath([.key(key)]), encoder: encoder)
    }
}

public enum PTModelDiff {
    public static func make(from old: PTJSONValue,
                            to new: PTJSONValue) -> PTModelPatch {
        var operations: [PTModelPatchOperation] = []
        appendDiff(from: old, to: new, path: .root, operations: &operations)
        return PTModelPatch(operations: operations)
    }

    public static func make<Model: Codable & Sendable>(from old: Model,
                                                       to new: Model,
                                                       encoder: PTModelEncoder = .init()) throws -> PTModelPatch {
        make(from: try encoder.jsonValue(old), to: try encoder.jsonValue(new))
    }

    private static func appendDiff(from old: PTJSONValue,
                                   to new: PTJSONValue,
                                   path: PTJSONPath,
                                   operations: inout [PTModelPatchOperation]) {
        guard old != new else { return }
        guard case .object(let oldObject) = old,
              case .object(let newObject) = new else {
            operations.append(.set(path: path, value: new))
            return
        }

        let keys = Set(oldObject.keys).union(newObject.keys).sorted()
        for key in keys {
            let childPath = path.appending(.key(key))
            switch (oldObject[key], newObject[key]) {
            case (nil, .some(let value)):
                operations.append(.set(path: childPath, value: value))
            case (.some, nil):
                operations.append(.remove(path: childPath))
            case (.some(let oldValue), .some(let newValue)):
                appendDiff(from: oldValue, to: newValue, path: childPath, operations: &operations)
            case (nil, nil):
                break
            }
        }
    }
}

public enum PTModelClone {
    public static func clone<Model: Codable & Sendable>(
        _ model: Model,
        decoder: PTModelDecoder = .init(),
        encoder: PTModelEncoder = .init()
    ) throws -> Model {
        try decoder.decode(Model.self, from: encoder.jsonValue(model))
    }
}

public enum PTModelConverter {
    public static func convert<Source: Codable & Sendable, Destination: Codable & Sendable>(
        _ source: Source,
        to: Destination.Type,
        decoder: PTModelDecoder = .init(),
        encoder: PTModelEncoder = .init()
    ) throws -> Destination {
        try decoder.decode(Destination.self, from: encoder.jsonValue(source))
    }
}

public enum PTModelUpdater {
    public static func update<Model: Codable & Sendable>(
        _ model: Model,
        with patch: PTModelPatch,
        decoder: PTModelDecoder = .init(),
        encoder: PTModelEncoder = .init()
    ) throws -> Model {
        try patch.applying(to: model, decoder: decoder, encoder: encoder)
    }
}

// English: Extras preserve unknown object members without forcing every model to depend on a reflection runtime.
// Español: Extras conserva miembros desconocidos sin obligar a cada modelo a depender de reflexión runtime.
// 中文：Extras 保存未知对象字段，不要求所有模型依赖运行时反射。
public struct PTExtras: Sendable, Codable, Hashable, Equatable {
    public private(set) var values: [String: PTJSONValue]

    public init(values: [String: PTJSONValue] = [:]) {
        self.values = values
    }

    public subscript(key: String) -> PTJSONValue? {
        get { values[key] }
        set { values[key] = newValue }
    }

    public var isEmpty: Bool { values.isEmpty }

    public func merged(into object: [String: PTJSONValue]) -> [String: PTJSONValue] {
        object.merging(values) { _, extra in extra }
    }
}

public protocol PTExtrasProviding: Sendable {
    var ptExtras: PTExtras { get }
}

// English: Models that opt in to automatic extras capture expose one mutable value slot, never a shared global bag.
// Español: Los modelos que optan por capturar extras exponen un único valor mutable, nunca un contenedor global compartido.
// 中文：选择自动捕获 extras 的模型只暴露一个可变值槽位，不使用共享全局容器。
public protocol PTExtrasStoring: PTExtrasProviding {
    var ptExtras: PTExtras { get set }
}

public enum PTModelDowngradePolicy: String, Sendable, Codable {
    case reject
    case bestEffort
}

public struct PTModelMigration: Sendable {
    public let fromVersion: Int
    public let toVersion: Int
    private let transform: @Sendable (PTJSONValue) throws -> PTJSONValue

    public init(fromVersion: Int,
                toVersion: Int,
                transform: @escaping @Sendable (PTJSONValue) throws -> PTJSONValue) {
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.transform = transform
    }

    public func apply(to value: PTJSONValue) throws -> PTJSONValue {
        try transform(value)
    }
}

public struct PTModelMigrationChain: Sendable {
    public let migrations: [PTModelMigration]

    public init(_ migrations: [PTModelMigration] = []) {
        self.migrations = migrations.sorted {
            if $0.fromVersion == $1.fromVersion { return $0.toVersion < $1.toVersion }
            return $0.fromVersion < $1.fromVersion
        }
    }

    // English: Read an optional persisted schema version without forcing callers to know the transport spelling.
    // Español: Lee una versión de esquema persistida opcional sin obligar al llamador a conocer la clave del transporte.
    // 中文：兼容常见传输字段读取持久化 Schema 版本，调用方无需关心具体字段名。
    public func sourceVersion(in value: PTJSONValue) -> Int? {
        guard case .object(let object) = value else { return nil }
        for key in ["schemaVersion", "_schemaVersion", "version"] {
            guard let value = object[key] else { continue }
            switch value {
            case .number(let number):
                if let integer = number.int64Value { return Int(integer) }
            case .string(let string):
                if let integer = Int(string) { return integer }
            default:
                continue
            }
        }
        return nil
    }

    public func migrate(_ value: PTJSONValue,
                        from sourceVersion: Int,
                        to destinationVersion: Int,
                        downgradePolicy: PTModelDowngradePolicy = .reject) throws -> PTJSONValue {
        guard sourceVersion != destinationVersion else { return value }
        if sourceVersion > destinationVersion {
            guard downgradePolicy == .bestEffort else {
                throw PTModelError.migrationFailed("Downgrade is not supported")
            }
            return value
        }

        var currentVersion = sourceVersion
        var current = value
        while currentVersion < destinationVersion {
            guard let migration = migrations.first(where: {
                $0.fromVersion == currentVersion &&
                $0.toVersion > currentVersion &&
                $0.toVersion <= destinationVersion
            }) else {
                throw PTModelError.migrationFailed("Missing migration from \(currentVersion)")
            }
            current = try migration.apply(to: current)
            currentVersion = migration.toVersion
        }
        return current
    }
}

public enum PTModelSchemaIntrospection {
    public static func jsonSchema<Model: Codable & Sendable>(
        _ schema: PTModelSchema<Model>
    ) -> PTJSONValue {
        schema.jsonSchema()
    }
}

private extension PTJSONValue {
    func replacingValue(at path: PTJSONPath, with replacement: PTJSONValue) throws -> PTJSONValue {
        guard let component = path.components.first else { return replacement }
        let tail = PTJSONPath(Array(path.components.dropFirst()))
        switch (component, self) {
        case (.key(let key), .object(var object)):
            let current = object[key] ?? .object([:])
            object[key] = try current.replacingValue(at: tail, with: replacement)
            return .object(object)
        case (.index(let index), .array(var array)):
            guard array.indices.contains(index) else {
                throw PTModelError.patchFailed("Array index out of bounds: \(index)")
            }
            array[index] = try array[index].replacingValue(at: tail, with: replacement)
            return .array(array)
        default:
            throw PTModelError.patchFailed("Cannot traverse \(path.description)")
        }
    }

    func removingValue(at path: PTJSONPath) throws -> PTJSONValue {
        guard let component = path.components.first else {
            throw PTModelError.patchFailed("The root value cannot be removed")
        }
        let tail = PTJSONPath(Array(path.components.dropFirst()))
        switch (component, self) {
        case (.key(let key), .object(var object)):
            guard object[key] != nil else { return self }
            if tail.components.isEmpty {
                object.removeValue(forKey: key)
            } else {
                object[key] = try object[key]!.removingValue(at: tail)
            }
            return .object(object)
        case (.index(let index), .array(var array)):
            guard array.indices.contains(index) else { return self }
            if tail.components.isEmpty {
                array.remove(at: index)
            } else {
                array[index] = try array[index].removingValue(at: tail)
            }
            return .array(array)
        default:
            throw PTModelError.patchFailed("Cannot traverse \(path.description)")
        }
    }
}
