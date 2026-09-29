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

public enum PTSetDuplicatePolicy: String, Sendable, Codable {
    case keepFirst
    case reject
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
    public var maxStringBytes: Int
    public var maxCollectionCount: Int
    public var maxObjectKeyCount: Int
    public var maxNumberDigits: Int

    // English: Limits protect the parser from oversized values before they reach application models.
    // Español: Los límites protegen el analizador de valores excesivos antes de llegar a los modelos.
    // 中文：这些限制在数据进入业务模型前保护解析器，避免超大输入消耗资源。
    public init(maxInputBytes: Int = 16 * 1024 * 1024,
                maxDepth: Int = 128,
                maxStringBytes: Int = 4 * 1024 * 1024,
                maxCollectionCount: Int = 100_000,
                maxObjectKeyCount: Int = 100_000,
                maxNumberDigits: Int = 1_000) {
        self.maxInputBytes = max(1, maxInputBytes)
        self.maxDepth = max(1, maxDepth)
        self.maxStringBytes = max(1, maxStringBytes)
        self.maxCollectionCount = max(1, maxCollectionCount)
        self.maxObjectKeyCount = max(1, maxObjectKeyCount)
        self.maxNumberDigits = max(1, maxNumberDigits)
    }

    // English: Decode older persisted limit values with safe defaults for the new resource guards.
    // Español: Decodifica valores de límites persistidos antiguos usando valores seguros para las nuevas protecciones.
    // 中文：读取旧版持久化限制配置时，为新增资源保护字段使用安全默认值。
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(maxInputBytes: try container.decodeIfPresent(Int.self, forKey: .maxInputBytes) ?? 16 * 1024 * 1024,
                  maxDepth: try container.decodeIfPresent(Int.self, forKey: .maxDepth) ?? 128,
                  maxStringBytes: try container.decodeIfPresent(Int.self, forKey: .maxStringBytes) ?? 4 * 1024 * 1024,
                  maxCollectionCount: try container.decodeIfPresent(Int.self, forKey: .maxCollectionCount) ?? 100_000,
                  maxObjectKeyCount: try container.decodeIfPresent(Int.self, forKey: .maxObjectKeyCount) ?? 100_000,
                  maxNumberDigits: try container.decodeIfPresent(Int.self, forKey: .maxNumberDigits) ?? 1_000)
    }

    private enum CodingKeys: String, CodingKey {
        case maxInputBytes
        case maxDepth
        case maxStringBytes
        case maxCollectionCount
        case maxObjectKeyCount
        case maxNumberDigits
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
    case stringLimitExceeded
    case collectionLimitExceeded
    case objectKeyLimitExceeded
    case numberDigitLimitExceeded
    case invalidJSONPath(String)
    case pathTypeMismatch(String)
    case requiredValue(String)
    case invalidCollectionElement(String)
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
        case .stringLimitExceeded:
            return "A JSON string exceeds the configured size limit."
        case .collectionLimitExceeded:
            return "A JSON collection exceeds the configured item limit."
        case .objectKeyLimitExceeded:
            return "A JSON object exceeds the configured key limit."
        case .numberDigitLimitExceeded:
            return "A JSON number exceeds the configured digit limit."
        case .invalidJSONPath(let path):
            return "Invalid JSON path: \(path)"
        case .pathTypeMismatch(let path):
            return "JSON path cannot traverse the value at \(path)."
        case .requiredValue(let path):
            return "Required value is missing at \(path)."
        case .invalidCollectionElement(let path):
            return "Invalid collection element at \(path)."
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

// English: Separate names make decoder and encoder session ownership explicit without duplicating the value-type implementation.
// Español: Los nombres separados hacen explícita la propiedad de las sesiones sin duplicar la implementación de tipo valor.
// 中文：通过分开的名称明确 decoder/encoder session 的归属，同时复用同一个值类型实现。
public typealias PTDecodingSession = PTModelCodingSession
public typealias PTEncodingSession = PTModelCodingSession

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

public extension KeyedEncodingContainer {
    // English: Missing fields are omitted; null fields remain explicit in keyed model encoding.
    // Español: Los campos ausentes se omiten y los nulos permanecen explícitos en modelos con claves.
    // 中文：键控模型编码时 missing 会省略，null 会保留为显式 null。
    mutating func encode<Value: Codable & Sendable>(_ value: PTPresence<Value>, forKey key: Key) throws {
        switch value {
        case .missing:
            return
        case .null:
            try encodeNil(forKey: key)
        case .value(let value):
            try encode(value, forKey: key)
        }
    }

    // English: The nil strategy is explicit at the field boundary so legacy Encodable models stay source-compatible.
    // Español: La estrategia nil es explícita en el límite del campo y mantiene compatibles los modelos heredados.
    // 中文：在字段边界显式传入 nil 策略，保持旧 Encodable 模型的源码兼容。
    mutating func encode<Value: Encodable>(_ value: Value?, forKey key: Key, nilStrategy: PTNilEncodingStrategy) throws {
        guard let value else {
            if nilStrategy == .null { try encodeNil(forKey: key) }
            return
        }
        try encode(value, forKey: key)
    }
}

public extension KeyedDecodingContainer {
    // English: Keyed decoding distinguishes a missing key from an explicit JSON null.
    // Español: La decodificación con claves distingue una clave ausente de un null JSON explícito.
    // 中文：键控解码区分缺少字段和显式 JSON null。
    func decodePresence<Value: Codable & Sendable>(_ type: Value.Type, forKey key: Key) throws -> PTPresence<Value> {
        guard contains(key) else { return .missing }
        if try decodeNil(forKey: key) { return .null }
        return .value(try decode(Value.self, forKey: key))
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
