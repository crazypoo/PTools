//
//  PTModelStreaming.swift
//
// English: Bounded top-level array streaming for PTModel decode and encode.
// Español: Streaming acotado de arrays de nivel superior para decodificación y codificación PTModel.
// 中文：PTModel 顶层数组的有界流式解码和编码能力。
//

import Foundation

// English: Decode an arbitrary AsyncSequence of Data chunks without collecting the complete JSON document.
// Español: Decodifica una AsyncSequence arbitraria de bloques Data sin acumular todo el documento JSON.
// 中文：直接解码任意 AsyncSequence<Data> 分块，不把完整 JSON 文档保留在内存中。
public struct PTModelChunkStreamDecoder<Source: AsyncSequence & Sendable, Item: Decodable & Sendable>: AsyncSequence, Sendable
where Source.Element == Data {
    public typealias Element = Item

    public struct AsyncIterator: AsyncIteratorProtocol {
        private var source: Source.AsyncIterator
        private var scanner: PTStreamingJSONArrayScanner
        private let decoder: PTModelDecoder
        private var elementIndex = 0

        fileprivate init(source: Source, decoder: PTModelDecoder) {
            self.source = source.makeAsyncIterator()
            self.decoder = decoder
            self.scanner = PTStreamingJSONArrayScanner(limits: decoder.limits)
        }

        public mutating func next() async throws -> Item? {
            while true {
                try Task.checkCancellation()
                if let elementData = try scanner.nextElementData() {
                    let currentIndex = elementIndex
                    elementIndex += 1
                    do {
                        return try decoder.decode(Item.self, from: elementData)
                    } catch {
                        throw PTModelError.streamElementFailed(currentIndex, error.localizedDescription)
                    }
                }
                if scanner.isFinished { return nil }
                guard let chunk = try await source.next() else {
                    try scanner.finish()
                    return nil
                }
                try scanner.append(chunk)
            }
        }
    }

    private let source: Source
    private let decoder: PTModelDecoder

    public init(source: Source,
                decoder: PTModelDecoder = .init()) {
        self.source = source
        self.decoder = decoder
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(source: source, decoder: decoder)
    }
}

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
    func flush() async throws
    func finish() async throws
}

// English: Flush is an optional durability/backpressure boundary; the default keeps existing sinks source-compatible.
// Español: Flush es un límite opcional de durabilidad/backpressure; el valor predeterminado conserva la compatibilidad.
// 中文：Flush 是可选的持久化/背压边界，默认实现保持现有 Sink 源码兼容。
public extension PTAsyncJSONByteSink {
    func flush() async throws {}
}

public actor PTAsyncDataByteSink: PTAsyncJSONByteSink {
    private var data = Data()
    private let maxBytes: Int?

    public init(maxBytes: Int? = nil) {
        self.maxBytes = maxBytes
    }

    public func write(_ data: Data) async throws {
        if let maxBytes,
           self.data.count > maxBytes - data.count {
            throw PTModelError.inputTooLarge
        }
        self.data.append(data)
    }

    public func flush() async throws {}

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
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: url.path, contents: nil)
            handle = try FileHandle(forWritingTo: url)
        }
        try handle?.seekToEnd()
        try handle?.write(contentsOf: data)
    }

    public func flush() async throws {
        try handle?.synchronize()
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

    // English: Flush cadence lets file and network sinks choose their own durability boundary.
    // Español: La cadencia de flush permite que cada sink de archivo o red elija su límite de durabilidad.
    // 中文：Flush 频率让文件和网络 Sink 自主选择持久化边界。
    public enum FlushPolicy: Sendable, Equatable {
        case never
        case everyElement
        case every(Int)

        fileprivate func shouldFlush(after count: Int) -> Bool {
            switch self {
            case .never: return false
            case .everyElement: return true
            case .every(let interval): return interval > 0 && count % interval == 0
            }
        }
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
        to sink: Sink,
        flushPolicy: FlushPolicy = .never
    ) async throws where S.Element == Model {
        do {
            try await sink.write(Data("[".utf8))
            var first = true
            var count = 0
            for try await value in values {
                try Task.checkCancellation()
                if !first { try await sink.write(Data(",".utf8)) }
                first = false
                try await sink.write(try encoder.encode(value))
                count += 1
                if flushPolicy.shouldFlush(after: count) {
                    try await sink.flush()
                }
            }
            try await sink.write(Data("]".utf8))
            try await sink.flush()
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

// English: The scanner retains only the unfinished element and a bounded working buffer.
// Español: El scanner conserva solo el elemento incompleto y un buffer de trabajo acotado.
// 中文：扫描器只保留未完成元素和有界工作缓冲区。
private struct PTStreamingJSONArrayScanner: Sendable {
    private let limits: PTModelLimits
    private var buffer: [UInt8] = []
    private var totalBytes = 0
    private var index = 0
    private var elementStart = 0
    private var depth = 0
    private var rootStarted = false
    private var rootClosed = false
    private var hasElements = false
    private var elementActive = false
    private var inString = false
    private var escaped = false
    private var elementCount = 0

    var isFinished: Bool { rootClosed && !elementActive }

    init(limits: PTModelLimits = .init()) {
        self.limits = limits
    }

    mutating func append(_ data: Data) throws {
        totalBytes += data.count
        guard totalBytes <= limits.maxInputBytes else {
            throw PTModelError.inputTooLarge
        }
        buffer.append(contentsOf: data)
    }

    mutating func nextElementData() throws -> Data? {
        if rootClosed { return nil }
        if !rootStarted {
            skipWhitespace()
            guard index < buffer.count else { return nil }
            guard buffer[index] == 0x5B else { throw PTModelError.streamInvalidRoot }
            rootStarted = true
            index += 1
        }

        if !elementActive {
            skipWhitespace()
            guard index < buffer.count else { return nil }
            if buffer[index] == 0x2C {
                guard hasElements else {
                    throw PTModelError.invalidJSON("Unexpected comma in streamed array")
                }
                index += 1
                skipWhitespace()
                guard index < buffer.count else { return nil }
                guard buffer[index] != 0x5D else {
                    throw PTModelError.invalidJSON("Trailing comma in streamed array")
                }
            }
            if buffer[index] == 0x5D {
                rootClosed = true
                index += 1
                compactIfNeeded()
                return nil
            }
            elementStart = index
            elementActive = true
            depth = 0
            inString = false
            escaped = false
        }

        while index < buffer.count {
            let byte = buffer[index]
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
                guard depth < limits.maxDepth else { throw PTModelError.depthLimitExceeded }
                depth += 1
                index += 1
            case 0x7D, 0x5D:
                if depth > 0 {
                    depth -= 1
                    index += 1
                    if depth == 0 {
                        return try finishElement(endingAt: index - 1)
                    }
                } else {
                    return try finishScalar(at: index)
                }
            case 0x2C where depth == 0:
                return try finishScalar(at: index)
            default:
                index += 1
            }
        }
        return nil
    }

    mutating func finish() throws {
        if !rootStarted || elementActive || !rootClosed {
            throw PTModelError.invalidJSON("Unterminated streamed array")
        }
        skipWhitespace()
        guard index == buffer.count else {
            throw PTModelError.invalidJSON("Trailing characters after streamed array")
        }
    }

    private mutating func finishElement(endingAt end: Int) throws -> Data {
        guard elementCount < limits.maxCollectionCount else {
            throw PTModelError.collectionLimitExceeded
        }
        elementActive = false
        let value = Data(buffer[elementStart...end])
        hasElements = true
        elementCount += 1
        compactIfNeeded()
        guard !value.isEmpty else { throw PTModelError.invalidJSON("Empty streamed element") }
        return value
    }

    private mutating func finishScalar(at delimiter: Int) throws -> Data {
        guard elementCount < limits.maxCollectionCount else {
            throw PTModelError.collectionLimitExceeded
        }
        let value = Data(buffer[elementStart..<delimiter])
        elementActive = false
        hasElements = true
        elementCount += 1
        index = delimiter
        compactIfNeeded()
        guard !value.allSatisfy({ $0 == 0x20 || $0 == 0x09 || $0 == 0x0A || $0 == 0x0D }) else {
            throw PTModelError.invalidJSON("Empty streamed element")
        }
        return value
    }

    private mutating func skipWhitespace() {
        while index < buffer.count {
            switch buffer[index] {
            case 0x20, 0x09, 0x0A, 0x0D: index += 1
            default: return
            }
        }
    }

    private mutating func compactIfNeeded() {
        guard index > 64 * 1024, index > buffer.count / 2 else { return }
        buffer.removeFirst(index)
        elementStart = max(0, elementStart - index)
        index = 0
    }
}
