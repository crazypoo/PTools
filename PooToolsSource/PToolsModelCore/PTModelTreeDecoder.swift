//
//  PTModelTreeDecoder.swift
//
// English: A Foundation-only decoder that reads the bounded PTJSONValue tree without JSONDecoder re-parsing.
// Español: Un decoder basado solo en Foundation que lee el árbol PTJSONValue limitado sin volver a analizar con JSONDecoder.
// 中文：仅依赖 Foundation 的 decoder，直接读取受限 PTJSONValue 树，不再重复经过 JSONDecoder。
//

import Foundation

private struct PTTreeDecodingOptions: Sendable {
    let policy: PTDecodePolicy
    let dateStrategy: PTDateDecodingStrategy
    let dataStrategy: PTDataDecodingStrategy
    let floatingPointStrategy: PTFloatingPointStrategy
    let urlStrategy: PTURLCodingStrategy
    let coercion: PTValueCoercionPolicy
    let numericOverflowPolicy: PTNumericOverflowPolicy
}

private final class PTModelTreeDecoder: Decoder {
    let value: PTJSONValue
    let options: PTTreeDecodingOptions
    let codingPath: [any CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    init(value: PTJSONValue,
         options: PTTreeDecodingOptions,
         codingPath: [any CodingKey] = [],
         userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.value = value
        self.options = options
        self.codingPath = codingPath
        self.userInfo = userInfo
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
    where Key: CodingKey {
        guard case .object = value else {
            throw PTModelError.typeMismatch(expected: "object", actual: value.typeName)
        }
        return KeyedDecodingContainer(PTTreeKeyedDecodingContainer<Key>(decoder: self))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case .array = value else {
            throw PTModelError.typeMismatch(expected: "array", actual: value.typeName)
        }
        return PTTreeUnkeyedDecodingContainer(decoder: self)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        PTTreeSingleValueDecodingContainer(decoder: self)
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        if type == PTJSONValue.self, let value = value as? T { return value }
        if type == PTJSONNumber.self,
           case .number(let number) = value,
           let number = number as? T { return number }
        if type == Date.self {
            let date = try PTModelFoundationCodec.date(from: value,
                                                       strategy: options.dateStrategy)
            guard let date = date as? T else {
                throw PTModelError.typeMismatch(expected: "Date", actual: value.typeName)
            }
            return date
        }
        if type == Data.self {
            let data = try PTModelFoundationCodec.data(from: value,
                                                       strategy: options.dataStrategy)
            guard let data = data as? T else {
                throw PTModelError.typeMismatch(expected: "Data", actual: value.typeName)
            }
            return data
        }
        if type == URL.self {
            let url = try PTModelFoundationCodec.url(from: value,
                                                     strategy: options.urlStrategy)
            guard let url = url as? T else {
                throw PTModelError.typeMismatch(expected: "URL", actual: value.typeName)
            }
            return url
        }
        if type == Decimal.self,
           case .number(let number) = value,
           let decimal = number.decimalValue,
           let decimal = decimal as? T { return decimal }
        if let primitive = try decodeScalar(type) { return primitive }
        return try T(from: self)
    }

    fileprivate func decodeScalar<T: Decodable>(_ type: T.Type) throws -> T? {
        switch value {
        case .string(let string):
            if type == String.self { return string as? T }
            guard options.coercion.stringToNumber else { return nil }
            if type == Int.self { return try exactInt(string) as? T }
            if type == Int8.self { return try exactInt8(string) as? T }
            if type == Int16.self { return try exactInt16(string) as? T }
            if type == Int32.self { return try exactInt32(string) as? T }
            if type == Int64.self { return try exactInt64(string) as? T }
            if type == UInt.self { return try exactUInt(string) as? T }
            if type == UInt8.self { return try exactUInt8(string) as? T }
            if type == UInt16.self { return try exactUInt16(string) as? T }
            if type == UInt32.self { return try exactUInt32(string) as? T }
            if type == UInt64.self { return try exactUInt64(string) as? T }
            if type == Double.self { return Double(string) as? T }
            if type == Float.self { return Float(string) as? T }
            if type == Bool.self, options.coercion.yesNoToBool {
                return parseBool(string) as? T
            }
        case .number(let number):
            if type == String.self, options.coercion.numberToString {
                return number.rawRepresentation as? T
            }
            if type == Int.self { return try exactInt(number.rawRepresentation) as? T }
            if type == Int8.self { return try exactInt8(number.rawRepresentation) as? T }
            if type == Int16.self { return try exactInt16(number.rawRepresentation) as? T }
            if type == Int32.self { return try exactInt32(number.rawRepresentation) as? T }
            if type == Int64.self { return try exactInt64(number.rawRepresentation) as? T }
            if type == UInt.self { return try exactUInt(number.rawRepresentation) as? T }
            if type == UInt8.self { return try exactUInt8(number.rawRepresentation) as? T }
            if type == UInt16.self { return try exactUInt16(number.rawRepresentation) as? T }
            if type == UInt32.self { return try exactUInt32(number.rawRepresentation) as? T }
            if type == UInt64.self { return try exactUInt64(number.rawRepresentation) as? T }
            if type == Double.self { return number.doubleValue as? T }
            if type == Float.self { return number.doubleValue.flatMap(Float.init) as? T }
        case .bool(let bool):
            if type == Bool.self { return bool as? T }
            if type == Int.self, options.coercion.boolToInteger {
                return (bool ? 1 : 0) as? T
            }
            if type == Int64.self, options.coercion.boolToInteger {
                return (bool ? Int64(1) : Int64(0)) as? T
            }
        case .null, .array, .object:
            break
        }
        return nil
    }

    private func parseBool(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "true", "yes", "y", "1": return true
        case "false", "no", "n", "0": return false
        default: return nil
        }
    }

    private func exactInt(_ raw: String) throws -> Int {
        try exactInteger(Int.self, raw: raw)
    }

    private func exactInt8(_ raw: String) throws -> Int8 {
        try exactInteger(Int8.self, raw: raw)
    }

    private func exactInt16(_ raw: String) throws -> Int16 {
        try exactInteger(Int16.self, raw: raw)
    }

    private func exactInt32(_ raw: String) throws -> Int32 {
        try exactInteger(Int32.self, raw: raw)
    }

    private func exactInt64(_ raw: String) throws -> Int64 {
        try exactInteger(Int64.self, raw: raw)
    }

    private func exactUInt(_ raw: String) throws -> UInt {
        try exactInteger(UInt.self, raw: raw)
    }

    private func exactUInt8(_ raw: String) throws -> UInt8 {
        try exactInteger(UInt8.self, raw: raw)
    }

    private func exactUInt16(_ raw: String) throws -> UInt16 {
        try exactInteger(UInt16.self, raw: raw)
    }

    private func exactUInt32(_ raw: String) throws -> UInt32 {
        try exactInteger(UInt32.self, raw: raw)
    }

    private func exactUInt64(_ raw: String) throws -> UInt64 {
        try exactInteger(UInt64.self, raw: raw)
    }

    private func exactInteger<T: FixedWidthInteger>(_ type: T.Type, raw: String) throws -> T {
        if let value = T(raw) { return value }
        guard options.numericOverflowPolicy == .clamp,
              let decimal = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")),
              let minimum = Decimal(string: String(T.min), locale: Locale(identifier: "en_US_POSIX")),
              let maximum = Decimal(string: String(T.max), locale: Locale(identifier: "en_US_POSIX")) else {
            throw PTModelError.numericOverflow(raw)
        }
        if decimal < minimum { return T.min }
        if decimal > maximum { return T.max }
        throw PTModelError.numericOverflow(raw)
    }
}

private struct PTTreeKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    private let decoder: PTModelTreeDecoder

    var codingPath: [any CodingKey] { decoder.codingPath }

    var allKeys: [Key] {
        guard case .object(let object) = decoder.value else { return [] }
        return object.keys.compactMap(Key.init(stringValue:))
    }

    init(decoder: PTModelTreeDecoder) { self.decoder = decoder }

    func contains(_ key: Key) -> Bool {
        guard case .object(let object) = decoder.value else { return false }
        return object[key.stringValue] != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        guard case .object(let object) = decoder.value else { return false }
        guard let value = object[key.stringValue] else { return false }
        return value == .null
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        guard case .object(let object) = decoder.value,
              let value = object[key.stringValue] else {
            throw PTModelError.missingValue(String(describing: decoder.codingPath + [key]))
        }
        if value == .null {
            throw PTModelError.nullValue(String(describing: decoder.codingPath + [key]))
        }
        return try PTModelTreeDecoder(value: value,
                                      options: decoder.options,
                                      codingPath: decoder.codingPath + [key],
                                      userInfo: decoder.userInfo).decode(type)
    }

    func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T: Decodable {
        guard case .object(let object) = decoder.value,
              let value = object[key.stringValue],
              value != .null else { return nil }
        return try PTModelTreeDecoder(value: value,
                                      options: decoder.options,
                                      codingPath: decoder.codingPath + [key],
                                      userInfo: decoder.userInfo).decode(type)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                    forKey key: Key) throws -> KeyedDecodingContainer<NestedKey>
    where NestedKey: CodingKey {
        let value: PTJSONValue = try decode(PTJSONValue.self, forKey: key)
        let child = PTModelTreeDecoder(value: value,
                                       options: decoder.options,
                                       codingPath: decoder.codingPath + [key],
                                       userInfo: decoder.userInfo)
        return try child.container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        let value: PTJSONValue = try decode(PTJSONValue.self, forKey: key)
        let child = PTModelTreeDecoder(value: value,
                                       options: decoder.options,
                                       codingPath: decoder.codingPath + [key],
                                       userInfo: decoder.userInfo)
        return try child.unkeyedContainer()
    }

    func superDecoder() throws -> Decoder { decoder }

    func superDecoder(forKey key: Key) throws -> Decoder {
        let value: PTJSONValue = try decode(PTJSONValue.self, forKey: key)
        return PTModelTreeDecoder(value: value,
                                  options: decoder.options,
                                  codingPath: decoder.codingPath + [key],
                                  userInfo: decoder.userInfo)
    }
}

private struct PTTreeUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    private let decoder: PTModelTreeDecoder
    private let values: [PTJSONValue]
    var currentIndex: Int = 0

    var codingPath: [any CodingKey] { decoder.codingPath }
    var count: Int? { values.count }
    var isAtEnd: Bool { currentIndex >= values.count }

    init(decoder: PTModelTreeDecoder) {
        self.decoder = decoder
        if case .array(let values) = decoder.value { self.values = values } else { self.values = [] }
    }

    mutating func decodeNil() throws -> Bool {
        guard !isAtEnd else { throw PTModelError.missingValue("[\(currentIndex)]") }
        guard values[currentIndex] == .null else { return false }
        currentIndex += 1
        return true
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard !isAtEnd else { throw PTModelError.missingValue("[\(currentIndex)]") }
        let index = currentIndex
        currentIndex += 1
        return try PTModelTreeDecoder(value: values[index],
                                      options: decoder.options,
                                      codingPath: decoder.codingPath + [PTTreeIndexKey(intValue: index)],
                                      userInfo: decoder.userInfo).decode(type)
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey>
    where NestedKey: CodingKey {
        try decode(PTJSONValue.self).asKeyedContainer(options: decoder.options,
                                                       codingPath: decoder.codingPath + [PTTreeIndexKey(intValue: currentIndex - 1)],
                                                       userInfo: decoder.userInfo,
                                                       keyType: type)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        let value = try decode(PTJSONValue.self)
        return try PTModelTreeDecoder(value: value,
                                      options: decoder.options,
                                      codingPath: decoder.codingPath + [PTTreeIndexKey(intValue: currentIndex - 1)],
                                      userInfo: decoder.userInfo).unkeyedContainer()
    }

    mutating func superDecoder() throws -> Decoder {
        let value = try decode(PTJSONValue.self)
        return PTModelTreeDecoder(value: value,
                                  options: decoder.options,
                                  codingPath: decoder.codingPath + [PTTreeIndexKey(intValue: currentIndex - 1)],
                                  userInfo: decoder.userInfo)
    }
}

private struct PTTreeSingleValueDecodingContainer: SingleValueDecodingContainer {
    private let decoder: PTModelTreeDecoder
    var codingPath: [any CodingKey] { decoder.codingPath }

    init(decoder: PTModelTreeDecoder) { self.decoder = decoder }

    func decodeNil() -> Bool { decoder.value == .null }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try decoder.decode(type)
    }

    func decode(_ type: Bool.Type) throws -> Bool { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: String.Type) throws -> String { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: Double.Type) throws -> Double { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: Float.Type) throws -> Float { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: Int.Type) throws -> Int { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: Int8.Type) throws -> Int8 { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: Int16.Type) throws -> Int16 { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: Int32.Type) throws -> Int32 { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: Int64.Type) throws -> Int64 { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: UInt.Type) throws -> UInt { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try decoder.decodePrimitiveValue(type) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { try decoder.decodePrimitiveValue(type) }
}

private extension PTModelTreeDecoder {
    func decodePrimitiveValue<T: Decodable>(_ type: T.Type) throws -> T {
        guard let value = try decodeScalar(type) else {
            throw PTModelError.typeMismatch(expected: String(reflecting: type), actual: self.value.typeName)
        }
        return value
    }
}

fileprivate extension PTJSONValue {
    var typeName: String {
        switch self {
        case .null: return "null"
        case .bool: return "bool"
        case .number: return "number"
        case .string: return "string"
        case .array: return "array"
        case .object: return "object"
        }
    }

    func asKeyedContainer<Key: CodingKey>(options: PTTreeDecodingOptions,
                                          codingPath: [any CodingKey],
                                          userInfo: [CodingUserInfoKey: Any],
                                          keyType: Key.Type) throws -> KeyedDecodingContainer<Key> {
        try PTModelTreeDecoder(value: self,
                               options: options,
                               codingPath: codingPath,
                               userInfo: userInfo).container(keyedBy: keyType)
    }
}

private struct PTTreeIndexKey: CodingKey {
    let intValue: Int?
    let stringValue: String

    init(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = Int(stringValue)
    }
}

extension PTModelDecoder {
    func treeDecode<T: Decodable>(_ type: T.Type,
                                  from value: PTJSONValue) throws -> T {
        let options = PTTreeDecodingOptions(policy: policy,
                                            dateStrategy: dateStrategy,
                                            dataStrategy: dataStrategy,
                                            floatingPointStrategy: floatingPointStrategy,
                                            urlStrategy: urlStrategy,
                                            coercion: coercionPolicy,
                                            numericOverflowPolicy: numericOverflowPolicy)
        return try PTModelTreeDecoder(value: value, options: options).decode(type)
    }
}
