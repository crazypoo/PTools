//
//  PTModelCodec.swift
//
// English: Codable-compatible model conversion without SmartCodable or KakaJSON dependencies.
// Español: Conversión compatible con Codable sin dependencias de SmartCodable ni KakaJSON.
// 中文：不依赖 SmartCodable 和 KakaJSON 的 Codable 兼容模型转换。
//

import Foundation

public struct PTModelDecoder: Sendable {
    public let policy: PTDecodePolicy
    public let duplicateKeyPolicy: PTDuplicateKeyPolicy
    public let limits: PTModelLimits
    public let dateStrategy: PTDateDecodingStrategy
    public let context: PTModelContext

    public init(policy: PTDecodePolicy = .compatible,
                duplicateKeyPolicy: PTDuplicateKeyPolicy = .keepLast,
                limits: PTModelLimits = .init(),
                dateStrategy: PTDateDecodingStrategy = .deferredToDate,
                context: PTModelContext = .init()) {
        self.policy = policy
        self.duplicateKeyPolicy = duplicateKeyPolicy
        self.limits = limits
        self.dateStrategy = dateStrategy
        self.context = context
    }

    public func decode<T: Decodable, Source: PTModelSource>(_ type: T.Type, from source: Source) throws -> T {
        let data = try PTModelSourceBridge.data(from: source,
                                                duplicateKeyPolicy: duplicateKeyPolicy,
                                                limits: limits)
        let decoder = JSONDecoder()
        switch dateStrategy {
        case .deferredToDate: decoder.dateDecodingStrategy = .deferredToDate
        case .secondsSince1970: decoder.dateDecodingStrategy = .secondsSince1970
        case .millisecondsSince1970: decoder.dateDecodingStrategy = .millisecondsSince1970
        case .iso8601: decoder.dateDecodingStrategy = .iso8601
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            guard policy != .strict else { throw PTModelError.underlying(error.localizedDescription) }
            if let fallback = try PTPrimitiveFallback.decode(type, data: data) {
                return fallback
            }
            throw PTModelError.underlying(error.localizedDescription)
        }
    }

    public static func decode<T: Decodable, Source: PTModelSource>(_ type: T.Type,
                                                                    from source: Source,
                                                                    policy: PTDecodePolicy = .compatible) throws -> T {
        try PTModelDecoder(policy: policy).decode(type, from: source)
    }
}

public struct PTModelEncoder: Sendable {
    public let prettyPrinted: Bool
    public let sortedKeys: Bool
    public let nilStrategy: PTNilEncodingStrategy
    public let dateStrategy: PTDateEncodingStrategy

    public init(prettyPrinted: Bool = false,
                sortedKeys: Bool = true,
                nilStrategy: PTNilEncodingStrategy = .omit,
                dateStrategy: PTDateEncodingStrategy = .deferredToDate) {
        self.prettyPrinted = prettyPrinted
        self.sortedKeys = sortedKeys
        self.nilStrategy = nilStrategy
        self.dateStrategy = dateStrategy
    }

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        if prettyPrinted { encoder.outputFormatting.insert(.prettyPrinted) }
        if sortedKeys { encoder.outputFormatting.insert(.sortedKeys) }
        switch dateStrategy {
        case .deferredToDate: encoder.dateEncodingStrategy = .deferredToDate
        case .secondsSince1970: encoder.dateEncodingStrategy = .secondsSince1970
        case .millisecondsSince1970: encoder.dateEncodingStrategy = .millisecondsSince1970
        case .iso8601: encoder.dateEncodingStrategy = .iso8601
        }
        return try encoder.encode(value)
    }

    public func encode(_ value: PTJSONValue) throws -> Data {
        try value.jsonData(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys)
    }

    public func jsonValue<T: Encodable>(_ value: T) throws -> PTJSONValue {
        if let value = value as? PTJSONValue { return value }
        return try PTJSONValue(data: encode(value),
                               duplicateKeyPolicy: .reject)
    }

    public func jsonString<T: Encodable>(_ value: T) throws -> String {
        try jsonValue(value).jsonString(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys)
    }

    public func dictionary<T: Encodable>(_ value: T) throws -> [String: Any] {
        guard case .object(let object) = try jsonValue(value) else {
            throw PTModelError.rootIsNotObject
        }
        return object.mapValues(\.foundationObject)
    }

    public func array<T: Encodable>(_ value: T) throws -> [Any] {
        guard case .array(let array) = try jsonValue(value) else {
            throw PTModelError.rootIsNotArray
        }
        return array.map(\.foundationObject)
    }

    public static func encode<T: Encodable>(_ value: T,
                                            prettyPrinted: Bool = false,
                                            sortedKeys: Bool = true) throws -> Data {
        try PTModelEncoder(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys).encode(value)
    }
}

public extension PTModelNamespace {
    func model<Source: PTModelSource>(from source: Source,
                                      using decoder: PTModelDecoder = .init()) throws -> Model where Model: Decodable {
        try decoder.decode(Model.self, from: source)
    }

    func models<Source: PTModelSource>(from source: Source,
                                       using decoder: PTModelDecoder = .init()) throws -> [Model] where Model: Decodable {
        try decoder.decode([Model].self, from: source)
    }

    func jsonData(using encoder: PTModelEncoder = .init()) throws -> Data where Model: Encodable {
        guard let value = value else { throw PTModelError.invalidInput }
        return try encoder.encode(value)
    }

    func jsonString(using encoder: PTModelEncoder = .init()) throws -> String where Model: Encodable {
        guard let value = value else { throw PTModelError.invalidInput }
        return try encoder.jsonString(value)
    }

    func dictionary(using encoder: PTModelEncoder = .init()) throws -> [String: Any] where Model: Encodable {
        guard let value = value else { throw PTModelError.invalidInput }
        return try encoder.dictionary(value)
    }

    func jsonArray(using encoder: PTModelEncoder = .init()) throws -> [Any] where Model: Encodable {
        guard let value = value else { throw PTModelError.invalidInput }
        return try encoder.array(value)
    }
}

public extension Encodable {
    var ptModel: PTModelNamespace<Self> { PTModelNamespace(value: self) }
}

private enum PTModelSourceBridge {
    static func data(from source: any PTModelSource,
                    duplicateKeyPolicy: PTDuplicateKeyPolicy,
                    limits: PTModelLimits) throws -> Data {
        if let data = source as? Data {
            guard data.count <= limits.maxInputBytes else { throw PTModelError.inputTooLarge }
            return data
        }
        if let string = source as? String {
            let data = Data(string.utf8)
            guard data.count <= limits.maxInputBytes else { throw PTModelError.inputTooLarge }
            return data
        }
        if let value = source as? PTJSONValue {
            return try value.jsonData(sortedKeys: duplicateKeyPolicy != .keepFirst)
        }
        if let dictionary = source as? [String: Any] {
            let value = try PTFoundationJSONBridge.value(from: dictionary, limits: limits)
            return try value.jsonData(sortedKeys: true)
        }
        if let array = source as? [Any] {
            let value = try PTFoundationJSONBridge.value(from: array, limits: limits)
            return try value.jsonData(sortedKeys: true)
        }
        if let dictionary = source as? NSDictionary {
            let value = try PTFoundationJSONBridge.value(from: dictionary, limits: limits)
            return try value.jsonData(sortedKeys: true)
        }
        if let array = source as? NSArray {
            let value = try PTFoundationJSONBridge.value(from: array, limits: limits)
            return try value.jsonData(sortedKeys: true)
        }
        throw PTModelError.unsupportedSource(String(reflecting: type(of: source)))
    }
}

private enum PTPrimitiveFallback {
    static func decode<T: Decodable>(_ type: T.Type, data: Data) throws -> T? {
        let value = try? PTJSONValue(data: data)
        guard let value else { return nil }
        switch value {
        case .string(let string):
            if type == String.self { return string as? T }
            if type == Int.self { return Int(string) as? T }
            if type == Int64.self { return Int64(string) as? T }
            if type == UInt.self { return UInt(string) as? T }
            if type == UInt64.self { return UInt64(string) as? T }
            if type == Double.self { return Double(string) as? T }
            if type == Float.self { return Float(string) as? T }
            if type == Bool.self { return parseBool(string) as? T }
        case .number(let number):
            if type == String.self { return number.rawRepresentation as? T }
            if type == Int.self { return number.int64Value.flatMap(Int.init) as? T }
            if type == Int64.self { return number.int64Value as? T }
            if type == UInt.self { return number.uint64Value.flatMap(UInt.init) as? T }
            if type == UInt64.self { return number.uint64Value as? T }
            if type == Double.self { return number.doubleValue as? T }
            if type == Float.self { return number.doubleValue.flatMap(Float.init) as? T }
        case .bool(let value):
            if type == Bool.self { return value as? T }
            if type == String.self { return (value ? "true" : "false") as? T }
            if type == Int.self { return (value ? 1 : 0) as? T }
        default:
            break
        }
        return nil
    }

    private static func parseBool(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "true", "yes", "y", "1": return true
        case "false", "no", "n", "0": return false
        default: return nil
        }
    }
}
