//
//  PTModelChunkSources.swift
//
// English: Foundation-only file and URLSession chunk sources for PTModel streaming.
// Español: Fuentes de chunks de archivo y URLSession basadas solo en Foundation para el streaming de PTModel.
// 中文：为 PTModel 流式解码提供仅依赖 Foundation 的文件和 URLSession 分块数据源。
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// English: Reads a file in bounded chunks and closes the handle on every exit path.
// Español: Lee un archivo en chunks acotados y cierra el handle en todas las salidas.
// 中文：按有界大小读取文件，并保证所有退出路径关闭文件句柄。
public struct PTFileDataChunkSequence: AsyncSequence, Sendable {
    public typealias Element = Data

    public struct AsyncIterator: AsyncIteratorProtocol {
        private var iterator: AsyncThrowingStream<Data, Error>.Iterator

        fileprivate init(iterator: AsyncThrowingStream<Data, Error>.Iterator) {
            self.iterator = iterator
        }

        public mutating func next() async throws -> Data? {
            try await iterator.next()
        }
    }

    public let url: URL
    public let chunkSize: Int

    public init(url: URL, chunkSize: Int = 64 * 1024) {
        self.url = url
        self.chunkSize = Swift.max(1, chunkSize)
    }

    public func makeAsyncIterator() -> AsyncIterator {
        let url = self.url
        let chunkSize = self.chunkSize
        let stream = AsyncThrowingStream<Data, Error> { continuation in
            let task = Task {
                do {
                    let handle = try FileHandle(forReadingFrom: url)
                    defer { try? handle.close() }
                    while !Task.isCancelled {
                        guard let data = try handle.read(upToCount: chunkSize), !data.isEmpty else {
                            continuation.finish()
                            return
                        }
                        continuation.yield(data)
                    }
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
        return AsyncIterator(iterator: stream.makeAsyncIterator())
    }
}

// English: Stream URLSession bytes without accumulating the complete response in memory.
// Español: Transmite bytes de URLSession sin acumular la respuesta completa en memoria.
// 中文：流式读取 URLSession 字节，避免把完整响应一次性驻留内存。
public struct PTURLSessionDataChunkSequence: AsyncSequence, Sendable {
    public typealias Element = Data

    public struct AsyncIterator: AsyncIteratorProtocol {
        private var iterator: AsyncThrowingStream<Data, Error>.Iterator

        fileprivate init(iterator: AsyncThrowingStream<Data, Error>.Iterator) {
            self.iterator = iterator
        }

        public mutating func next() async throws -> Data? {
            try await iterator.next()
        }
    }

    public let url: URL
    public let method: String
    public let headers: [String: String]
    public let body: Data?
    public let chunkSize: Int
    public let timeout: TimeInterval

    public init(url: URL,
                method: String = "GET",
                headers: [String: String] = [:],
                body: Data? = nil,
                chunkSize: Int = 64 * 1024,
                timeout: TimeInterval = 60) {
        self.url = url
        self.method = method.uppercased()
        self.headers = headers
        self.body = body
        self.chunkSize = Swift.max(1, chunkSize)
        self.timeout = Swift.max(0, timeout)
    }

    public func makeAsyncIterator() -> AsyncIterator {
        let url = self.url
        let method = self.method
        let headers = self.headers
        let body = self.body
        let chunkSize = self.chunkSize
        let timeout = self.timeout
        let stream = AsyncThrowingStream<Data, Error> { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = method
                    request.httpBody = body
                    request.timeoutInterval = timeout
                    for (key, value) in headers {
                        request.setValue(value, forHTTPHeaderField: key)
                    }
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    if let response = response as? HTTPURLResponse,
                       !(200..<300).contains(response.statusCode) {
                        throw PTModelError.underlying("HTTP status \(response.statusCode)")
                    }

                    var buffer: [UInt8] = []
                    buffer.reserveCapacity(chunkSize)
                    for try await byte in bytes {
                        try Task.checkCancellation()
                        buffer.append(byte)
                        if buffer.count >= chunkSize {
                            continuation.yield(Data(buffer))
                            buffer.removeAll(keepingCapacity: true)
                        }
                    }
                    if !buffer.isEmpty { continuation.yield(Data(buffer)) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
        return AsyncIterator(iterator: stream.makeAsyncIterator())
    }
}
