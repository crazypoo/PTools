// English: Incremental HTTP/1.1 request parsing with bounded framing rules.
// Español: Análisis incremental de solicitudes HTTP/1.1 con límites de framing.
// 中文：带有严格 framing 限制的增量 HTTP/1.1 请求解析器。

import Foundation

public struct PTHTTPParserLimits: Sendable, Equatable {
    public var maximumRequestLineBytes: Int
    public var maximumHeaderBytes: Int
    public var maximumHeaderCount: Int
    public var maximumHeaderLineBytes: Int
    public var maximumChunkCount: Int
    public var maximumTrailerBytes: Int

    public init(maximumRequestLineBytes: Int = 8 * 1024, maximumHeaderBytes: Int = 32 * 1024,
                maximumHeaderCount: Int = 100, maximumHeaderLineBytes: Int = 8 * 1024,
                maximumChunkCount: Int = 100_000, maximumTrailerBytes: Int = 8 * 1024) {
        self.maximumRequestLineBytes = maximumRequestLineBytes
        self.maximumHeaderBytes = maximumHeaderBytes
        self.maximumHeaderCount = maximumHeaderCount
        self.maximumHeaderLineBytes = maximumHeaderLineBytes
        self.maximumChunkCount = maximumChunkCount
        self.maximumTrailerBytes = maximumTrailerBytes
    }
}

public struct PTHTTPParserError: Error, LocalizedError, Sendable, Equatable {
    public let status: PTHTTPStatus
    public let message: String

    public init(status: PTHTTPStatus = .badRequest, message: String) {
        self.status = status
        self.message = message
    }

    public var errorDescription: String? { message }
}

public struct PTHTTPParser: Sendable {
    private enum State: Sendable {
        case requestLine
        case headers
        case fixedBody
        case chunkSize
        case chunkData
        case chunkDataCRLF
        case chunkTrailers
    }

    private var buffer = Data()
    private var state: State = .requestLine
    private var method: PTHTTPMethod?
    private var target = ""
    private var httpVersion = ""
    private var headers: [(String, String)] = []
    private var headerBytes = 0
    private var contentLength: Int64?
    private var isChunked = false
    private var body = PTHTTPBodyAccumulator()
    private var remainingBodyBytes: Int64 = 0
    private var remainingChunkBytes: Int64 = 0
    private var chunkCount = 0
    private var trailerHeaders: [(String, String)] = []
    private let limits: PTHTTPParserLimits
    private let maximumBodyBytes: Int64
    private let bodyFileThreshold: Int64
    private let remoteEndpoint: String?
    private var failed = false

    public init(limits: PTHTTPParserLimits = PTHTTPParserLimits(), maximumBodyBytes: Int64 = 10 * 1024 * 1024,
                bodyFileThreshold: Int64 = 1 * 1024 * 1024, remoteEndpoint: String? = nil) {
        self.limits = limits
        self.maximumBodyBytes = max(1, maximumBodyBytes)
        self.bodyFileThreshold = max(1, min(bodyFileThreshold, maximumBodyBytes))
        self.remoteEndpoint = remoteEndpoint
    }

    public var isFailed: Bool { failed }

    public mutating func append(_ data: Data) throws -> [PTHTTPRequest] {
        guard !failed else { throw PTHTTPParserError(message: "Parser 已经失败 / Parser has already failed / El parser ya falló") }
        buffer.append(data)
        var requests: [PTHTTPRequest] = []

        do {
            while true {
                switch state {
                case .requestLine:
                    guard let line = try consumeLine(maximumBytes: limits.maximumRequestLineBytes) else { return requests }
                    try parseRequestLine(line)
                    state = .headers
                case .headers:
                    guard let line = try consumeLine(maximumBytes: limits.maximumHeaderLineBytes) else { return requests }
                    if line.isEmpty {
                        try finishHeaders()
                    } else {
                        try parseHeader(line)
                    }
                case .fixedBody:
                    guard remainingBodyBytes > 0 else {
                        requests.append(try finishRequest())
                        continue
                    }
                    guard !buffer.isEmpty else { return requests }
                    let count = min(Int(remainingBodyBytes), buffer.count)
                    try appendBody(buffer.prefix(count))
                    buffer.removeFirst(count)
                    remainingBodyBytes -= Int64(count)
                    if remainingBodyBytes == 0 { requests.append(try finishRequest()) }
                case .chunkSize:
                    guard let line = try consumeLine(maximumBytes: limits.maximumHeaderLineBytes) else { return requests }
                    let value = try parseChunkSize(line)
                    chunkCount += 1
                    guard chunkCount <= limits.maximumChunkCount else {
                        throw PTHTTPParserError(message: "Chunk 数量超过限制 / Chunk count exceeded / Se superó el número de chunks")
                    }
                    if value == 0 {
                        state = .chunkTrailers
                    } else {
                        remainingChunkBytes = value
                        state = .chunkData
                    }
                case .chunkData:
                    guard remainingChunkBytes > 0 else {
                        state = .chunkDataCRLF
                        continue
                    }
                    guard !buffer.isEmpty else { return requests }
                    let count = min(Int(remainingChunkBytes), buffer.count)
                    try appendBody(buffer.prefix(count))
                    buffer.removeFirst(count)
                    remainingChunkBytes -= Int64(count)
                    if remainingChunkBytes == 0 { state = .chunkDataCRLF }
                case .chunkDataCRLF:
                    guard buffer.count >= 2 else { return requests }
                    guard buffer[buffer.startIndex] == 13, buffer[buffer.index(after: buffer.startIndex)] == 10 else {
                        throw PTHTTPParserError(message: "Chunk CRLF 无效 / Invalid chunk CRLF / CRLF de chunk inválido")
                    }
                    buffer.removeFirst(2)
                    state = .chunkSize
                case .chunkTrailers:
                    guard let line = try consumeLine(maximumBytes: limits.maximumTrailerBytes) else { return requests }
                    if line.isEmpty {
                        requests.append(try finishRequest())
                    } else {
                        guard trailerHeaders.reduce(0, { $0 + $1.0.utf8.count + $1.1.utf8.count }) + line.count <= limits.maximumTrailerBytes else {
                            throw PTHTTPParserError(message: "Trailer 超过限制 / Trailer size exceeded / El tamaño del trailer excede el límite")
                        }
                        trailerHeaders.append(try parseHeaderValue(line))
                    }
                }
            }
        } catch let error as PTHTTPParserError {
            failed = true
            body.cleanup()
            throw error
        } catch {
            failed = true
            body.cleanup()
            throw PTHTTPParserError(message: "HTTP 请求解析失败 / HTTP request parsing failed / Falló el análisis HTTP")
        }
    }

    private mutating func consumeLine(maximumBytes: Int) throws -> [UInt8]? {
        guard let end = buffer.firstRange(of: Data([13, 10])) else {
            guard buffer.count <= maximumBytes else {
                throw PTHTTPParserError(status: .requestHeaderFieldsTooLarge, message: "HTTP 行超过限制 / HTTP line exceeded limit / La línea HTTP excede el límite")
            }
            return nil
        }
        let line = Array(buffer[..<end.lowerBound])
        buffer.removeFirst(end.upperBound - buffer.startIndex)
        guard line.count <= maximumBytes else {
            throw PTHTTPParserError(status: .requestHeaderFieldsTooLarge, message: "HTTP 行超过限制 / HTTP line exceeded limit / La línea HTTP excede el límite")
        }
        return line
    }

    private mutating func parseRequestLine(_ line: [UInt8]) throws {
        let parts = line.split(separator: 32, omittingEmptySubsequences: true)
        guard parts.count == 3, let methodString = String(bytes: parts[0], encoding: .ascii),
              let targetString = String(bytes: parts[1], encoding: .utf8),
              let version = String(bytes: parts[2], encoding: .ascii),
              version == "HTTP/1.1" || version == "HTTP/1.0" else {
            throw PTHTTPParserError(message: "请求行无效 / Invalid request line / Línea de solicitud inválida")
        }
        guard methodString.utf8.allSatisfy(Self.isTokenByte) else {
            throw PTHTTPParserError(message: "HTTP 方法无效 / Invalid HTTP method / Método HTTP inválido")
        }
        guard targetString.utf8.count <= limits.maximumRequestLineBytes else {
            throw PTHTTPParserError(status: .requestHeaderFieldsTooLarge, message: "请求目标过长 / Request target too long / Objetivo de solicitud demasiado largo")
        }
        method = PTHTTPMethod(rawValue: methodString)
        target = targetString
        httpVersion = version
    }

    private mutating func parseHeader(_ line: [UInt8]) throws {
        guard let first = line.first, first != 32, first != 9, let pair = try? parseHeaderValue(line) else {
            throw PTHTTPParserError(message: "Header 无效 / Invalid header / Cabecera inválida")
        }
        headerBytes += line.count + 2
        guard headerBytes <= limits.maximumHeaderBytes else {
            throw PTHTTPParserError(status: .requestHeaderFieldsTooLarge, message: "Header 总长度超过限制 / Header bytes exceeded limit / Los bytes de cabecera exceden el límite")
        }
        guard headers.count < limits.maximumHeaderCount else {
            throw PTHTTPParserError(status: .requestHeaderFieldsTooLarge, message: "Header 数量超过限制 / Header count exceeded / Se superó el número de cabeceras")
        }
        let name = pair.0.lowercased()
        if name == "content-length" {
            guard contentLength == nil, !isChunked, let value = Int64(pair.1), value >= 0 else {
                throw PTHTTPParserError(message: "Content-Length 重复或无效 / Duplicate or invalid Content-Length / Content-Length duplicado o inválido")
            }
            guard value <= maximumBodyBytes else {
                throw PTHTTPParserError(status: .requestEntityTooLarge, message: "请求体超过限制 / Request body exceeded limit / El cuerpo excede el límite")
            }
            contentLength = value
        } else if name == "transfer-encoding" {
            let codings = pair.1.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            guard codings == ["chunked"], contentLength == nil else {
                throw PTHTTPParserError(message: "Transfer-Encoding framing 无效 / Invalid Transfer-Encoding framing / Framing Transfer-Encoding inválido")
            }
            isChunked = true
        }
        headers.append(pair)
    }

    private func parseHeaderValue(_ line: [UInt8]) throws -> (String, String) {
        guard let colon = line.firstIndex(of: 58), colon > line.startIndex else {
            throw PTHTTPParserError(message: "Header 缺少冒号 / Header is missing colon / Falta dos puntos en la cabecera")
        }
        let nameBytes = line[..<colon]
        guard nameBytes.allSatisfy(Self.isTokenByte) else {
            throw PTHTTPParserError(message: "Header 名称无效 / Invalid header name / Nombre de cabecera inválido")
        }
        let valueStart = line.index(after: colon)
        let rawValue = String(bytes: line[valueStart...], encoding: .utf8) ?? ""
        guard !rawValue.contains("\r"), !rawValue.contains("\n") else {
            throw PTHTTPParserError(message: "Header value 含有换行 / Header value contains a newline / El valor contiene un salto de línea")
        }
        guard let name = String(bytes: nameBytes, encoding: .ascii) else {
            throw PTHTTPParserError(message: "Header 名称编码无效 / Invalid header name encoding / Codificación de nombre de cabecera inválida")
        }
        return (name, rawValue.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private mutating func finishHeaders() throws {
        if isChunked {
            state = .chunkSize
            return
        }
        remainingBodyBytes = contentLength ?? 0
        state = remainingBodyBytes == 0 ? .fixedBody : .fixedBody
    }

    private mutating func appendBody<S: Sequence>(_ bytes: S) throws where S.Element == UInt8 {
        let data = Data(bytes)
        guard body.byteCount + Int64(data.count) <= maximumBodyBytes else {
            throw PTHTTPParserError(status: .requestEntityTooLarge, message: "请求体超过限制 / Request body exceeded limit / El cuerpo excede el límite")
        }
        try body.append(data, threshold: bodyFileThreshold)
    }

    private mutating func finishRequest() throws -> PTHTTPRequest {
        guard let method else { throw PTHTTPParserError(message: "缺少 HTTP 方法 / Missing HTTP method / Falta el método HTTP") }
        let targetParts = target.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let rawPath = String(targetParts.first ?? "/")
        guard rawPath.hasPrefix("/") else {
            throw PTHTTPParserError(message: "仅支持 origin-form / Only origin-form is supported / Solo se admite origin-form")
        }
        let path = rawPath.removingPercentEncoding ?? rawPath
        guard !path.contains("\0") else { throw PTHTTPParserError(message: "路径无效 / Invalid path / Ruta inválida") }
        let query = targetParts.count == 2 ? PTHTTPQuery.parse(String(targetParts[1])) : PTHTTPQuery()
        let result = PTHTTPRequest(id: UUID(), method: method, path: path, query: query,
                                   headers: PTHTTPHeaders(values: headers), body: body.finish(),
                                   httpVersion: httpVersion, remoteEndpoint: remoteEndpoint,
                                   trailers: PTHTTPHeaders(values: trailerHeaders))
        resetForNextRequest()
        return result
    }

    private mutating func resetForNextRequest() {
        state = .requestLine
        method = nil
        target = ""
        httpVersion = ""
        headers.removeAll(keepingCapacity: true)
        headerBytes = 0
        contentLength = nil
        isChunked = false
        body = PTHTTPBodyAccumulator()
        remainingBodyBytes = 0
        remainingChunkBytes = 0
        chunkCount = 0
        trailerHeaders.removeAll(keepingCapacity: true)
    }

    private func parseChunkSize(_ line: [UInt8]) throws -> Int64 {
        let value = String(bytes: line, encoding: .ascii)?.split(separator: ";", maxSplits: 1).first?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !value.isEmpty, value.allSatisfy({ $0.isHexDigit }), let size = Int64(value, radix: 16), size <= maximumBodyBytes else {
            throw PTHTTPParserError(status: .requestEntityTooLarge, message: "Chunk size 无效 / Invalid chunk size / Tamaño de chunk inválido")
        }
        return size
    }

    private static func isTokenByte(_ byte: UInt8) -> Bool {
        switch byte {
        case 33, 35...39, 42, 43, 45...46, 48...57, 65...90, 94...122: return true
        default: return false
        }
    }

    public mutating func cleanup() {
        body.cleanup()
        buffer.removeAll(keepingCapacity: false)
        failed = true
    }
}

private struct PTHTTPBodyAccumulator: Sendable {
    private(set) var data = Data()
    private var fileURL: URL?
    private var fileHandle: FileHandle?
    private(set) var byteCount: Int64 = 0

    mutating func append(_ value: Data, threshold: Int64) throws {
        if fileHandle == nil, byteCount + Int64(value.count) <= threshold {
            data.append(value)
        } else {
            if fileHandle == nil {
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("pt-http-\(UUID().uuidString).upload")
                FileManager.default.createFile(atPath: url.path, contents: nil)
                fileURL = url
                fileHandle = try FileHandle(forWritingTo: url)
                try fileHandle?.write(contentsOf: data)
                data.removeAll(keepingCapacity: false)
            }
            try fileHandle?.write(contentsOf: value)
        }
        byteCount += Int64(value.count)
    }

    mutating func finish() -> PTHTTPRequestBody {
        try? fileHandle?.close()
        fileHandle = nil
        if let fileURL { return .file(fileURL) }
        return data.isEmpty ? .empty : .data(data)
    }

    mutating func cleanup() {
        try? fileHandle?.close()
        fileHandle = nil
        if let fileURL { try? FileManager.default.removeItem(at: fileURL) }
        fileURL = nil
        data.removeAll(keepingCapacity: false)
    }
}
