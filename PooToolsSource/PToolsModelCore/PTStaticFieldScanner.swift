//
//  PTStaticFieldScanner.swift
//
// English: Scan top-level object fields as bounded byte slices for static-schema fast paths.
// Español: Escanea campos de objetos de nivel superior como slices de bytes acotados para fast paths estáticos.
// 中文：将顶层对象字段扫描为有界字节切片，供静态 Schema Fast Path 使用。
//

import Foundation

public struct PTJSONFieldSlice: Sendable, Hashable, Equatable {
    public let key: String
    public let data: Data

    public init(key: String, data: Data) {
        self.key = key
        self.data = data
    }
}

// English: This scanner skips unknown values without constructing a full PTJSONValue object tree.
// Español: Este scanner omite valores desconocidos sin construir un árbol completo de PTJSONValue.
// 中文：该 Scanner 可以跳过未知值，不构建完整 PTJSONValue 对象树。
public struct PTJSONFieldScanner: Sendable {
    private let data: Data
    private let limits: PTModelLimits
    private var index = 0
    private var started = false
    private var finished = false
    private var expectsSeparator = false

    public init(data: Data, limits: PTModelLimits = .init()) throws {
        guard data.count <= limits.maxInputBytes else { throw PTModelError.inputTooLarge }
        self.data = data
        self.limits = limits
    }

    public mutating func next() throws -> PTJSONFieldSlice? {
        guard !finished else { return nil }
        if !started {
            started = true
            skipWhitespace()
            try consume(0x7B)
        } else if expectsSeparator {
            skipWhitespace()
            if currentByte == 0x2C {
                index += 1
                skipWhitespace()
                guard currentByte != 0x7D else {
                    finished = true
                    index += 1
                    throw PTModelError.invalidJSON("Trailing comma in object")
                }
            } else if currentByte == 0x7D {
                finished = true
                index += 1
                skipWhitespace()
                guard index == data.count else {
                    throw PTModelError.invalidJSON("Trailing characters after object")
                }
                return nil
            } else {
                throw PTModelError.invalidJSON("Expected comma between object fields")
            }
        }

        skipWhitespace()
        if currentByte == 0x7D {
            finished = true
            index += 1
            skipWhitespace()
            guard index == data.count else {
                throw PTModelError.invalidJSON("Trailing characters after object")
            }
            return nil
        }

        let keyStart = index
        let keyEnd = try skipString()
        let keyData = Data(data[keyStart..<keyEnd])
        guard let key = try JSONSerialization.jsonObject(with: keyData,
                                                          options: [.fragmentsAllowed]) as? String else {
            throw PTModelError.invalidJSON("Object key is not a string")
        }
        skipWhitespace()
        try consume(0x3A)
        skipWhitespace()
        let valueStart = index
        try skipValue(depth: 0)
        let valueData = Data(data[valueStart..<index])
        expectsSeparator = true
        return PTJSONFieldSlice(key: key, data: valueData)
    }

    public mutating func collect(duplicateKeyPolicy: PTDuplicateKeyPolicy = .keepLast) throws -> [String: Data] {
        var result: [String: Data] = [:]
        while let field = try next() {
            if result[field.key] != nil {
                switch duplicateKeyPolicy {
                case .keepFirst: continue
                case .keepLast: result[field.key] = field.data
                case .reject: throw PTModelError.duplicateKey(field.key)
                }
            } else {
                result[field.key] = field.data
            }
        }
        return result
    }

    private mutating func skipValue(depth: Int) throws {
        guard depth <= limits.maxDepth else { throw PTModelError.depthLimitExceeded }
        skipWhitespace()
        guard let byte = currentByte else { throw PTModelError.invalidJSON("Unexpected end of input") }
        switch byte {
        case 0x22:
            _ = try skipString()
        case 0x7B:
            try skipObject(depth: depth + 1)
        case 0x5B:
            try skipArray(depth: depth + 1)
        case 0x2D, 0x30...0x39:
            try skipNumber()
        case 0x74:
            try consumeLiteral("true")
        case 0x66:
            try consumeLiteral("false")
        case 0x6E:
            try consumeLiteral("null")
        default:
            throw PTModelError.invalidJSON("Unexpected byte \(byte)")
        }
    }

    private mutating func skipObject(depth: Int) throws {
        try consume(0x7B)
        skipWhitespace()
        if currentByte == 0x7D { index += 1; return }
        var keyCount = 0
        while true {
            guard keyCount < limits.maxObjectKeyCount else { throw PTModelError.objectKeyLimitExceeded }
            keyCount += 1
            _ = try skipString()
            skipWhitespace()
            try consume(0x3A)
            try skipValue(depth: depth)
            skipWhitespace()
            if currentByte == 0x7D { index += 1; return }
            try consume(0x2C)
            skipWhitespace()
        }
    }

    private mutating func skipArray(depth: Int) throws {
        try consume(0x5B)
        skipWhitespace()
        if currentByte == 0x5D { index += 1; return }
        var count = 0
        while true {
            guard count < limits.maxCollectionCount else { throw PTModelError.collectionLimitExceeded }
            count += 1
            try skipValue(depth: depth)
            skipWhitespace()
            if currentByte == 0x5D { index += 1; return }
            try consume(0x2C)
            skipWhitespace()
        }
    }

    private mutating func skipString() throws -> Int {
        try consume(0x22)
        var byteCount = 0
        while let byte = currentByte {
            index += 1
            if byte == 0x22 { return index }
            if byte == 0x5C {
                guard let escaped = currentByte else { throw PTModelError.invalidJSON("Unfinished escape") }
                index += 1
                if escaped == 0x75 {
                    guard index + 4 <= data.count else { throw PTModelError.invalidJSON("Incomplete unicode escape") }
                    index += 4
                }
            } else if byte <= 0x1F {
                throw PTModelError.invalidJSON("Unescaped control character")
            }
            byteCount += 1
            guard byteCount <= limits.maxStringBytes else { throw PTModelError.stringLimitExceeded }
        }
        throw PTModelError.invalidJSON("Unterminated string")
    }

    private mutating func skipNumber() throws {
        let start = index
        if currentByte == 0x2D { index += 1 }
        guard currentByte != nil else { throw PTModelError.invalidJSON("Incomplete number") }
        if currentByte == 0x30 {
            index += 1
        } else {
            guard let byte = currentByte, (0x31...0x39).contains(byte) else { throw PTModelError.invalidJSON("Invalid number") }
            while let byte = currentByte, (0x30...0x39).contains(byte) { index += 1 }
        }
        if currentByte == 0x2E {
            index += 1
            guard let byte = currentByte, (0x30...0x39).contains(byte) else { throw PTModelError.invalidJSON("Invalid fraction") }
            while let byte = currentByte, (0x30...0x39).contains(byte) { index += 1 }
        }
        if currentByte == 0x65 || currentByte == 0x45 {
            index += 1
            if currentByte == 0x2B || currentByte == 0x2D { index += 1 }
            guard let byte = currentByte, (0x30...0x39).contains(byte) else { throw PTModelError.invalidJSON("Invalid exponent") }
            while let byte = currentByte, (0x30...0x39).contains(byte) { index += 1 }
        }
        let digitCount = data[start..<index].reduce(into: 0) { count, byte in
            if (0x30...0x39).contains(byte) { count += 1 }
        }
        guard digitCount <= limits.maxNumberDigits else { throw PTModelError.numberDigitLimitExceeded }
    }

    private mutating func consume(_ byte: UInt8) throws {
        guard currentByte == byte else { throw PTModelError.invalidJSON("Expected byte \(byte)") }
        index += 1
    }

    private mutating func consumeLiteral(_ literal: String) throws {
        let bytes = Array(literal.utf8)
        guard index + bytes.count <= data.count,
              Array(data[index..<(index + bytes.count)]) == bytes else {
            throw PTModelError.invalidJSON("Invalid literal")
        }
        index += bytes.count
    }

    private mutating func skipWhitespace() {
        while let byte = currentByte,
              byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
            index += 1
        }
    }

    private var currentByte: UInt8? {
        guard index < data.count else { return nil }
        return data[index]
    }
}

// English: Dispatch only requested keys and decode their slices; unknown keys are skipped by the scanner.
// Español: Solo despacha las claves solicitadas y decodifica sus slices; el scanner omite las claves desconocidas.
// 中文：只分发请求字段并解析对应切片，未知字段由 Scanner 直接跳过。
public enum PTStaticFieldDispatcher {
    public static func decodeValues(from data: Data,
                                    fields: [PTModelFieldDescriptor],
                                    decoder: PTModelDecoder = .init()) throws -> [String: PTJSONValue] {
        var dispatch: [UInt64: [(String, String)]] = [:]
        for field in fields {
            for key in field.mapping.decodeKeys {
                dispatch[PTStableKeyHash.hash(key), default: []].append((key, field.name))
            }
        }
        var scanner = try PTJSONFieldScanner(data: data, limits: decoder.limits)
        var result: [String: PTJSONValue] = [:]
        while let field = try scanner.next() {
            guard let candidates = dispatch[PTStableKeyHash.hash(field.key)],
                  let (_, property) = candidates.first(where: { $0.0 == field.key }) else { continue }
            let value = try PTJSONValue(data: field.data,
                                        duplicateKeyPolicy: decoder.duplicateKeyPolicy,
                                        limits: decoder.limits)
            switch decoder.duplicateKeyPolicy {
            case .keepFirst where result[property] != nil:
                continue
            case .reject where result[property] != nil:
                throw PTModelError.duplicateKey(property)
            default:
                result[property] = value
            }
        }
        return result
    }
}
