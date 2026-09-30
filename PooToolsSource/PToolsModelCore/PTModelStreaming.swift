//
//  PTModelStreaming.swift
//
// English: Bounded top-level array streaming for PTModel decode and encode.
// Español: Streaming acotado de arrays de nivel superior para decodificación y codificación PTModel.
// 中文：PTModel 顶层数组的有界流式解码和编码能力。
//

import Foundation

public struct PTModelStreamDecoder<Item: Decodable & Sendable>: AsyncSequence, Sendable {
    public typealias Element = Item

    public struct AsyncIterator: AsyncIteratorProtocol {
        private var scanner: PTJSONArrayElementScanner
        private let decoder: PTModelDecoder
        private var elementIndex: Int = 0

        fileprivate init(data: Data, decoder: PTModelDecoder) {
            self.scanner = PTJSONArrayElementScanner(data: data)
            self.decoder = decoder
        }

        public mutating func next() async throws -> Item? {
            try Task.checkCancellation()
            guard let elementData = try scanner.nextElementData() else { return nil }
            let currentIndex = elementIndex
            elementIndex += 1
            do {
                return try decoder.decode(Item.self, from: elementData)
            } catch {
                throw PTModelError.streamElementFailed(currentIndex, error.localizedDescription)
            }
        }
    }

    private let data: Data
    private let decoder: PTModelDecoder

    public init(data: Data,
                decoder: PTModelDecoder = .init()) {
        self.data = data
        self.decoder = decoder
    }

    public init(jsonString: String,
                decoder: PTModelDecoder = .init()) {
        self.init(data: Data(jsonString.utf8), decoder: decoder)
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(data: data, decoder: decoder)
    }
}

public protocol PTAsyncJSONByteSink: Sendable {
    func write(_ data: Data) async throws
    func finish() async throws
}

public actor PTAsyncDataByteSink: PTAsyncJSONByteSink {
    private var data = Data()

    public init() {}

    public func write(_ data: Data) async throws {
        self.data.append(data)
    }

    public func finish() async throws {}

    public func value() -> Data { data }
}

public actor PTAsyncFileByteSink: PTAsyncJSONByteSink {
    public let url: URL
    private var handle: FileHandle?

    public init(url: URL) {
        self.url = url
    }

    public func write(_ data: Data) async throws {
        if handle == nil {
            FileManager.default.createFile(atPath: url.path, contents: nil)
            handle = try FileHandle(forWritingTo: url)
        }
        try handle?.seekToEnd()
        try handle?.write(contentsOf: data)
    }

    public func finish() async throws {
        try handle?.close()
        handle = nil
    }
}

public struct PTModelStreamEncoder<Model: Encodable & Sendable>: Sendable {
    public let encoder: PTModelEncoder

    public init(encoder: PTModelEncoder = .init()) {
        self.encoder = encoder
    }

    public func encode<S: AsyncSequence>(_ values: S) async throws -> Data where S.Element == Model {
        let sink = PTAsyncDataByteSink()
        try await write(values, to: sink)
        return await sink.value()
    }

    public func encode(_ values: [Model]) throws -> Data {
        var sink = PTDataByteSink()
        try write(values, to: &sink)
        return sink.data
    }

    public func write<S: AsyncSequence, Sink: PTAsyncJSONByteSink>(
        _ values: S,
        to sink: Sink
    ) async throws where S.Element == Model {
        do {
            try await sink.write(Data("[".utf8))
            var first = true
            for try await value in values {
                try Task.checkCancellation()
                if !first { try await sink.write(Data(",".utf8)) }
                first = false
                try await sink.write(try encoder.encode(value))
            }
            try await sink.write(Data("]".utf8))
            try await sink.finish()
        } catch {
            // English: Give sinks a chance to release partial output after cancellation or a write failure.
            // Español: Permite que el sink libere la salida parcial después de una cancelación o fallo de escritura.
            // 中文：取消或写入失败后仍让 sink 释放部分输出资源。
            try? await sink.finish()
            throw error
        }
    }

    public func write<Sink: PTJSONByteSink>(_ values: [Model], to sink: inout Sink) throws {
        try sink.write(Data("[".utf8))
        for (index, value) in values.enumerated() {
            if index > 0 { try sink.write(Data(",".utf8)) }
            try sink.write(try encoder.encode(value))
        }
        try sink.write(Data("]".utf8))
    }
}

private struct PTJSONArrayElementScanner: Sendable {
    private let data: Data
    private var index: Int = 0
    private var started = false
    private var finished = false

    init(data: Data) {
        self.data = data
    }

    mutating func nextElementData() throws -> Data? {
        if finished { return nil }
        if !started {
            started = true
            skipWhitespace()
            guard currentByte == 0x5B else { throw PTModelError.streamInvalidRoot }
            index += 1
        }
        skipWhitespace()
        if currentByte == 0x5D {
            finished = true
            index += 1
            skipWhitespace()
            guard index == data.count else {
                throw PTModelError.invalidJSON("Trailing characters after streamed array")
            }
            return nil
        }

        let start = index
        var depth = 0
        var inString = false
        var escaped = false
        while index < data.count {
            let byte = data[index]
            if inString {
                if escaped {
                    escaped = false
                } else if byte == 0x5C {
                    escaped = true
                } else if byte == 0x22 {
                    inString = false
                }
                index += 1
                continue
            }

            switch byte {
            case 0x22:
                inString = true
                index += 1
            case 0x7B, 0x5B:
                depth += 1
                index += 1
            case 0x7D, 0x5D:
                if depth > 0 {
                    depth -= 1
                    index += 1
                } else {
                    let slice = data[start..<index]
                    guard !slice.isEmpty else { throw PTModelError.invalidJSON("Empty streamed element") }
                    if byte == 0x5D {
                        finished = true
                        index += 1
                        skipWhitespace()
                        guard index == data.count else {
                            throw PTModelError.invalidJSON("Trailing characters after streamed array")
                        }
                    }
                    return Data(slice)
                }
            case 0x2C where depth == 0:
                let slice = data[start..<index]
                index += 1
                guard !slice.isEmpty else { throw PTModelError.invalidJSON("Empty streamed element") }
                return Data(slice)
            default:
                index += 1
            }
        }
        throw PTModelError.invalidJSON("Unterminated streamed array element")
    }

    private mutating func skipWhitespace() {
        while let byte = currentByte, byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
            index += 1
        }
    }

    private var currentByte: UInt8? {
        guard index < data.count else { return nil }
        return data[index]
    }
}
