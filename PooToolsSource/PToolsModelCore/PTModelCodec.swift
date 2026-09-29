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
    public let dictionaryKeyStrategy: PTDictionaryKeyStrategy
    public let coercionPolicy: PTValueCoercionPolicy

    public init(policy: PTDecodePolicy = .compatible,
                duplicateKeyPolicy: PTDuplicateKeyPolicy = .keepLast,
                limits: PTModelLimits = .init(),
                dateStrategy: PTDateDecodingStrategy = .deferredToDate,
                context: PTModelContext = .init(),
                dictionaryKeyStrategy: PTDictionaryKeyStrategy = .stringOnly,
                coercionPolicy: PTValueCoercionPolicy = .init()) {
        self.policy = policy
        self.duplicateKeyPolicy = duplicateKeyPolicy
        self.limits = limits
        self.dateStrategy = dateStrategy
        self.context = context
        self.dictionaryKeyStrategy = dictionaryKeyStrategy
        self.coercionPolicy = coercionPolicy
    }

    public func decode<T: Decodable, Source: PTModelSource>(_ type: T.Type, from source: Source) throws -> T {
        let data = try PTModelSourceBridge.data(from: source,
                                                duplicateKeyPolicy: duplicateKeyPolicy,
                                                limits: limits)
        // English: Parse once to enforce duplicate-key and resource limits before JSONDecoder sees the payload.
        // Español: Analiza una vez para aplicar duplicados y límites antes de entregar el payload a JSONDecoder.
        // 中文：先解析一次，在交给 JSONDecoder 前统一执行重复键和资源限制。
        let parsedValue = try PTJSONValue(data: data,
                                          duplicateKeyPolicy: duplicateKeyPolicy,
                                          limits: limits)
        // English: Re-encode the normalized tree so JSONDecoder cannot silently reapply its own duplicate-key policy.
        // Español: Re-encode el árbol normalizado para que JSONDecoder no aplique silenciosamente otra política de claves duplicadas.
        // 中文：重新编码归一化后的树，避免 JSONDecoder 悄悄使用另一套重复键策略。
        let normalizedData = try parsedValue.jsonData(sortedKeys: false)
        let decoder = JSONDecoder()
        switch dateStrategy {
        case .deferredToDate: decoder.dateDecodingStrategy = .deferredToDate
        case .secondsSince1970: decoder.dateDecodingStrategy = .secondsSince1970
        case .millisecondsSince1970: decoder.dateDecodingStrategy = .millisecondsSince1970
        case .iso8601: decoder.dateDecodingStrategy = .iso8601
        }
        do {
            return try decoder.decode(T.self, from: normalizedData)
        } catch {
            guard policy != .strict else { throw PTModelError.underlying(error.localizedDescription) }
            if let fallback = try PTPrimitiveFallback.decode(type,
                                                             data: normalizedData,
                                                             coercion: coercionPolicy) {
                return fallback
            }
            throw PTModelError.underlying(error.localizedDescription)
        }
    }

    public func decodeValue<T: Decodable>(_ type: T.Type,
                                          from value: PTJSONValue,
                                          path: PTJSONPath = .root) throws -> T {
        do {
            return try decode(type, from: value)
        } catch {
            guard policy != .strict,
                  let fallback = try PTPrimitiveFallback.decode(type, value: value, coercion: coercionPolicy) else {
                throw PTModelError.underlying("\(path.description): \(error.localizedDescription)")
            }
            return fallback
        }
    }

    // English: Resolve one field into missing, null, invalid, or value without collapsing diagnostics into nil.
    // Español: Resuelve un campo como ausente, nulo, inválido o valor sin convertir los diagnósticos en nil.
    // 中文：将字段明确解析为 missing、null、invalid 或 value，不把诊断信息压成 nil。
    public func decodeField<T: Decodable>(_ type: T.Type,
                                          from object: PTJSONValue,
                                          key: String,
                                          path: PTJSONPath = .root) -> PTModelFieldState<T> {
        guard case .object(let values) = object else {
            return .invalid(path.appending(.key(key)).description)
        }
        guard let value = values[key] else { return .missing }
        let fieldPath = path.appending(.key(key))
        if case .null = value { return .null }
        do {
            return .value(try decodeValue(type, from: value, path: fieldPath))
        } catch {
            return .invalid(fieldPath.description)
        }
    }

    // English: Empty-object behavior is explicit and does not require a macro-generated model initializer.
    // Español: El comportamiento de un objeto vacío es explícito y no requiere un inicializador generado por macro.
    // 中文：空对象行为显式配置，不依赖宏生成的模型初始化器。
    public func decodeOptional<T: Decodable>(_ type: T.Type,
                                             from value: PTJSONValue,
                                             emptyObjectStrategy: PTEmptyObjectStrategy = .preserve,
                                             defaultValue: T? = nil) throws -> T? {
        if case .null = value { return nil }
        if case .object(let object) = value, object.isEmpty {
            switch emptyObjectStrategy {
            case .preserve:
                break
            case .decodeAsNil:
                return nil
            case .decodeAsDefault:
                guard let defaultValue else {
                    throw PTModelError.conversionFailed("A default value is required for an empty object")
                }
                return defaultValue
            }
        }
        return try decodeValue(type, from: value)
    }

    // English: Decode an aliased field through the same coercion and path diagnostics as every other value.
    // Español: Decodifica un campo con alias usando la misma coerción y diagnósticos de ruta que los demás valores.
    // 中文：别名字段复用统一的类型转换和路径诊断逻辑。
    public func decodeAliased<T: Decodable>(_ type: T.Type,
                                            from object: PTJSONValue,
                                            mapping: PTModelKeyMapping,
                                            conflictPolicy: PTModelAliasConflictPolicy = .preferCanonical,
                                            path: PTJSONPath = .root) throws -> T? {
        guard let value = try object.aliasedValue(using: mapping, conflictPolicy: conflictPolicy) else {
            return nil
        }
        return try decodeValue(type, from: value, path: path.appending(.key(mapping.encodeKey)))
    }

    public func decodeArray<Element: Decodable>(_ type: Element.Type,
                                                from value: PTJSONValue,
                                                strategy: PTLossyCollectionStrategy = .fail,
                                                defaultValue: Element? = nil) throws -> [Element] {
        guard case .array(let values) = value else { throw PTModelError.rootIsNotArray }
        var result: [Element] = []
        for (index, value) in values.enumerated() {
            do {
                result.append(try decodeValue(type, from: value, path: PTJSONPath([.index(index)])))
            } catch {
                switch strategy {
                case .fail:
                    throw error
                case .skipInvalid:
                    continue
                case .preserveIndexAsNil:
                    throw PTModelError.invalidCollectionElement("[\(index)] requires an optional element result")
                case .replaceWithDefault:
                    guard let defaultValue else {
                        throw PTModelError.invalidCollectionElement("[\(index)]")
                    }
                    result.append(defaultValue)
                }
            }
        }
        return result
    }

    public func decodeOptionalArray<Element: Decodable>(_ type: Element.Type,
                                                        from value: PTJSONValue,
                                                        strategy: PTLossyCollectionStrategy = .preserveIndexAsNil) throws -> [Element?] {
        guard case .array(let values) = value else { throw PTModelError.rootIsNotArray }
        var result: [Element?] = []
        for (index, value) in values.enumerated() {
            do {
                result.append(try decodeValue(type, from: value, path: PTJSONPath([.index(index)])))
            } catch {
                switch strategy {
                case .preserveIndexAsNil:
                    result.append(nil)
                case .skipInvalid:
                    continue
                case .fail:
                    throw error
                case .replaceWithDefault:
                    throw PTModelError.invalidCollectionElement("[\(index)]")
                }
            }
        }
        return result
    }

    public func decodeDictionary<Key: Hashable & Decodable, Value: Decodable>(_ keyType: Key.Type,
                                                                                _ valueType: Value.Type,
                                                                                from value: PTJSONValue) throws -> [Key: Value] {
        switch dictionaryKeyStrategy {
        case .keyValuePairs:
            guard case .array(let pairs) = value else { throw PTModelError.rootIsNotArray }
            var result: [Key: Value] = [:]
            for pair in pairs {
                guard case .object(let object) = pair,
                      let keyValue = object["key"],
                      let itemValue = object["value"] else {
                    throw PTModelError.conversionFailed("Invalid key-value pair")
                }
                let key = try decodeValue(keyType, from: keyValue)
                result[key] = try decodeValue(valueType, from: itemValue)
            }
            return result
        case .stringOnly, .losslessStringConvertible, .rawRepresentable:
            guard case .object(let object) = value else { throw PTModelError.rootIsNotObject }
            var result: [Key: Value] = [:]
            for (rawKey, itemValue) in object {
                let key: Key
                if dictionaryKeyStrategy == .stringOnly {
                    guard let string = rawKey as? Key else {
                        throw PTModelError.conversionFailed("Dictionary key is not String")
                    }
                    key = string
                } else if let type = Key.self as? any LosslessStringConvertible.Type,
                          let parsed = type.init(rawKey) as? Key {
                    key = parsed
                } else {
                    throw PTModelError.conversionFailed("Dictionary key cannot be decoded: \(rawKey)")
                }
                result[key] = try decodeValue(valueType, from: itemValue)
            }
            return result
        }
    }

    public func decodeSet<Element: Hashable & Decodable>(_ type: Element.Type,
                                                          from value: PTJSONValue,
                                                          duplicatePolicy: PTSetDuplicatePolicy = .keepFirst) throws -> Set<Element> {
        guard case .array(let values) = value else { throw PTModelError.rootIsNotArray }
        var result: Set<Element> = []
        for (index, value) in values.enumerated() {
            let element = try decodeValue(type, from: value, path: PTJSONPath([.index(index)]))
            if duplicatePolicy == .reject, result.contains(element) {
                throw PTModelError.duplicateKey("array[\(index)]")
            }
            result.insert(element)
        }
        return result
    }

    public func decodeRawDictionary<Key: RawRepresentable & Hashable & Decodable, Value: Decodable>(_ keyType: Key.Type,
                                                                                                    _ valueType: Value.Type,
                                                                                                    from value: PTJSONValue) throws -> [Key: Value]
    where Key.RawValue: LosslessStringConvertible {
        guard case .object(let object) = value else { throw PTModelError.rootIsNotObject }
        var result: [Key: Value] = [:]
        for (rawKey, itemValue) in object {
            guard let rawValue = Key.RawValue(rawKey), let key = Key(rawValue: rawValue) else {
                throw PTModelError.conversionFailed("Dictionary key cannot be decoded: \(rawKey)")
            }
            result[key] = try decodeValue(valueType, from: itemValue)
        }
        return result
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
    public let dictionaryKeyStrategy: PTDictionaryKeyStrategy

    public init(prettyPrinted: Bool = false,
                sortedKeys: Bool = true,
                nilStrategy: PTNilEncodingStrategy = .omit,
                dateStrategy: PTDateEncodingStrategy = .deferredToDate,
                dictionaryKeyStrategy: PTDictionaryKeyStrategy = .stringOnly) {
        self.prettyPrinted = prettyPrinted
        self.sortedKeys = sortedKeys
        self.nilStrategy = nilStrategy
        self.dateStrategy = dateStrategy
        self.dictionaryKeyStrategy = dictionaryKeyStrategy
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

    public func jsonValue<Key: Hashable & Encodable, Value: Encodable>(dictionary: [Key: Value]) throws -> PTJSONValue {
        switch dictionaryKeyStrategy {
        case .stringOnly:
            var object: [String: PTJSONValue] = [:]
            for (key, value) in dictionary {
                guard let string = key as? String else {
                    throw PTModelError.conversionFailed("Dictionary key is not String")
                }
                object[string] = try jsonValue(value)
            }
            return .object(object)
        case .losslessStringConvertible:
            var object: [String: PTJSONValue] = [:]
            for (key, value) in dictionary {
                guard let string = key as? any LosslessStringConvertible else {
                    throw PTModelError.conversionFailed("Dictionary key is not LosslessStringConvertible")
                }
                object[String(string)] = try jsonValue(value)
            }
            return .object(object)
        case .rawRepresentable:
            throw PTModelError.conversionFailed("Use encodeRawDictionary for RawRepresentable keys")
        case .keyValuePairs:
            return .array(try dictionary.map { key, value in
                .object(["key": try jsonValue(key), "value": try jsonValue(value)])
            })
        }
    }

    public func jsonValue<Key: RawRepresentable & Hashable & Encodable, Value: Encodable>(rawDictionary: [Key: Value]) throws -> PTJSONValue
    where Key.RawValue: LosslessStringConvertible {
        var object: [String: PTJSONValue] = [:]
        for (key, value) in rawDictionary {
            object[String(key.rawValue)] = try jsonValue(value)
        }
        return .object(object)
    }

    public func encode<Key: RawRepresentable & Hashable & Encodable, Value: Encodable>(rawDictionary: [Key: Value]) throws -> Data
    where Key.RawValue: LosslessStringConvertible {
        try jsonValue(rawDictionary: rawDictionary).jsonData(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys)
    }

    public func encode<Key: Hashable & Encodable, Value: Encodable>(dictionary: [Key: Value]) throws -> Data {
        try jsonValue(dictionary: dictionary).jsonData(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys)
    }

    public func jsonValue<Element: Hashable & Encodable>(set: Set<Element>) throws -> PTJSONValue {
        let values = try set.map { try jsonValue($0) }
        let sorted = try values.sorted {
            try $0.jsonString(sortedKeys: true) < $1.jsonString(sortedKeys: true)
        }
        return .array(sorted)
    }

    public func encode<Element: Hashable & Encodable>(set: Set<Element>) throws -> Data {
        try jsonValue(set: set).jsonData(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys)
    }

    public func write<T: Encodable, Sink: PTJSONByteSink>(_ value: T, to sink: inout Sink) throws {
        try sink.write(encode(value))
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
    static func decode<T: Decodable>(_ type: T.Type,
                                     data: Data,
                                     coercion: PTValueCoercionPolicy = .init()) throws -> T? {
        let value = try? PTJSONValue(data: data)
        guard let value else { return nil }
        return try decode(type, value: value, coercion: coercion)
    }

    static func decode<T: Decodable>(_ type: T.Type,
                                     value: PTJSONValue,
                                     coercion: PTValueCoercionPolicy) throws -> T? {
        switch value {
        case .string(let string):
            if type == String.self { return string as? T }
            guard coercion.stringToNumber || type == Bool.self else { return nil }
            if type == Int.self { return Int(string) as? T }
            if type == Int64.self { return Int64(string) as? T }
            if type == UInt.self { return UInt(string) as? T }
            if type == UInt64.self { return UInt64(string) as? T }
            if type == Double.self { return Double(string) as? T }
            if type == Float.self { return Float(string) as? T }
            if type == Bool.self, coercion.yesNoToBool { return parseBool(string) as? T }
        case .number(let number):
            if type == String.self, coercion.numberToString { return number.rawRepresentation as? T }
            if type == Int.self { return number.int64Value.flatMap(Int.init) as? T }
            if type == Int64.self { return number.int64Value as? T }
            if type == UInt.self { return number.uint64Value.flatMap(UInt.init) as? T }
            if type == UInt64.self { return number.uint64Value as? T }
            if type == Double.self { return number.doubleValue as? T }
            if type == Float.self { return number.doubleValue.flatMap(Float.init) as? T }
        case .bool(let value):
            if type == Bool.self { return value as? T }
            if type == String.self { return (value ? "true" : "false") as? T }
            if type == Int.self, coercion.boolToInteger { return (value ? 1 : 0) as? T }
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
