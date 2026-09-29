//
//  PTJSONByteSink.swift
//
// English: Small output sinks keep JSON serialization usable for Data and files without coupling the model core to FileHandle state.
// Español: Los sinks pequeños permiten serializar JSON a Data o archivos sin acoplar el núcleo a un FileHandle persistente.
// 中文：轻量输出 Sink 让 JSON 可写入 Data 或文件，同时避免模型核心持有 FileHandle 状态。
//

import Foundation

public protocol PTJSONByteSink {
    mutating func write(_ data: Data) throws
}

public struct PTDataByteSink: PTJSONByteSink, Sendable {
    public private(set) var data: Data

    public init(data: Data = .init()) {
        self.data = data
    }

    public mutating func write(_ data: Data) throws {
        self.data.append(data)
    }
}

public struct PTFileByteSink: PTJSONByteSink, Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public mutating func write(_ data: Data) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }
}
