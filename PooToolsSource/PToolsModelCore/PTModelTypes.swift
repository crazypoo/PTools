//
//  PTModelTypes.swift
//
// English: Public contracts for the Foundation-only PTModel boundary.
// Español: Contratos públicos para el límite PTModel basado únicamente en Foundation.
// 中文：仅依赖 Foundation 的 PTModel 边界公共契约。
//

import Foundation

public enum PTDecodePolicy: String, Sendable, Codable {
    case strict
    case compatible
    case lossy
}

public enum PTNilEncodingStrategy: String, Sendable, Codable {
    case omit
    case null
}

public enum PTDuplicateKeyPolicy: String, Sendable, Codable {
    case keepFirst
    case keepLast
    case reject
}

public enum PTNumericOverflowPolicy: String, Sendable, Codable {
    case error
    case useDefault
    case clamp
}

public enum PTStringifiedJSONPolicy: String, Sendable, Codable {
    case disabled
    case nestedModelsOnly
    case collectionsAndModels
}

public enum PTDictionaryKeyStrategy: String, Sendable, Codable {
    case stringOnly
    case losslessStringConvertible
    case rawRepresentable
    case keyValuePairs
}

public enum PTDateDecodingStrategy: Sendable, Codable, Equatable {
    case deferredToDate
    case secondsSince1970
    case millisecondsSince1970
    case iso8601
}

public enum PTDateEncodingStrategy: Sendable, Codable, Equatable {
    case deferredToDate
    case secondsSince1970
    case millisecondsSince1970
    case iso8601
}

public struct PTModelLimits: Sendable, Codable, Equatable {
    public var maxInputBytes: Int
    public var maxDepth: Int

    public init(maxInputBytes: Int = 16 * 1024 * 1024, maxDepth: Int = 128) {
        self.maxInputBytes = max(1, maxInputBytes)
        self.maxDepth = max(1, maxDepth)
    }
}

public enum PTCodableInteropPolicy: String, Sendable, Codable {
    case preferPTModel
    case preferCustomCodable
    case ptModelFastPathWithCodableFallback
    case codableOnly
}

public enum PTModelError: Error, LocalizedError, Sendable, Equatable {
    case invalidInput
    case invalidJSON(String)
    case unsupportedSource(String)
    case typeMismatch(expected: String, actual: String)
    case missingValue(String)
    case nullValue(String)
    case numericOverflow(String)
    case duplicateKey(String)
    case depthLimitExceeded
    case inputTooLarge
    case rootIsNotObject
    case rootIsNotArray
    case conversionFailed(String)
    case underlying(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "The model input is invalid."
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        case .unsupportedSource(let type):
            return "Unsupported model source: \(type)"
        case .typeMismatch(let expected, let actual):
            return "Expected \(expected), received \(actual)."
        case .missingValue(let key):
            return "Missing value for \(key)."
        case .nullValue(let key):
            return "Null value for \(key)."
        case .numericOverflow(let value):
            return "Numeric value is out of range: \(value)"
        case .duplicateKey(let key):
            return "Duplicate JSON key: \(key)"
        case .depthLimitExceeded:
            return "The JSON nesting depth exceeds the configured limit."
        case .inputTooLarge:
            return "The model input exceeds the configured size limit."
        case .rootIsNotObject:
            return "The JSON root is not an object."
        case .rootIsNotArray:
            return "The JSON root is not an array."
        case .conversionFailed(let message), .underlying(let message):
            return message
        }
    }
}

// English: A source is only a marker; conversion is centralized in PTModelDecoder.
// Español: La fuente solo es un marcador; la conversión está centralizada en PTModelDecoder.
// 中文：Source 只负责标记，转换统一由 PTModelDecoder 集中处理。
public protocol PTModelSource {}

extension Data: PTModelSource {}
extension String: PTModelSource {}
extension Dictionary: PTModelSource where Key == String, Value == Any {}
extension Array: PTModelSource where Element == Any {}
extension NSDictionary: PTModelSource {}
extension NSArray: PTModelSource {}

public protocol PTModelContextKey {
    associatedtype Value: Codable & Sendable
}

// English: Typed context values are encoded as PTJSONValue instead of carrying Any across actors.
// Español: Los valores tipados se guardan como PTJSONValue y no transportan Any entre actores.
// 中文：类型化上下文使用 PTJSONValue 保存，不让 Any 跨 actor 传递。
public struct PTModelContext: Sendable {
    private var storage: [String: PTJSONValue]

    public init() {
        storage = [:]
    }

    public subscript<Key: PTModelContextKey>(key: Key.Type) -> Key.Value? {
        get {
            guard let value = storage[String(reflecting: Key.self)] else { return nil }
            return try? PTModelDecoder(policy: .strict).decode(Key.Value.self, from: value)
        }
        set {
            let storageKey = String(reflecting: Key.self)
            guard let newValue else {
                storage.removeValue(forKey: storageKey)
                return
            }
            if let value = try? PTModelEncoder().jsonValue(newValue) {
                storage[storageKey] = value
            }
        }
    }

    public var jsonValues: [String: PTJSONValue] {
        storage
    }
}

public typealias PTDecodingContext = PTModelContext
public typealias PTEncodingContext = PTModelContext

public enum PTPresence<Value: Codable & Sendable>: Sendable, Codable, Equatable where Value: Equatable {
    case missing
    case null
    case value(Value)

    public init(_ value: Value) {
        self = .value(value)
    }

    public var value: Value? {
        guard case .value(let value) = self else { return nil }
        return value
    }

    public var isMissing: Bool {
        if case .missing = self { return true }
        return false
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else {
            self = .value(try container.decode(Value.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .missing, .null:
            try container.encodeNil()
        case .value(let value):
            try container.encode(value)
        }
    }
}

extension PTJSONValue: PTModelSource {}

// English: The namespace keeps one-line model conversion available without annotations.
// Español: El namespace mantiene disponible la conversión de una línea sin anotaciones.
// 中文：Namespace 让普通 Codable 模型无需额外注解即可使用一行式转换。
public struct PTModelNamespace<Model> {
    let value: Model?

    public init() {
        value = nil
    }

    init(value: Model) {
        self.value = value
    }
}

public extension Decodable {
    static var pt: PTModelNamespace<Self> { PTModelNamespace() }
}

public extension Encodable {
    var pt: PTModelNamespace<Self> { PTModelNamespace(value: self) }
}
