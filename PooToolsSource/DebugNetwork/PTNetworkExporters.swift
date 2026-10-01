// English: Exporters consume immutable records and redact by default.
// Español: Los exportadores consumen registros inmutables y redactan por defecto.
// 中文：导出器只消费不可变记录，并默认执行脱敏。

import Foundation

public enum PTNetworkCurlExporter {
    public static func string(record: PTNetworkCaptureRecord,
                              policy: PTNetworkPrivacyPolicy = .default,
                              redacted: Bool = true) -> String {
        let value = redacted ? record.redacted(using: policy) : record
        var parts = ["curl", "--request", shell(value.request.method), shell(value.request.url.absoluteString)]
        for (key, header) in value.request.headers.sorted(by: { $0.key < $1.key }) {
            parts.append("--header")
            parts.append(shell("\(key): \(header)"))
        }
        if let data = value.request.body.previewData,
           let body = String(data: data, encoding: .utf8), !body.isEmpty {
            parts.append("--data-raw")
            parts.append(shell(body))
        }
        return parts.joined(separator: " ")
    }

    private static func shell(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

public enum PTNetworkTextExporter {
    public static func string(record: PTNetworkCaptureRecord,
                              policy: PTNetworkPrivacyPolicy = .default,
                              redacted: Bool = true) -> String {
        let value = redacted ? record.redacted(using: policy) : record
        let requestBody = value.request.body.previewData.flatMap { String(data: $0, encoding: .utf8) } ?? "<binary or unavailable>"
        let responseBody = value.response?.body.previewData.flatMap { String(data: $0, encoding: .utf8) } ?? "<binary or unavailable>"
        return """
        [\(value.request.method)] \(value.request.url.absoluteString)
        Status: \(value.response.map { String($0.statusCode) } ?? "pending")
        Duration: \(value.timing.duration.map { String(format: "%.4f s", $0) } ?? "pending")
        Source: \(value.source.rawValue)

        Request headers:
        \(value.request.headers.map { "\($0.key): \($0.value)" }.sorted().joined(separator: "\n"))

        Request body:
        \(requestBody)

        Response headers:
        \(value.response?.headers.map { "\($0.key): \($0.value)" }.sorted().joined(separator: "\n") ?? "")

        Response body:
        \(responseBody)
        """
    }
}

public enum PTNetworkHARExporter {
    public static func data(records: [PTNetworkCaptureRecord],
                            policy: PTNetworkPrivacyPolicy = .default,
                            redacted: Bool = true) throws -> Data {
        let entries = records.map { record -> [String: Any] in
            let value = redacted ? record.redacted(using: policy) : record
            var entry: [String: Any] = [
                "startedDateTime": ISO8601DateFormatter().string(from: value.timing.startedAt),
                "time": Int((value.timing.duration ?? 0) * 1000),
                "request": [
                    "method": value.request.method,
                    "url": value.request.url.absoluteString,
                    "httpVersion": "HTTP/1.1",
                    "headers": value.request.headers.map { ["name": $0.key, "value": $0.value] },
                    "queryString": queryItems(value.request.url),
                    "headersSize": -1,
                    "bodySize": value.request.body.totalBytes
                ],
                "response": [
                    "status": value.response?.statusCode ?? 0,
                    "statusText": value.response.map { HTTPURLResponse.localizedString(forStatusCode: $0.statusCode) } ?? "",
                    "httpVersion": "HTTP/1.1",
                    "headers": value.response?.headers.map { ["name": $0.key, "value": $0.value] } ?? [],
                    "content": [
                        "size": value.response?.body.totalBytes ?? 0,
                        "mimeType": value.response?.mimeType ?? "application/octet-stream"
                    ],
                    "headersSize": -1,
                    "bodySize": value.response?.body.totalBytes ?? 0
                ],
                "cache": [:],
                "timings": timings(value.metrics),
                "_ptools": [
                    "id": value.id.uuidString,
                    "sequence": value.sequence,
                    "source": value.source.rawValue,
                    "completion": value.completion?.rawValue ?? "pending"
                ]
            ]
            if let serverIPAddress = value.response?.headers["X-Server-IP"] { entry["serverIPAddress"] = serverIPAddress }
            return entry
        }
        let document: [String: Any] = [
            "log": [
                "version": "1.2",
                "creator": ["name": "PTools DebugNetwork", "version": "5.59.0"],
                "entries": entries
            ]
        ]
        return try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
    }

    private static func queryItems(_ url: URL) -> [[String: String]] {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.map {
            ["name": $0.name, "value": $0.value ?? ""]
        } ?? []
    }

    private static func timings(_ metrics: PTNetworkTaskMetricsSnapshot?) -> [String: Any] {
        guard let metrics else { return [:] }
        return [
            "dns": milliseconds(metrics.dnsDuration),
            "connect": milliseconds(metrics.connectDuration),
            "ssl": milliseconds(metrics.secureConnectionDuration),
            "send": milliseconds(metrics.requestDuration),
            "wait": milliseconds(metrics.ttfb),
            "receive": milliseconds(metrics.responseDuration)
        ].compactMapValues { $0 }
    }

    private static func milliseconds(_ duration: Duration?) -> Double? {
        guard let duration else { return nil }
        let components = duration.components
        return (Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000) * 1000
    }
}

public enum PTNetworkExportManager {
    public static func curl(record: PTNetworkCaptureRecord,
                            policy: PTNetworkPrivacyPolicy = .default) -> String {
        PTNetworkCurlExporter.string(record: record, policy: policy)
    }

    public static func text(record: PTNetworkCaptureRecord,
                            policy: PTNetworkPrivacyPolicy = .default) -> String {
        PTNetworkTextExporter.string(record: record, policy: policy)
    }

    public static func har(records: [PTNetworkCaptureRecord],
                           policy: PTNetworkPrivacyPolicy = .default) throws -> Data {
        try PTNetworkHARExporter.data(records: records, policy: policy)
    }
}
