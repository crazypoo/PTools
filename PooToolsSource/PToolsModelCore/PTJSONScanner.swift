//
//  PTJSONScanner.swift
//
// English: A bounded scanner can skip unknown JSON values without building a tree or copying the input buffer.
// Español: Un scanner acotado puede omitir valores JSON desconocidos sin crear un árbol ni copiar el buffer.
// 中文：有界 Scanner 可以跳过未知 JSON 值，不构建整棵树，也不复制输入缓冲区。
//

import Foundation

public struct PTJSONScanner: Sendable {
    public let data: Data
    public private(set) var index: Int
    public let limits: PTModelLimits

    public init(data: Data, limits: PTModelLimits = .init()) throws {
        guard data.count <= limits.maxInputBytes else { throw PTModelError.inputTooLarge }
        self.data = data
        self.index = 0
        self.limits = limits
    }

    public var isAtEnd: Bool {
        var copy = self
        copy.skipWhitespace()
        return copy.index == data.count
    }

    public mutating func skipValue() throws {
        try skipValue(depth: 0)
    }

    public mutating func skipUnknownSubtree() throws {
        try skipValue()
    }

    // English: Return bounded raw slices for one JSON array without building an intermediate PTJSONValue tree.
    // Español: Devuelve slices JSON acotados para un array sin construir un árbol PTJSONValue intermedio.
    // 中文：在不构建中间 PTJSONValue 树的情况下，返回 JSON 数组中每个元素的有界原始切片。
    public mutating func collectArrayElementSlices() throws -> [Data] {
        skipWhitespace()
        try consume(0x5B)
        skipWhitespace()
        if currentByte == 0x5D {
            index += 1
            skipWhitespace()
            guard index == data.count else {
                throw PTModelError.invalidJSON("Trailing bytes after array")
            }
            return []
        }

        var slices: [Data] = []
        slices.reserveCapacity(min(limits.maxCollectionCount, 16))
        while true {
            guard slices.count < limits.maxCollectionCount else {
                throw PTModelError.collectionLimitExceeded
            }
            skipWhitespace()
            let start = index
            try skipValue(depth: 1)
            let end = index
            slices.append(data.subdata(in: start..<end))

            skipWhitespace()
            if currentByte == 0x5D {
                index += 1
                skipWhitespace()
                guard index == data.count else {
                    throw PTModelError.invalidJSON("Trailing bytes after array")
                }
                return slices
            }
            try consume(0x2C)
        }
    }

    public mutating func skipWhitespace() {
        while let byte = currentByte,
              byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
            index += 1
        }
    }

    private mutating func skipValue(depth: Int) throws {
        guard depth <= limits.maxDepth else { throw PTModelError.depthLimitExceeded }
        skipWhitespace()
        guard let byte = currentByte else { throw PTModelError.invalidJSON("Unexpected end of input") }
        switch byte {
        case 0x22:
            try skipString()
        case 0x5B:
            try skipCollection(open: 0x5B, close: 0x5D, depth: depth + 1)
        case 0x7B:
            try skipObject(depth: depth + 1)
        case 0x2D, 0x30...0x39:
            try skipNumber()
        case 0x74:
            try consume("true")
        case 0x66:
            try consume("false")
        case 0x6E:
            try consume("null")
        default:
            throw PTModelError.invalidJSON("Unexpected byte \(byte)")
        }
    }

    private mutating func skipCollection(open: UInt8, close: UInt8, depth: Int) throws {
        try consume(open)
        skipWhitespace()
        if currentByte == close {
            index += 1
            return
        }
        var count = 0
        while true {
            guard count < limits.maxCollectionCount else { throw PTModelError.collectionLimitExceeded }
            try skipValue(depth: depth)
            count += 1
            skipWhitespace()
            if currentByte == close {
                index += 1
                return
            }
            try consume(0x2C)
        }
    }

    private mutating func skipObject(depth: Int) throws {
        try consume(0x7B)
        skipWhitespace()
        if currentByte == 0x7D {
            index += 1
            return
        }
        var count = 0
        while true {
            guard count < limits.maxObjectKeyCount, currentByte == 0x22 else {
                throw PTModelError.objectKeyLimitExceeded
            }
            try skipString()
            skipWhitespace()
            try consume(0x3A)
            try skipValue(depth: depth)
            count += 1
            skipWhitespace()
            if currentByte == 0x7D {
                index += 1
                return
            }
            try consume(0x2C)
            skipWhitespace()
        }
    }

    private mutating func skipString() throws {
        try consume(0x22)
        var bytes = 0
        while let byte = currentByte {
            index += 1
            if byte == 0x22 { return }
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
            bytes += 1
            guard bytes <= limits.maxStringBytes else { throw PTModelError.stringLimitExceeded }
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
        let digitCount = data[start..<index].reduce(into: 0) { count, byte in
            if (0x30...0x39).contains(byte) { count += 1 }
        }
        guard digitCount <= limits.maxNumberDigits else { throw PTModelError.numberDigitLimitExceeded }
    }

    private mutating func consume(_ byte: UInt8) throws {
        guard currentByte == byte else { throw PTModelError.invalidJSON("Expected byte \(byte)") }
        index += 1
    }

    private mutating func consume(_ literal: String) throws {
        let bytes = Data(literal.utf8)
        guard index + bytes.count <= data.count,
              data[index..<(index + bytes.count)] == bytes else {
            throw PTModelError.invalidJSON("Invalid literal")
        }
        index += bytes.count
    }

    private var currentByte: UInt8? {
        guard index < data.count else { return nil }
        return data[index]
    }
}
