//
//  PTModelTreeEncoder.swift
//
// English: A Foundation-only tree encoder that makes PTModel nil and value policies observable.
// Español: Un encoder de árbol basado solo en Foundation que hace observables las políticas nil y de valor de PTModel.
// 中文：仅依赖 Foundation 的树编码器，让 PTModel 的 nil 和值策略真正生效。
//

import Foundation

private struct PTTreeEncodingOptions: Sendable {
    let nilStrategy: PTNilEncodingStrategy
    let dateStrategy: PTDateEncodingStrategy
    let dataStrategy: PTDataEncodingStrategy
    let floatingPointStrategy: PTFloatingPointStrategy
    let urlStrategy: PTURLCodingStrategy
}

private final class PTTreeEncodingNode {
    var value: PTJSONValue? {
        didSet { onChange?() }
    }
    var onChange: (() -> Void)?

    init(value: PTJSONValue? = nil) {
        self.value = value
    }
}

private final class PTModelTreeEncoder: Encoder {
    let node: PTTreeEncodingNode
    let options: PTTreeEncodingOptions
    let codingPath: [any CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    init(node: PTTreeEncodingNode,
         options: PTTreeEncodingOptions,
         codingPath: [any CodingKey] = [],
         userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.node = node
        self.options = options
        self.codingPath = codingPath
        self.userInfo = userInfo
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        if node.value == nil { node.value = .object([:]) }
        return KeyedEncodingContainer(PTTreeKeyedEncodingContainer<Key>(encoder: self))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        if node.value == nil { node.value = .array([]) }
        return PTTreeUnkeyedEncodingContainer(encoder: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        PTTreeSingleValueEncodingContainer(encoder: self)
    }

    func encode<T: Encodable>(_ value: T,
                              at codingPath: [any CodingKey]) throws -> PTJSONValue {
        if let value = value as? PTJSONValue { return value }
        if let value = value as? Date {
            return try PTModelFoundationCodec.date(value, strategy: options.dateStrategy)
        }
        if let value = value as? Data {
            return try PTModelFoundationCodec.data(value, strategy: options.dataStrategy)
        }
        if let value = value as? URL {
            return PTModelFoundationCodec.url(value, strategy: options.urlStrategy)
        }
        if let value = value as? Decimal {
            return .number(try PTJSONNumber(NSDecimalNumber(decimal: value).stringValue))
        }
        let child = PTTreeEncodingNode()
        let childEncoder = PTModelTreeEncoder(node: child,
                                               options: options,
                                               codingPath: codingPath,
                                               userInfo: userInfo)
        try value.encode(to: childEncoder)
        guard let result = child.value else {
            throw PTModelError.invalidInput
        }
        return result
    }

    func set(_ value: PTJSONValue) {
        node.value = value
    }

    func set<T: Encodable>(_ value: T) throws {
        node.value = try encode(value, at: codingPath)
    }

    func childNode(_ value: PTJSONValue,
                   forKey key: String) -> PTTreeEncodingNode {
        let child = PTTreeEncodingNode(value: value)
        weak var weakChild: PTTreeEncodingNode?
        weakChild = child
        child.onChange = { [weak parent = node] in
            guard let parent,
                  let weakChild,
                  case .object(var values) = parent.value else { return }
            values[key] = weakChild.value ?? .null
            parent.value = .object(values)
        }
        return child
    }

    func childNode(_ value: PTJSONValue,
                   at index: Int) -> PTTreeEncodingNode {
        let child = PTTreeEncodingNode(value: value)
        weak var weakChild: PTTreeEncodingNode?
        weakChild = child
        child.onChange = { [weak parent = node] in
            guard let parent,
                  let weakChild,
                  case .array(var values) = parent.value,
                  values.indices.contains(index) else { return }
            values[index] = weakChild.value ?? .null
            parent.value = .array(values)
        }
        return child
    }
}

private struct PTTreeKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    private let encoder: PTModelTreeEncoder

    var codingPath: [any CodingKey] { encoder.codingPath }

    init(encoder: PTModelTreeEncoder) { self.encoder = encoder }

    private var object: [String: PTJSONValue] {
        get {
            guard case .object(let value) = encoder.node.value else { return [:] }
            return value
        }
        set { encoder.node.value = .object(newValue) }
    }

    mutating func encodeNil(forKey key: Key) throws {
        var values = object
        switch encoder.options.nilStrategy {
        case .omit:
            values.removeValue(forKey: key.stringValue)
        case .null:
            values[key.stringValue] = .null
        }
        object = values
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        var values = object
        values[key.stringValue] = try encoder.encode(value,
                                                     at: codingPath + [key])
        object = values
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type,
                                             forKey key: Key) -> KeyedEncodingContainer<NestedKey>
    where NestedKey: CodingKey {
        let child = encoder.childNode(.object([:]), forKey: key.stringValue)
        var values = object
        values[key.stringValue] = child.value ?? .object([:])
        object = values
        let childEncoder = PTModelTreeEncoder(node: child,
                                               options: encoder.options,
                                               codingPath: codingPath + [key],
                                               userInfo: encoder.userInfo)
        return KeyedEncodingContainer(PTTreeKeyedEncodingContainer<NestedKey>(encoder: childEncoder))
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let child = encoder.childNode(.array([]), forKey: key.stringValue)
        var values = object
        values[key.stringValue] = child.value ?? .array([])
        object = values
        let childEncoder = PTModelTreeEncoder(node: child,
                                               options: encoder.options,
                                               codingPath: codingPath + [key],
                                               userInfo: encoder.userInfo)
        return PTTreeUnkeyedEncodingContainer(encoder: childEncoder)
    }

    mutating func superEncoder() -> Encoder {
        PTModelTreeEncoder(node: PTTreeEncodingNode(),
                           options: encoder.options,
                           codingPath: codingPath,
                           userInfo: encoder.userInfo)
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        let child = encoder.childNode(.object([:]), forKey: key.stringValue)
        var values = object
        values[key.stringValue] = child.value ?? .object([:])
        object = values
        return PTModelTreeEncoder(node: child,
                                  options: encoder.options,
                                  codingPath: codingPath + [key],
                                  userInfo: encoder.userInfo)
    }

}

private struct PTTreeUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    private let encoder: PTModelTreeEncoder
    

    var codingPath: [any CodingKey] { encoder.codingPath }

    var count: Int {
        guard case .array(let values) = encoder.node.value else { return 0 }
        return values.count
    }

    init(encoder: PTModelTreeEncoder) {
        self.encoder = encoder
    }

    mutating func encodeNil() throws {
        append(.null)
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        append(try encoder.encode(value,
                                  at: codingPath + [PTTreeIndexKey(intValue: count)]) )
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
    where NestedKey: CodingKey {
        let child = encoder.childNode(.object([:]), at: count)
        append(child.value ?? .object([:]))
        let childEncoder = PTModelTreeEncoder(node: child,
                                               options: encoder.options,
                                               codingPath: codingPath + [PTTreeIndexKey(intValue: count - 1)],
                                               userInfo: encoder.userInfo)
        return KeyedEncodingContainer(PTTreeKeyedEncodingContainer<NestedKey>(encoder: childEncoder))
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let child = encoder.childNode(.array([]), at: count)
        append(child.value ?? .array([]))
        let childEncoder = PTModelTreeEncoder(node: child,
                                               options: encoder.options,
                                               codingPath: codingPath + [PTTreeIndexKey(intValue: count - 1)],
                                               userInfo: encoder.userInfo)
        return PTTreeUnkeyedEncodingContainer(encoder: childEncoder)
    }

    mutating func superEncoder() -> Encoder {
        let child = encoder.childNode(.object([:]), at: count)
        append(.null)
        return PTModelTreeEncoder(node: child,
                                  options: encoder.options,
                                  codingPath: codingPath + [PTTreeIndexKey(intValue: count - 1)],
                                  userInfo: encoder.userInfo)
    }

    private mutating func append(_ value: PTJSONValue) {
        guard case .array(var values) = encoder.node.value else {
            encoder.node.value = .array([value])
            return
        }
        values.append(value)
        encoder.node.value = .array(values)
    }
}

private struct PTTreeSingleValueEncodingContainer: SingleValueEncodingContainer {
    private let encoder: PTModelTreeEncoder

    var codingPath: [any CodingKey] { encoder.codingPath }

    init(encoder: PTModelTreeEncoder) {
        self.encoder = encoder
    }

    mutating func encodeNil() throws {
        encoder.set(.null)
    }

    mutating func encode(_ value: Bool) throws { encoder.set(.bool(value)) }
    mutating func encode(_ value: String) throws { encoder.set(.string(value)) }
    mutating func encode(_ value: Double) throws { encoder.set(try number(value)) }
    mutating func encode(_ value: Float) throws { encoder.set(try number(Double(value))) }
    mutating func encode(_ value: Int) throws { encoder.set(try number(String(value))) }
    mutating func encode(_ value: Int8) throws { encoder.set(try number(String(value))) }
    mutating func encode(_ value: Int16) throws { encoder.set(try number(String(value))) }
    mutating func encode(_ value: Int32) throws { encoder.set(try number(String(value))) }
    mutating func encode(_ value: Int64) throws { encoder.set(try number(String(value))) }
    mutating func encode(_ value: UInt) throws { encoder.set(try number(String(value))) }
    mutating func encode(_ value: UInt8) throws { encoder.set(try number(String(value))) }
    mutating func encode(_ value: UInt16) throws { encoder.set(try number(String(value))) }
    mutating func encode(_ value: UInt32) throws { encoder.set(try number(String(value))) }
    mutating func encode(_ value: UInt64) throws { encoder.set(try number(String(value))) }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        encoder.set(try encoder.encode(value, at: codingPath))
    }

    private func number(_ raw: String) throws -> PTJSONValue {
        guard let decimal = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) else {
            throw PTModelError.numericOverflow(raw)
        }
        return .number(try PTJSONNumber(NSDecimalNumber(decimal: decimal).stringValue))
    }

    private func number(_ value: Double) throws -> PTJSONValue {
        if value.isNaN || value.isInfinite {
            guard encoder.options.floatingPointStrategy == .convertToString else {
                throw PTModelError.conversionFailed("Non-conforming floating point value")
            }
            if value.isNaN { return .string("nan") }
            return .string(value.sign == .minus ? "-inf" : "inf")
        }
        return try number(String(value))
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

extension PTModelEncoder {
    func treeJSONValue<T: Encodable>(_ value: T) throws -> PTJSONValue {
        let root = PTTreeEncodingNode()
        let options = PTTreeEncodingOptions(nilStrategy: nilStrategy,
                                             dateStrategy: dateStrategy,
                                             dataStrategy: dataStrategy,
                                             floatingPointStrategy: floatingPointStrategy,
                                             urlStrategy: urlStrategy)
        let encoder = PTModelTreeEncoder(node: root, options: options)
        try value.encode(to: encoder)
        guard let result = root.value else { throw PTModelError.invalidInput }
        return result
    }

}
