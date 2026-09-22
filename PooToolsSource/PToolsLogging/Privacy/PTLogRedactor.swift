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
            return redactText(message)
        case .privateData:
            return "[PRIVATE]"
        case .sensitive:
            return "[REDACTED]"
        }
    }

    // English: Redact common credential markers even when a legacy caller marked the whole message public.
    // Español: Oculta marcadores comunes de credenciales aunque un caller heredado haya marcado todo el mensaje como público.
    // 中文：即使旧调用方把整条消息标记为公开，也隐藏常见凭据标记。
    public static func redactText(_ value: String) -> String {
        var result = value
        let markers = ["Bearer ", "token=", "access_token=", "refresh_token=", "Authorization:", "Cookie:"]
        for marker in markers {
            guard let range = result.range(of: marker, options: .caseInsensitive) else { continue }
            let start = range.upperBound
            let end = result[start...].firstIndex(where: { $0 == " " || $0 == "\n" || $0 == "&" || $0 == "," }) ?? result.endIndex
            result.replaceSubrange(start..<end, with: "[REDACTED]")
        }
        return result
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

    // English: Create a safe immutable record for memory, Debug and Instruments consumers.
    // Español: Crea un registro inmutable y seguro para los consumidores de memoria, Debug e Instruments.
    // 中文：为内存、Debug 和 Instruments 消费者创建安全的不可变日志记录。
    public static func redact(record: PTLogRecord) -> PTLogRecord {
        PTLogRecord(sequence: record.sequence,
                    timestamp: record.timestamp,
                    level: record.level,
                    subsystem: record.subsystem,
                    category: record.category,
                    message: redact(message: record.message, privacy: record.privacy),
                    metadata: redact(metadata: record.metadata, privacy: record.privacy),
                    privacy: record.privacy,
                    file: record.file,
                    function: record.function,
                    line: record.line)
    }
}
