//
//  PTJSONValue.swift
//
// English: A Foundation-only JSON value tree with exact numeric lexemes.
// Español: Un árbol JSON basado solo en Foundation que conserva los lexemas numéricos exactos.
// 中文：仅依赖 Foundation 且保留数字原始字面量的 JSON 值树。
//

import Foundation

public struct PTJSONNumber: Sendable, Hashable, Codable, Equatable {
    public let rawRepresentation: String

    public init(_ rawRepresentation: String) throws {
        guard !rawRepresentation.isEmpty else {
            throw PTModelError.invalidJSON("Empty number")
        }
        self.rawRepresentation = rawRepresentation
    }

    public var int64Value: Int64? { Int64(rawRepresentation) }
    public var uint64Value: UInt64? { UInt64(rawRepresentation) }
    public var decimalValue: Decimal? { Decimal(string: rawRepresentation, locale: Locale(identifier: "en_US_POSIX")) }
    public var doubleValue: Double? { Double(rawRepresentation) }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let integer = try? container.decode(Int64.self) {
            rawRepresentation = String(integer)
            return
        }
        if let decimal = try? container.decode(Decimal.self) {
            rawRepresentation = NSDecimalNumber(decimal: decimal).stringValue
            return
        }
        throw PTModelError.typeMismatch(expected: "JSON number", actual: "non-number")
    }

    public func encode(to encoder: Encoder) throws {
        guard let decimalValue else {
            throw PTModelError.invalidJSON("Number cannot be represented by Decimal")
        }
        var container = encoder.singleValueContainer()
        try container.encode(decimalValue)
    }
}

public enum PTJSONValue: Sendable, Equatable, Hashable, Codable {
    case null
    case bool(Bool)
    case number(PTJSONNumber)
    case string(String)
    case array([PTJSONValue])
    case object([String: PTJSONValue])

    public init(data: Data,
                duplicateKeyPolicy: PTDuplicateKeyPolicy = .keepLast,
                limits: PTModelLimits = .init()) throws {
        guard data.count <= limits.maxInputBytes else { throw PTModelError.inputTooLarge }
        self = try PTJSONParser(data: data,
                                duplicateKeyPolicy: duplicateKeyPolicy,
                                limits: limits).parse()
    }

    public init(jsonString: String,
                duplicateKeyPolicy: PTDuplicateKeyPolicy = .keepLast,
                limits: PTModelLimits = .init()) throws {
        try self.init(data: Data(jsonString.utf8),
                      duplicateKeyPolicy: duplicateKeyPolicy,
                      limits: limits)
    }

    public var foundationObject: Any {
        switch self {
        case .null:
            return NSNull()
        case .bool(let value):
            return NSNumber(value: value)
        case .number(let value):
            if let integer = value.int64Value { return NSNumber(value: integer) }
            if let decimal = value.decimalValue { return NSDecimalNumber(decimal: decimal) }
            if let double = value.doubleValue { return NSNumber(value: double) }
            return value.rawRepresentation
        case .string(let value):
            return value
        case .array(let values):
            return values.map(\.foundationObject)
        case .object(let values):
            return values.mapValues(\.foundationObject)
        }
    }

    public func jsonData(prettyPrinted: Bool = false, sortedKeys: Bool = true) throws -> Data {
        try PTJSONWriter(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys).write(self)
    }

    public func jsonString(prettyPrinted: Bool = false, sortedKeys: Bool = true) throws -> String {
        let data = try jsonData(prettyPrinted: prettyPrinted, sortedKeys: sortedKeys)
        guard let string = String(data: data, encoding: .utf8) else {
            throw PTModelError.conversionFailed("JSON is not valid UTF-8")
        }
        return string
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .number(try PTJSONNumber(String(value)))
        } else if let value = try? container.decode(Decimal.self) {
            self = .number(try PTJSONNumber(NSDecimalNumber(decimal: value).stringValue))
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([PTJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: PTJSONValue].self) {
            self = .object(value)
        } else {
            throw PTModelError.typeMismatch(expected: "JSON value", actual: "unsupported")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            guard let decimal = value.decimalValue else {
                throw PTModelError.invalidJSON("Number cannot be encoded by Codable")
            }
            try container.encode(decimal)
        case .string(let value):
            try container.encode(value)
        case .array(let values):
            try container.encode(values)
        case .object(let values):
            try container.encode(values)
        }
    }
}

private struct PTJSONParser {
    private let bytes: [UInt8]
    private var index: Int = 0
    private let duplicateKeyPolicy: PTDuplicateKeyPolicy
    private let limits: PTModelLimits

    init(data: Data, duplicateKeyPolicy: PTDuplicateKeyPolicy, limits: PTModelLimits) {
        bytes = Array(data)
        self.duplicateKeyPolicy = duplicateKeyPolicy
        self.limits = limits
    }

    func parse() throws -> PTJSONValue {
        var parser = self
        parser.skipWhitespace()
        let value = try parser.parseValue(depth: 0)
        parser.skipWhitespace()
        guard parser.index == parser.bytes.count else {
            throw PTModelError.invalidJSON("Trailing characters at byte \(parser.index)")
        }
        return value
    }

    private mutating func parseValue(depth: Int) throws -> PTJSONValue {
        guard depth <= limits.maxDepth else { throw PTModelError.depthLimitExceeded }
        skipWhitespace()
        guard let byte = currentByte else { throw PTModelError.invalidJSON("Unexpected end of input") }
        switch byte {
        case 0x6E:
            try consumeLiteral("null")
            return .null
        case 0x74:
            try consumeLiteral("true")
            return .bool(true)
        case 0x66:
            try consumeLiteral("false")
            return .bool(false)
        case 0x22:
            return .string(try parseString())
        case 0x5B:
            return try parseArray(depth: depth + 1)
        case 0x7B:
            return try parseObject(depth: depth + 1)
        case 0x2D, 0x30...0x39:
            return .number(try parseNumber())
        default:
            throw PTModelError.invalidJSON("Unexpected byte \(byte)")
        }
    }

    private mutating func parseArray(depth: Int) throws -> PTJSONValue {
        try consume(0x5B)
        skipWhitespace()
        var values: [PTJSONValue] = []
        if currentByte == 0x5D {
            index += 1
            return .array(values)
        }
        while true {
            values.append(try parseValue(depth: depth))
            skipWhitespace()
            if currentByte == 0x5D {
                index += 1
                return .array(values)
            }
            try consume(0x2C)
        }
    }

    private mutating func parseObject(depth: Int) throws -> PTJSONValue {
        try consume(0x7B)
        skipWhitespace()
        var values: [String: PTJSONValue] = [:]
        if currentByte == 0x7D {
            index += 1
            return .object(values)
        }
        while true {
            guard currentByte == 0x22 else { throw PTModelError.invalidJSON("Object key must be a string") }
            let key = try parseString()
            skipWhitespace()
            try consume(0x3A)
            let value = try parseValue(depth: depth)
            if values[key] != nil {
                switch duplicateKeyPolicy {
                case .keepFirst:
                    break
                case .keepLast:
                    values[key] = value
                case .reject:
                    throw PTModelError.duplicateKey(key)
                }
            } else {
                values[key] = value
            }
            skipWhitespace()
            if currentByte == 0x7D {
                index += 1
                return .object(values)
            }
            try consume(0x2C)
            skipWhitespace()
        }
    }

    private mutating func parseString() throws -> String {
        try consume(0x22)
        var output: [UInt8] = []
        while let byte = currentByte {
            index += 1
            switch byte {
            case 0x22:
                guard let result = String(bytes: output, encoding: .utf8) else {
                    throw PTModelError.invalidJSON("Invalid UTF-8 string")
                }
                return result
            case 0x5C:
                guard let escape = currentByte else { throw PTModelError.invalidJSON("Unfinished escape") }
                index += 1
                switch escape {
                case 0x22, 0x5C, 0x2F: output.append(escape)
                case 0x62: output.append(0x08)
                case 0x66: output.append(0x0C)
                case 0x6E: output.append(0x0A)
                case 0x72: output.append(0x0D)
                case 0x74: output.append(0x09)
                case 0x75:
                    let scalar = try parseUnicodeScalar()
                    output.append(contentsOf: String(scalar).utf8)
                default:
                    throw PTModelError.invalidJSON("Unknown escape")
                }
            case 0x00...0x1F:
                throw PTModelError.invalidJSON("Unescaped control character")
            default:
                output.append(byte)
            }
        }
        throw PTModelError.invalidJSON("Unterminated string")
    }

    private mutating func parseUnicodeScalar() throws -> UnicodeScalar {
        guard index + 4 <= bytes.count else { throw PTModelError.invalidJSON("Incomplete unicode escape") }
        var value: UInt32 = 0
        for _ in 0..<4 {
            guard let digit = hexValue(bytes[index]) else { throw PTModelError.invalidJSON("Invalid unicode escape") }
            value = value * 16 + UInt32(digit)
            index += 1
        }
        guard let scalar = UnicodeScalar(value) else { throw PTModelError.invalidJSON("Invalid unicode scalar") }
        return scalar
    }

    private mutating func parseNumber() throws -> PTJSONNumber {
        let start = index
        if currentByte == 0x2D { index += 1 }
        guard currentByte != nil else { throw PTModelError.invalidJSON("Incomplete number") }
        if currentByte == 0x30 {
            index += 1
        } else {
            guard let byte = currentByte, (0x31...0x39).contains(byte) else {
                throw PTModelError.invalidJSON("Invalid number")
            }
            while let byte = currentByte, (0x30...0x39).contains(byte) { index += 1 }
        }
        if currentByte == 0x2E {
            index += 1
            guard let byte = currentByte, (0x30...0x39).contains(byte) else {
                throw PTModelError.invalidJSON("Invalid fraction")
            }
            while let byte = currentByte, (0x30...0x39).contains(byte) { index += 1 }
        }
        if currentByte == 0x65 || currentByte == 0x45 {
            index += 1
            if currentByte == 0x2B || currentByte == 0x2D { index += 1 }
            guard let byte = currentByte, (0x30...0x39).contains(byte) else {
                throw PTModelError.invalidJSON("Invalid exponent")
            }
            while let byte = currentByte, (0x30...0x39).contains(byte) { index += 1 }
        }
        let raw = String(decoding: bytes[start..<index], as: UTF8.self)
        return try PTJSONNumber(raw)
    }

    private mutating func consume(_ byte: UInt8) throws {
        guard currentByte == byte else { throw PTModelError.invalidJSON("Expected byte \(byte)") }
        index += 1
    }

    private mutating func consumeLiteral(_ literal: String) throws {
        let literalBytes = Array(literal.utf8)
        guard index + literalBytes.count <= bytes.count,
              Array(bytes[index..<(index + literalBytes.count)]) == literalBytes else {
            throw PTModelError.invalidJSON("Invalid literal")
        }
        index += literalBytes.count
    }

    private mutating func skipWhitespace() {
        while let byte = currentByte, byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
            index += 1
        }
    }

    private var currentByte: UInt8? {
        guard index < bytes.count else { return nil }
        return bytes[index]
    }

    private func hexValue(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 0x30...0x39: return byte - 0x30
        case 0x41...0x46: return byte - 0x41 + 10
        case 0x61...0x66: return byte - 0x61 + 10
        default: return nil
        }
    }
}

private struct PTJSONWriter {
    let prettyPrinted: Bool
    let sortedKeys: Bool

    func write(_ value: PTJSONValue) throws -> Data {
        var bytes: [UInt8] = []
        try append(value, to: &bytes, depth: 0)
        return Data(bytes)
    }

    private func append(_ value: PTJSONValue, to bytes: inout [UInt8], depth: Int) throws {
        switch value {
        case .null:
            bytes.append(contentsOf: Array("null".utf8))
        case .bool(let value):
            bytes.append(contentsOf: Array((value ? "true" : "false").utf8))
        case .number(let value):
            guard !value.rawRepresentation.isEmpty else { throw PTModelError.invalidJSON("Empty number") }
            bytes.append(contentsOf: Array(value.rawRepresentation.utf8))
        case .string(let value):
            appendString(value, to: &bytes)
        case .array(let values):
            bytes.append(0x5B)
            for (offset, item) in values.enumerated() {
                if offset > 0 { bytes.append(0x2C) }
                appendIndent(to: &bytes, depth: depth + 1, first: offset == 0)
                try append(item, to: &bytes, depth: depth + 1)
            }
            appendIndent(to: &bytes, depth: depth, first: values.isEmpty)
            bytes.append(0x5D)
        case .object(let values):
            bytes.append(0x7B)
            let keys = sortedKeys ? values.keys.sorted() : Array(values.keys)
            for (offset, key) in keys.enumerated() {
                if offset > 0 { bytes.append(0x2C) }
                appendIndent(to: &bytes, depth: depth + 1, first: offset == 0)
                appendString(key, to: &bytes)
                bytes.append(0x3A)
                if prettyPrinted { bytes.append(0x20) }
                if let item = values[key] { try append(item, to: &bytes, depth: depth + 1) }
            }
            appendIndent(to: &bytes, depth: depth, first: keys.isEmpty)
            bytes.append(0x7D)
        }
    }

    private func appendString(_ value: String, to bytes: inout [UInt8]) {
        bytes.append(0x22)
        for byte in value.utf8 {
            switch byte {
            case 0x22: bytes.append(contentsOf: Array("\\\"".utf8))
            case 0x5C: bytes.append(contentsOf: Array("\\\\".utf8))
            case 0x08: bytes.append(contentsOf: Array("\\b".utf8))
            case 0x0C: bytes.append(contentsOf: Array("\\f".utf8))
            case 0x0A: bytes.append(contentsOf: Array("\\n".utf8))
            case 0x0D: bytes.append(contentsOf: Array("\\r".utf8))
            case 0x09: bytes.append(contentsOf: Array("\\t".utf8))
            case 0x00...0x1F:
                let escaped = String(format: "\\u%04x", byte)
                bytes.append(contentsOf: Array(escaped.utf8))
            default: bytes.append(byte)
            }
        }
        bytes.append(0x22)
    }

    private func appendIndent(to bytes: inout [UInt8], depth: Int, first: Bool) {
        guard prettyPrinted else { return }
        if first {
            bytes.append(0x0A)
        } else {
            bytes.append(0x0A)
        }
        bytes.append(contentsOf: Array(repeating: 0x20, count: depth * 2))
    }
}

// English: Foundation values enter the model layer through one recursive, bounded bridge.
// Español: Los valores de Foundation entran mediante un único puente recursivo y limitado.
// 中文：Foundation 值通过一个有深度限制的递归桥接统一进入模型层。
enum PTFoundationJSONBridge {
    static func value(from object: Any, depth: Int = 0, limits: PTModelLimits = .init()) throws -> PTJSONValue {
        guard depth <= limits.maxDepth else { throw PTModelError.depthLimitExceeded }
        if object is NSNull { return .null }
        if let value = object as? PTJSONValue { return value }
        if let value = object as? String { return .string(value) }
        if let value = object as? NSString { return .string(String(value)) }
        if let value = object as? Bool { return .bool(value) }
        if let value = object as? NSNumber {
            let type = String(cString: value.objCType)
            if type == "c" { return .bool(value.boolValue) }
            return .number(try PTJSONNumber(value.stringValue))
        }
        if let value = object as? Decimal {
            return .number(try PTJSONNumber(NSDecimalNumber(decimal: value).stringValue))
        }
        if let value = object as? NSDecimalNumber {
            return .number(try PTJSONNumber(value.stringValue))
        }
        if let value = object as? URL { return .string(value.absoluteString) }
        if let value = object as? NSURL { return .string(value.absoluteString ?? "") }
        if let value = object as? Date {
            return .string(ISO8601DateFormatter().string(from: value))
        }
        if let value = object as? Data {
            return .string(value.base64EncodedString())
        }
        if let value = object as? [String: Any] {
            var result: [String: PTJSONValue] = [:]
            for (key, nested) in value {
                result[key] = try self.value(from: nested, depth: depth + 1, limits: limits)
            }
            return .object(result)
        }
        if let value = object as? [Any] {
            return .array(try value.map { try self.value(from: $0, depth: depth + 1, limits: limits) })
        }
        if let value = object as? NSDictionary {
            var result: [String: PTJSONValue] = [:]
            for (key, nested) in value {
                guard let key = key as? String else {
                    throw PTModelError.conversionFailed("Dictionary key is not String")
                }
                result[key] = try self.value(from: nested, depth: depth + 1, limits: limits)
            }
            return .object(result)
        }
        if let value = object as? NSArray {
            return .array(try value.map { try self.value(from: $0, depth: depth + 1, limits: limits) })
        }
        if let value = object as? NSSet {
            return .array(try value.allObjects.map { try self.value(from: $0, depth: depth + 1, limits: limits) })
        }
        throw PTModelError.unsupportedSource(String(reflecting: type(of: object)))
    }
}
