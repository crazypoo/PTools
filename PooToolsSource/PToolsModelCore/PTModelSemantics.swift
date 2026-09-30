//
//  PTModelSemantics.swift
//
// English: Typed paths, field state, aliases, and bounded collection semantics for PTModel.
// Español: Rutas tipadas, estados de campo, alias y semántica acotada de colecciones para PTModel.
// 中文：PTModel 的类型化路径、字段状态、别名和有边界的集合语义。
//

import Foundation

public struct PTJSONPath: Sendable, Hashable, Codable, ExpressibleByStringLiteral {
    public enum Component: Sendable, Hashable, Codable {
        case key(String)
        case index(Int)
    }

    public let components: [Component]

    public init(_ components: [Component] = []) {
        self.components = components
    }

    public init(stringLiteral value: String) {
        self = (try? Self.parse(value)) ?? Self()
    }

    public static func parse(_ path: String) throws -> PTJSONPath {
        let characters = Array(path)
        if characters.isEmpty || path == "$" { return Self() }
        var index = path.first == "$" ? 1 : 0
        var components: [Component] = []
        while index < characters.count {
            if characters[index] == "." {
                index += 1
            }
            if index >= characters.count { throw PTModelError.invalidJSONPath(path) }
            if characters[index] == "[" {
                index += 1
                let start = index
                while index < characters.count, characters[index] != "]" { index += 1 }
                guard index < characters.count,
                      let value = Int(String(characters[start..<index])),
                      value >= 0 else {
                    throw PTModelError.invalidJSONPath(path)
                }
                components.append(.index(value))
                index += 1
                continue
            }
            let start = index
            while index < characters.count, characters[index] != ".", characters[index] != "[" {
                index += 1
            }
            guard start < index else { throw PTModelError.invalidJSONPath(path) }
            components.append(.key(String(characters[start..<index])))
        }
        return Self(components)
    }

    public static let root = Self()

    public var description: String {
        components.reduce("$") { result, component in
            switch component {
            case .key(let key): return result + "." + key
            case .index(let index): return result + "[\(index)]"
            }
        }
    }

    // English: Append a typed component without exposing stringly-typed path construction to decoders.
    // Español: Añade un componente tipado sin exponer la construcción de rutas basada en cadenas a los decodificadores.
    // 中文：追加类型化路径组件，避免 decoder 依赖字符串拼接。
    public func appending(_ component: Component) -> PTJSONPath {
        PTJSONPath(components + [component])
    }
}

public extension PTJSONValue {
    func value(at path: PTJSONPath) throws -> PTJSONValue? {
        var current = self
        for component in path.components {
            switch (component, current) {
            case (.key(let key), .object(let object)):
                guard let next = object[key] else { return nil }
                current = next
            case (.index(let index), .array(let array)):
                guard array.indices.contains(index) else { return nil }
                current = array[index]
            default:
                throw PTModelError.pathTypeMismatch(path.description)
            }
        }
        return current
    }

    func requiredValue(at path: PTJSONPath) throws -> PTJSONValue {
        guard let value = try value(at: path) else {
            throw PTModelError.requiredValue(path.description)
        }
        return value
    }

    func aliasedValue(using mapping: PTModelKeyMapping,
                      conflictPolicy: PTModelAliasConflictPolicy = .preferCanonical) throws -> PTJSONValue? {
        guard case .object(let object) = self else { throw PTModelError.rootIsNotObject }
        let matches = mapping.decodeKeys.compactMap { key in object[key].map { (key, $0) } }
        guard !matches.isEmpty else { return nil }
        if matches.count == 1 { return matches[0].1 }
        switch conflictPolicy {
        case .preferCanonical:
            return object[mapping.encodeKey] ?? matches[0].1
        case .preferFirst:
            return matches[0].1
        case .reject:
            throw PTModelError.conversionFailed("Conflicting aliases: \(mapping.decodeKeys.joined(separator: ","))")
        }
    }
}

public enum PTModelAliasConflictPolicy: String, Sendable, Codable {
    case preferCanonical
    case preferFirst
    case reject
}

public struct PTModelKeyMapping: Sendable, Codable, Hashable {
    public let decodeKeys: [String]
    public let encodeKey: String

    public init(decodeKeys: [String], encodeKey: String? = nil) {
        self.decodeKeys = decodeKeys
        self.encodeKey = encodeKey ?? decodeKeys.first ?? ""
    }
}

public enum PTLossyCollectionStrategy: String, Sendable, Codable {
    case fail
    case skipInvalid
    case replaceWithDefault
    case preserveIndexAsNil

    // English: Keep the shorter 5.58 spelling as a source-compatible alias.
    // Español: Conserva la forma corta de 5.58 como alias compatible a nivel de código fuente.
    // 中文：保留 5.58 的短名称作为源码兼容别名。
    @available(*, deprecated, renamed: "replaceWithDefault")
    public static var replaceDefault: Self { .replaceWithDefault }
}

public enum PTEmptyObjectStrategy: String, Sendable, Codable {
    case preserve
    case decodeAsNil
    case decodeAsDefault
}

public struct PTValueCoercionPolicy: Sendable, Codable, Equatable {
    public var stringToNumber: Bool
    public var numberToString: Bool
    public var boolToInteger: Bool
    public var yesNoToBool: Bool

    public init(stringToNumber: Bool = true,
                numberToString: Bool = true,
                boolToInteger: Bool = true,
                yesNoToBool: Bool = true) {
        self.stringToNumber = stringToNumber
        self.numberToString = numberToString
        self.boolToInteger = boolToInteger
        self.yesNoToBool = yesNoToBool
    }
}

public enum PTModelFieldState<Value: Sendable>: Sendable {
    case missing
    case null
    case invalid(String)
    case value(Value)
}

public struct PTModelCodingSession: Sendable, Equatable {
    private var frames: [PTJSONPath]

    public init() {
        frames = []
    }

    public var currentPath: PTJSONPath { frames.last ?? .root }

    public mutating func push(_ path: PTJSONPath) {
        frames.append(path)
    }

    // English: Frame scopes always restore the previous path, including when nested decoding throws.
    // Español: Los ámbitos de frame restauran siempre la ruta anterior, incluso si falla una decodificación anidada.
    // 中文：无论嵌套解码是否抛错，frame 作用域都会恢复之前的路径。
    @discardableResult
    public mutating func withFrame<Result>(_ path: PTJSONPath,
                                           _ operation: (inout PTModelCodingSession) throws -> Result) rethrows -> Result {
        push(path)
        defer { _ = pop() }
        return try operation(&self)
    }

    @discardableResult
    public mutating func pop() -> PTJSONPath? {
        frames.popLast()
    }
}

public enum PTRequired {
    public static func value<T>(_ value: T?, at path: PTJSONPath) throws -> T {
        guard let value else { throw PTModelError.requiredValue(path.description) }
        return value
    }
}
