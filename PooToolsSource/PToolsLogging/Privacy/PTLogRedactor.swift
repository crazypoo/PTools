//
//  PTLogRedactor.swift
//  PToolsLogging
//
// English: Redacts sensitive log values before they reach persistent destinations.
// Español: Redacta los valores sensibles antes de que lleguen a destinos persistentes.
// 中文：在敏感日志写入持久化目标前进行脱敏。
//

import Foundation

public enum PTLogRedactor {
    public static let sensitiveKeys: Set<String> = [
        "password",
        "passwd",
        "token",
        "access_token",
        "refresh_token",
        "authorization",
        "cookie",
        "set-cookie",
        "secret",
        "private_key",
        "client_secret",
        "api_key",
        "session"
    ]

    public static func isSensitiveKey(_ key: String) -> Bool {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return sensitiveKeys.contains { normalizedKey == $0 || normalizedKey.contains($0) }
    }

    public static func redact(message: String, privacy: PTLogPrivacy) -> String {
        switch privacy {
        case .public:
            return message
        case .privateData:
            return "[PRIVATE]"
        case .sensitive:
            return "[REDACTED]"
        }
    }

    public static func redact(metadata: PTLogMetadata,
                              privacy: PTLogPrivacy = .public) -> PTLogMetadata {
        metadata.reduce(into: PTLogMetadata()) { result, item in
            if isSensitiveKey(item.key) {
                result[item.key] = "[REDACTED]"
            } else {
                result[item.key] = redact(message: item.value, privacy: privacy)
            }
        }
    }

    public static func formatMetadata(_ metadata: PTLogMetadata,
                                     privacy: PTLogPrivacy = .public) -> String {
        let redacted = redact(metadata: metadata, privacy: privacy)
        guard !redacted.isEmpty else { return "" }
        return redacted.keys.sorted().compactMap { key in
            guard let value = redacted[key] else { return nil }
            return "\(key)=\(value)"
        }.joined(separator: " ")
    }
}
