import Foundation

/// Foundation-only privacy gate shared by Studio diagnostics and Debug producers.
/// Identities, parent references, and protocol version remain stable; only
/// human-readable content is redacted before transport or export.
public enum PTStudioDiagnosticPrivacy {
    private static let sensitiveKeys = [
        "authorization", "cookie", "token", "password", "secret",
        "credential", "private", "keychain", "sessionid", "apikey"
    ]

    public static func scrub(_ value: String) -> String {
        var result = String(value.prefix(256))
        let patterns: [(String, String)] = [
            (#"(?i)\b(bearer\s+)[a-z0-9._~+/-]+"#, "$1[REDACTED]"),
            (#"(?i)\b(token|password|secret|api[_-]?key|authorization)\s*[:=]\s*[^\s&,;]+"#, "$1=[REDACTED]"),
            (#"(?i)[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}"#, "[REDACTED_EMAIL]"),
            (#"(?i)(https?://[^\s?#]+)\?[^\s#]+"#, "$1?[REDACTED]")
        ]
        for (pattern, replacement) in patterns {
            result = result.replacingOccurrences(of: pattern, with: replacement,
                                                  options: .regularExpression)
        }
        return result
    }

    public static func sanitize(_ reply: PTStudioDiagnosticReply) -> PTStudioDiagnosticReply {
        let entries = reply.entries.prefix(1_200).map { item in
            let attributes = item.attributes.filter { key, _ in
                !sensitiveKeys.contains(where: {
                    key.replacingOccurrences(of: "_", with: "").lowercased().contains($0)
                })
            }.mapValues { scrub($0) }
            return PTStudioDiagnosticEntry(
                id: item.id, parentID: item.parentID, kind: item.kind,
                name: scrub(item.name), detail: item.detail.map(scrub),
                frame: item.frame, attributes: attributes,
                previewBase64: item.previewBase64)
        }
        return PTStudioDiagnosticReply(
            id: reply.id, sessionID: reply.sessionID,
            success: reply.success, message: reply.message.map(scrub),
            entries: entries)
    }
}
