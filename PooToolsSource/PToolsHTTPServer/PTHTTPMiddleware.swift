// English: Small opt-in HTTP middleware for security and local diagnostics.
// Español: Middleware HTTP pequeño y opcional para seguridad y diagnósticos locales.
// 中文：面向安全和本地诊断的轻量可选 HTTP 中间件。

import Foundation
import zlib

public struct PTHTTPHostPolicy: PTHTTPMiddleware {
    public let allowedHosts: Set<String>

    public init(allowedHosts: Set<String>) {
        self.allowedHosts = Set(allowedHosts.map { $0.lowercased() })
    }

    public func handle(request: PTHTTPRequest, next: @escaping PTHTTPNext) async throws -> PTHTTPResponse {
        guard let host = request.headers.firstValue(for: "Host")?.lowercased(), allowedHosts.contains(host) else {
            return .error(.forbidden)
        }
        return try await next(request)
    }
}

public struct PTHTTPCORSPolicy: PTHTTPMiddleware {
    public let allowedOrigins: Set<String>
    public let allowedMethods: String
    public let allowedHeaders: String

    public init(allowedOrigins: Set<String>, allowedMethods: String = "GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS",
                allowedHeaders: String = "Content-Type, Authorization") {
        self.allowedOrigins = allowedOrigins
        self.allowedMethods = allowedMethods
        self.allowedHeaders = allowedHeaders
    }

    public func handle(request: PTHTTPRequest, next: @escaping PTHTTPNext) async throws -> PTHTTPResponse {
        guard let origin = request.headers.firstValue(for: "Origin"), allowedOrigins.contains(origin) else {
            return try await next(request)
        }
        if request.method == .options {
            return PTHTTPResponse(status: .noContent, headers: responseHeaders(origin))
        }
        var response = try await next(request)
        for (name, value) in responseHeaders(origin).all { response.headers = response.headers.setting(value, for: name) }
        return response
    }

    private func responseHeaders(_ origin: String) -> PTHTTPHeaders {
        PTHTTPHeaders(["Access-Control-Allow-Origin": origin, "Access-Control-Allow-Methods": allowedMethods,
                       "Access-Control-Allow-Headers": allowedHeaders, "Vary": "Origin"])
    }
}

public struct PTHTTPBearerAuthentication: PTHTTPMiddleware {
    public let token: String

    public init(token: String) { self.token = token }

    public func handle(request: PTHTTPRequest, next: @escaping PTHTTPNext) async throws -> PTHTTPResponse {
        let value = request.headers.firstValue(for: "Authorization") ?? ""
        guard value == "Bearer \(token)" else {
            return PTHTTPResponse(status: .unauthorized, headers: PTHTTPHeaders(["WWW-Authenticate": "Bearer"]))
        }
        return try await next(request)
    }
}

public actor PTHTTPRateLimiter {
    private let limit: Int
    private let interval: Duration
    private var buckets: [String: (started: ContinuousClock.Instant, count: Int)] = [:]

    public init(limit: Int = 120, interval: Duration = .seconds(60)) {
        self.limit = max(1, limit)
        self.interval = interval
    }

    public func allows(_ key: String) -> Bool {
        let now = ContinuousClock.now
        if let bucket = buckets[key], bucket.started.duration(to: now) < interval {
            guard bucket.count < limit else { return false }
            buckets[key] = (bucket.started, bucket.count + 1)
            return true
        }
        buckets[key] = (now, 1)
        return true
    }
}

public struct PTHTTPRateLimitMiddleware: PTHTTPMiddleware {
    public let limiter: PTHTTPRateLimiter

    public init(limiter: PTHTTPRateLimiter = PTHTTPRateLimiter()) { self.limiter = limiter }

    public func handle(request: PTHTTPRequest, next: @escaping PTHTTPNext) async throws -> PTHTTPResponse {
        let key = request.remoteEndpoint ?? "unknown"
        guard await limiter.allows(key) else { return .error(.tooManyRequests) }
        return try await next(request)
    }
}

// English: Compress only negotiated text-like response bodies with native zlib.
// Español: Comprime solo cuerpos de texto negociados usando zlib nativo.
// 中文：仅对协商成功的文本类响应使用系统 zlib 压缩。
public struct PTHTTPCompressionMiddleware: PTHTTPMiddleware {
    public let minimumBytes: Int

    public init(minimumBytes: Int = 1_024) {
        self.minimumBytes = max(0, minimumBytes)
    }

    public func handle(request: PTHTTPRequest, next: @escaping PTHTTPNext) async throws -> PTHTTPResponse {
        var response = try await next(request)
        guard request.headers.values(for: "Accept-Encoding").contains(where: { $0.localizedCaseInsensitiveContains("gzip") }),
              response.headers["Content-Encoding"] == nil,
              isCompressible(response.headers.firstValue(for: "Content-Type")) else {
            return response
        }

        let body: Data
        switch response.body {
        case .data(let data): body = data
        case .text(let text, let encoding):
            guard let data = text.data(using: encoding) else { return response }
            body = data
        default:
            return response
        }
        guard body.count >= minimumBytes, let compressed = Self.gzip(body) else { return response }
        response.body = .data(compressed)
        response.headers = response.headers
            .removing("Content-Length")
            .setting("gzip", for: "Content-Encoding")
            .setting("Accept-Encoding", for: "Vary")
        return response
    }

    private func isCompressible(_ contentType: String?) -> Bool {
        guard let contentType = contentType?.lowercased() else { return false }
        return contentType.hasPrefix("text/") || contentType.contains("json") || contentType.contains("javascript") || contentType.contains("xml") || contentType.contains("svg")
    }

    private static func gzip(_ data: Data) -> Data? {
        guard data.count <= Int(UInt32.max) else { return nil }
        var stream = z_stream()
        let initCode = deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 31, 8, Z_DEFAULT_STRATEGY,
                                     ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initCode == Z_OK else { return nil }
        defer { deflateEnd(&stream) }
        return data.withUnsafeBytes { input in
            guard let base = input.bindMemory(to: UInt8.self).baseAddress else { return Data() }
            stream.next_in = UnsafeMutablePointer(mutating: base)
            stream.avail_in = uInt(data.count)
            var result = Data()
            var status: Int32 = Z_OK
            repeat {
                var output = [UInt8](repeating: 0, count: 32 * 1024)
                let produced = output.withUnsafeMutableBufferPointer { buffer -> Int in
                    stream.next_out = buffer.baseAddress
                    stream.avail_out = uInt(buffer.count)
                    status = deflate(&stream, Z_FINISH)
                    return buffer.count - Int(stream.avail_out)
                }
                result.append(contentsOf: output.prefix(produced))
            } while status == Z_OK
            return status == Z_STREAM_END ? result : nil
        }
    }
}
