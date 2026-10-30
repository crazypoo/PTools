// English: Redaction is applied before copy, sharing, export, and debug events.
// Español: La redacción se aplica antes de copiar, compartir, exportar y publicar eventos Debug.
// 中文：复制、分享、导出和 Debug 事件发布前统一执行脱敏。

import Foundation

public struct PTNetworkSensitiveKeyRegistry: Sendable, Codable, Equatable {
    public var keys: Set<String>

    public init(keys: Set<String> = [
        "authorization", "proxy-authorization", "cookie", "set-cookie", "x-api-key",
        "api_key", "token", "access_token", "refresh_token", "password", "passwd",
        "secret", "session", "code"
    ]) {
        self.keys = Set(keys.map { $0.lowercased() })
    }

    public func contains(_ key: String) -> Bool {
        keys.contains(key.lowercased())
    }
}

public struct PTNetworkPrivacyPolicy: Sendable, Codable, Equatable {
    public var registry: PTNetworkSensitiveKeyRegistry
    public var replacement: String

    public init(registry: PTNetworkSensitiveKeyRegistry = .init(), replacement: String = "[REDACTED]") {
        self.registry = registry
        self.replacement = replacement
    }

    public static let `default` = PTNetworkPrivacyPolicy()

    public func redact(_ request: PTNetworkRequestSnapshot) -> PTNetworkRequestSnapshot {
        let contentType = request.headers.first { $0.key.caseInsensitiveCompare("Content-Type") == .orderedSame }?.value
        return PTNetworkRequestSnapshot(url: redact(request.url),
                                        method: request.method,
                                        headers: redact(request.headers),
                                        body: redact(request.body, mimeType: contentType),
                                        startedAt: request.startedAt)
    }

    public func redact(_ response: PTNetworkCaptureResponseSnapshot) -> PTNetworkCaptureResponseSnapshot {
        PTNetworkCaptureResponseSnapshot(statusCode: response.statusCode,
                                  headers: redact(response.headers),
                                  mimeType: response.mimeType,
                                  body: redact(response.body, mimeType: response.mimeType))
    }

    public func redact(_ redirect: PTNetworkRedirectSnapshot) -> PTNetworkRedirectSnapshot {
        PTNetworkRedirectSnapshot(from: redact(redirect.from),
                                  to: redact(redirect.to),
                                  statusCode: redirect.statusCode,
                                  timestamp: redirect.timestamp)
    }

    public func redact(_ error: PTNetworkCaptureError) -> PTNetworkCaptureError {
        PTNetworkCaptureError(domain: error.domain,
                              code: error.code,
                              description: error.description.replacingOccurrences(of: "token", with: replacement, options: .caseInsensitive),
                              failureReason: error.failureReason?.replacingOccurrences(of: "token", with: replacement, options: .caseInsensitive))
    }

    public func redact(_ body: PTNetworkBodyCapture, mimeType: String? = nil) -> PTNetworkBodyCapture {
        switch body {
        case .none:
            return .none
        case let .complete(data, totalBytes):
            return .complete(data: redact(data, mimeType: mimeType), totalBytes: totalBytes)
        case let .truncated(preview, capturedBytes, totalBytes):
            return .truncated(preview: redact(preview, mimeType: mimeType),
                              capturedBytes: capturedBytes,
                              totalBytes: totalBytes)
        case let .file(url, preview, totalBytes):
            return .file(url: url,
                         preview: preview.map { redact($0, mimeType: mimeType) },
                         totalBytes: totalBytes)
        }
    }

    public func redact(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return url
        }
        components.queryItems = queryItems.map { item in
            guard registry.contains(item.name) else { return item }
            return URLQueryItem(name: item.name, value: replacement)
        }
        return components.url ?? url
    }

    public func redact(_ headers: [String: String]) -> [String: String] {
        headers.reduce(into: [:]) { result, pair in
            result[pair.key] = registry.contains(pair.key) ? replacement : pair.value
        }
    }

    public func redact(_ data: Data, mimeType: String?) -> Data {
        guard let mimeType, mimeType.localizedCaseInsensitiveContains("json") else { return data }
        guard var object = try? JSONSerialization.jsonObject(with: data) else { return data }
        redactJSON(&object)
        return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? data
    }

    private func redactJSON(_ value: inout Any) {
        if var dictionary = value as? [String: Any] {
            for key in dictionary.keys {
                if registry.contains(key) {
                    dictionary[key] = replacement
                } else if var child = dictionary[key] {
                    redactJSON(&child)
                    dictionary[key] = child
                }
            }
            value = dictionary
            return
        }
        if var array = value as? [Any] {
            for index in array.indices {
                redactJSON(&array[index])
            }
            value = array
        }
    }
}

public enum PTNetworkRedactor {
    public static func redact(url: URL, policy: PTNetworkPrivacyPolicy = .default) -> URL {
        policy.redact(url)
    }

    public static func redact(headers: [String: String], policy: PTNetworkPrivacyPolicy = .default) -> [String: String] {
        policy.redact(headers)
    }

    public static func redact(record: PTNetworkCaptureRecord,
                              policy: PTNetworkPrivacyPolicy = .default) -> PTNetworkCaptureRecord {
        record.redacted(using: policy)
    }
}
