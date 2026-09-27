// English: Typed HTTP contracts for the native iOS 17+ server.
// Español: Contratos HTTP tipados para el servidor nativo de iOS 17+.
// 中文：面向 iOS 17+ 原生服务器的类型化 HTTP 契约。

import Foundation
import Security

public struct PTHTTPMethod: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public static let get: Self = "GET"
    public static let head: Self = "HEAD"
    public static let post: Self = "POST"
    public static let put: Self = "PUT"
    public static let patch: Self = "PATCH"
    public static let delete: Self = "DELETE"
    public static let options: Self = "OPTIONS"
}

public struct PTHTTPStatus: RawRepresentable, Hashable, Sendable {
    public let rawValue: Int
    public let reasonPhrase: String

    public init(rawValue: Int, reasonPhrase: String? = nil) {
        self.rawValue = rawValue
        self.reasonPhrase = reasonPhrase ?? Self.defaultReason(for: rawValue)
    }

    public init?(rawValue: Int) {
        self.init(rawValue: rawValue, reasonPhrase: nil)
    }

    public static let ok = Self(rawValue: 200, reasonPhrase: nil)
    public static let created = Self(rawValue: 201, reasonPhrase: nil)
    public static let noContent = Self(rawValue: 204, reasonPhrase: nil)
    public static let partialContent = Self(rawValue: 206, reasonPhrase: nil)
    public static let notModified = Self(rawValue: 304, reasonPhrase: nil)
    public static let badRequest = Self(rawValue: 400, reasonPhrase: nil)
    public static let unauthorized = Self(rawValue: 401, reasonPhrase: nil)
    public static let forbidden = Self(rawValue: 403, reasonPhrase: nil)
    public static let notFound = Self(rawValue: 404, reasonPhrase: nil)
    public static let methodNotAllowed = Self(rawValue: 405, reasonPhrase: nil)
    public static let requestTimeout = Self(rawValue: 408, reasonPhrase: nil)
    public static let requestEntityTooLarge = Self(rawValue: 413, reasonPhrase: nil)
    public static let requestHeaderFieldsTooLarge = Self(rawValue: 431, reasonPhrase: nil)
    public static let tooManyRequests = Self(rawValue: 429, reasonPhrase: nil)
    public static let rangeNotSatisfiable = Self(rawValue: 416, reasonPhrase: nil)
    public static let internalServerError = Self(rawValue: 500, reasonPhrase: nil)
    public static let notImplemented = Self(rawValue: 501, reasonPhrase: nil)
    public static let serviceUnavailable = Self(rawValue: 503, reasonPhrase: nil)

    private static func defaultReason(for code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 201: return "Created"
        case 204: return "No Content"
        case 206: return "Partial Content"
        case 304: return "Not Modified"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 408: return "Request Timeout"
        case 413: return "Content Too Large"
        case 416: return "Range Not Satisfiable"
        case 429: return "Too Many Requests"
        case 431: return "Request Header Fields Too Large"
        case 500: return "Internal Server Error"
        case 501: return "Not Implemented"
        case 503: return "Service Unavailable"
        default: return "HTTP Error"
        }
    }
}

public struct PTHTTPHeaders: Sendable, Equatable {
    private var values: [(name: String, value: String)]

    public init(_ values: [String: String] = [:]) {
        self.values = values.map { ($0.key, $0.value) }.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    public init(values: [(String, String)]) {
        self.values = values
    }

    public var all: [(String, String)] { values }

    public func firstValue(for name: String) -> String? {
        values.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    public func values(for name: String) -> [String] {
        values.filter { $0.name.caseInsensitiveCompare(name) == .orderedSame }.map(\.value)
    }

    public func contains(_ name: String) -> Bool { firstValue(for: name) != nil }

    public subscript(name: String) -> String? { firstValue(for: name) }

    public func setting(_ value: String, for name: String) -> Self {
        var result = values.filter { $0.name.caseInsensitiveCompare(name) != .orderedSame }
        result.append((name, value))
        return Self(values: result)
    }

    public func appending(_ value: String, for name: String) -> Self {
        var result = values
        result.append((name, value))
        return Self(values: result)
    }

    public func removing(_ name: String) -> Self {
        Self(values: values.filter { $0.name.caseInsensitiveCompare(name) != .orderedSame })
    }

    func serialized() -> String {
        values.map { "\($0.name): \($0.value)\r\n" }.joined()
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.values.count == rhs.values.count else { return false }
        return zip(lhs.values, rhs.values).allSatisfy {
            $0.0.name.caseInsensitiveCompare($0.1.name) == .orderedSame && $0.0.value == $0.1.value
        }
    }
}

public struct PTHTTPQuery: Sendable, Equatable {
    public let values: [String: [String]]

    public init(_ values: [String: [String]] = [:]) {
        self.values = values
    }

    public subscript(_ key: String) -> String? { values[key]?.first }

    public func all(_ key: String) -> [String] { values[key] ?? [] }

    public static func parse(_ query: String) -> Self {
        var result: [String: [String]] = [:]
        for item in query.split(separator: "&", omittingEmptySubsequences: false) {
            let pair = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let key = String(pair.first ?? "").replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? ""
            let value = pair.count == 2
                ? String(pair[1]).replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? ""
                : ""
            guard !key.isEmpty else { continue }
            result[key, default: []].append(value)
        }
        return Self(result)
    }
}

public enum PTHTTPRequestBody: Sendable, Equatable {
    case empty
    case data(Data)
    case file(URL)

    public var byteCount: Int64 {
        switch self {
        case .empty: return 0
        case .data(let data): return Int64(data.count)
        case .file(let url): return (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
        }
    }
}

public struct PTHTTPRequest: Sendable {
    public let id: UUID
    public let method: PTHTTPMethod
    public let scheme: String
    public let authority: String?
    public let path: String
    public let query: PTHTTPQuery
    public let headers: PTHTTPHeaders
    public let body: PTHTTPRequestBody
    public let httpVersion: String
    public let remoteEndpoint: String?
    public let parameters: [String: String]
    public let trailers: PTHTTPHeaders

    public init(id: UUID = UUID(), method: PTHTTPMethod, scheme: String = "http", authority: String? = nil,
                path: String, query: PTHTTPQuery = PTHTTPQuery(), headers: PTHTTPHeaders = PTHTTPHeaders(),
                body: PTHTTPRequestBody = .empty, httpVersion: String = "HTTP/1.1", remoteEndpoint: String? = nil,
                parameters: [String: String] = [:], trailers: PTHTTPHeaders = PTHTTPHeaders()) {
        self.id = id
        self.method = method
        self.scheme = scheme
        self.authority = authority
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
        self.httpVersion = httpVersion
        self.remoteEndpoint = remoteEndpoint
        self.parameters = parameters
        self.trailers = trailers
    }
}

public struct PTHTTPFileBody: Sendable, Equatable {
    public let url: URL
    public let offset: UInt64
    public let length: UInt64
    public let contentType: String
    public let etag: String?
    public let modificationDate: Date?

    public init(url: URL, offset: UInt64 = 0, length: UInt64, contentType: String = "application/octet-stream",
                etag: String? = nil, modificationDate: Date? = nil) {
        self.url = url
        self.offset = offset
        self.length = length
        self.contentType = contentType
        self.etag = etag
        self.modificationDate = modificationDate
    }
}

public typealias PTHTTPBodyStream = AsyncThrowingStream<Data, Error>

public enum PTHTTPResponseBody: Sendable {
    case empty
    case data(Data)
    case text(String, encoding: String.Encoding = .utf8)
    case file(PTHTTPFileBody)
    case stream(PTHTTPBodyStream)
    case sse(PTHTTPSSEStream)
}

public struct PTHTTPResponse: Sendable {
    public var status: PTHTTPStatus
    public var headers: PTHTTPHeaders
    public var body: PTHTTPResponseBody

    public init(status: PTHTTPStatus = .ok, headers: PTHTTPHeaders = PTHTTPHeaders(), body: PTHTTPResponseBody = .empty) {
        self.status = status
        self.headers = headers
        self.body = body
    }

    public static func text(_ value: String, status: PTHTTPStatus = .ok, headers: PTHTTPHeaders = PTHTTPHeaders()) -> Self {
        Self(status: status, headers: headers.setting("text/plain; charset=utf-8", for: "Content-Type"), body: .text(value))
    }

    public static func json<T: Encodable & Sendable>(_ value: T, status: PTHTTPStatus = .ok, encoder: JSONEncoder = JSONEncoder()) throws -> Self {
        let data = try encoder.encode(value)
        return Self(status: status, headers: PTHTTPHeaders(["Content-Type": "application/json; charset=utf-8"]), body: .data(data))
    }

    public static func error(_ status: PTHTTPStatus, message: String? = nil) -> Self {
        Self.text(message ?? status.reasonPhrase, status: status)
    }

    public static func sse(_ stream: PTHTTPSSEStream, headers: PTHTTPHeaders = PTHTTPHeaders()) -> Self {
        let responseHeaders = headers.setting("text/event-stream; charset=utf-8", for: "Content-Type")
            .setting("no-cache", for: "Cache-Control")
            .setting("keep-alive", for: "Connection")
        return Self(headers: responseHeaders, body: .sse(stream))
    }
}

public typealias PTHTTPHandler = @Sendable (PTHTTPRequest) async throws -> PTHTTPResponse
public typealias PTHTTPNext = @Sendable (PTHTTPRequest) async throws -> PTHTTPResponse

public protocol PTHTTPMiddleware: Sendable {
    func handle(request: PTHTTPRequest, next: @escaping PTHTTPNext) async throws -> PTHTTPResponse
}

public struct PTHTTPClosureMiddleware: PTHTTPMiddleware {
    private let closure: @Sendable (PTHTTPRequest, @escaping PTHTTPNext) async throws -> PTHTTPResponse

    public init(_ closure: @escaping @Sendable (PTHTTPRequest, @escaping PTHTTPNext) async throws -> PTHTTPResponse) {
        self.closure = closure
    }

    public func handle(request: PTHTTPRequest, next: @escaping PTHTTPNext) async throws -> PTHTTPResponse {
        try await closure(request, next)
    }
}

public enum PTHTTPBindScope: Sendable, Equatable {
    case loopback
    case localNetwork
}

// English: This wrapper contains only a system TLS identity used by Network.framework.
// Español: Este envoltorio contiene únicamente una identidad TLS del sistema usada por Network.framework.
// 中文：这个包装器只承载 Network.framework 使用的系统 TLS 身份对象。
public struct PTTLSIdentity: @unchecked Sendable {
    let value: SecIdentity

    public init(_ value: SecIdentity) { self.value = value }
}

public enum PTHTTPTLSConfiguration: @unchecked Sendable {
    case disabled
    case identity(PTTLSIdentity)
}

public struct PTHTTPServerConfiguration: Sendable {
    public var bindScope: PTHTTPBindScope
    public var port: UInt16
    public var serviceName: String?
    public var serviceType: String?
    public var idleTimeout: Duration
    public var headerTimeout: Duration
    public var handlerTimeout: Duration?
    public var maxRequestsPerConnection: Int
    public var maxConnections: Int
    public var maxBodyBytes: Int64
    public var bodyFileThreshold: Int64
    public var parserLimits: PTHTTPParserLimits
    public var tls: PTHTTPTLSConfiguration
    public var shutdownGracePeriod: Duration

    public init(bindScope: PTHTTPBindScope = .loopback, port: UInt16 = 0, serviceName: String? = nil,
                serviceType: String? = nil, idleTimeout: Duration = .seconds(30), headerTimeout: Duration = .seconds(10),
                handlerTimeout: Duration? = nil, maxRequestsPerConnection: Int = 100, maxConnections: Int = 32,
                maxBodyBytes: Int64 = 10 * 1024 * 1024, bodyFileThreshold: Int64 = 1 * 1024 * 1024,
                parserLimits: PTHTTPParserLimits = PTHTTPParserLimits(), tls: PTHTTPTLSConfiguration = .disabled,
                shutdownGracePeriod: Duration = .seconds(3)) {
        self.bindScope = bindScope
        self.port = port
        self.serviceName = serviceName
        self.serviceType = serviceType
        self.idleTimeout = idleTimeout
        self.headerTimeout = headerTimeout
        self.handlerTimeout = handlerTimeout
        self.maxRequestsPerConnection = max(1, maxRequestsPerConnection)
        self.maxConnections = max(1, maxConnections)
        self.maxBodyBytes = max(1, maxBodyBytes)
        self.bodyFileThreshold = max(1, min(bodyFileThreshold, maxBodyBytes))
        self.parserLimits = parserLimits
        self.tls = tls
        self.shutdownGracePeriod = shutdownGracePeriod
    }
}

public struct PTHTTPServerEndpoint: Sendable, Equatable {
    public let port: UInt16
    public let urls: [URL]
    public let bonjourName: String?

    public init(port: UInt16, urls: [URL], bonjourName: String? = nil) {
        self.port = port
        self.urls = urls
        self.bonjourName = bonjourName
    }
}

public enum PTHTTPServerState: Sendable, Equatable {
    case stopped
    case starting
    case ready(PTHTTPServerEndpoint)
    case stopping
    case failed(String)
}

public enum PTHTTPServerError: Error, LocalizedError, Sendable, Equatable {
    case alreadyRunning
    case notRunning
    case listenerFailed(String)
    case connectionLimitReached
    case invalidConfiguration(String)
    case parser(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .alreadyRunning: return "HTTP Server 已经运行 / HTTP server is already running / El servidor HTTP ya está activo"
        case .notRunning: return "HTTP Server 未运行 / HTTP server is not running / El servidor HTTP no está activo"
        case .listenerFailed(let message), .parser(let message), .invalidConfiguration(let message): return message
        case .connectionLimitReached: return "连接数已达上限 / Connection limit reached / Se alcanzó el límite de conexiones"
        case .cancelled: return "HTTP Server 操作已取消 / HTTP server operation cancelled / Operación del servidor HTTP cancelada"
        }
    }
}

public struct PTHTTPServerMetrics: Sendable, Equatable {
    public let activeConnections: Int
    public let totalConnections: UInt64
    public let totalRequests: UInt64
    public let bytesReceived: UInt64
    public let bytesSent: UInt64
    public let parseErrors: UInt64
    public let activeSSEClients: Int

    public init(activeConnections: Int = 0, totalConnections: UInt64 = 0, totalRequests: UInt64 = 0,
                bytesReceived: UInt64 = 0, bytesSent: UInt64 = 0, parseErrors: UInt64 = 0, activeSSEClients: Int = 0) {
        self.activeConnections = activeConnections
        self.totalConnections = totalConnections
        self.totalRequests = totalRequests
        self.bytesReceived = bytesReceived
        self.bytesSent = bytesSent
        self.parseErrors = parseErrors
        self.activeSSEClients = activeSSEClients
    }
}

public struct PTHTTPSSEEvent: Sendable, Equatable {
    public let id: String?
    public let event: String?
    public let data: String
    public let retry: Duration?

    public init(data: String, id: String? = nil, event: String? = nil, retry: Duration? = nil) {
        self.id = id
        self.event = event
        self.data = data
        self.retry = retry
    }

    fileprivate var encoded: Data {
        var lines: [String] = []
        if let id { lines.append("id: \(id)") }
        if let event { lines.append("event: \(event)") }
        if let retry { lines.append("retry: \(max(0, retry.ptMilliseconds))") }
        let dataLines = data.split(separator: "\n", omittingEmptySubsequences: false).map { "data: \($0)" }
        lines.append(contentsOf: dataLines.isEmpty ? ["data:"] : dataLines)
        return Data((lines.joined(separator: "\n") + "\n\n").utf8)
    }
}

public struct PTHTTPSSEStream: Sendable {
    public let stream: PTHTTPBodyStream
    private let continuation: PTHTTPBodyStream.Continuation

    public init(bufferingPolicy: AsyncThrowingStream<Data, Error>.Continuation.BufferingPolicy = .bufferingNewest(64)) {
        let pair = PTHTTPBodyStream.makeStream(bufferingPolicy: bufferingPolicy)
        stream = pair.stream
        continuation = pair.continuation
    }

    public func send(_ event: PTHTTPSSEEvent) { continuation.yield(event.encoded) }
    public func finish() { continuation.finish() }
}

extension Duration {
    fileprivate var ptSeconds: Double {
        let components = self.components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }

    fileprivate var ptMilliseconds: Int64 { Int64(max(0, ptSeconds) * 1000) }
}
