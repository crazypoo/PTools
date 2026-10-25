// The last privacy boundary before serialization or any transport.
import Foundation
#if SWIFT_PACKAGE
import PooToolsDEBUG
#endif

public struct PTStudioPrivacyGate: Sendable {
    public var policy: PTNetworkPrivacyPolicy
    public let maximumPreviewBytes: Int
    public let includeURLPath: Bool

    public init(policy: PTNetworkPrivacyPolicy = .default,
                maximumPreviewBytes: Int = 16 * 1024,
                includeURLPath: Bool = false) {
        self.policy = policy
        self.maximumPreviewBytes = max(0, min(maximumPreviewBytes, 64 * 1024))
        self.includeURLPath = includeURLPath
    }

    // Only include host by default. Strip basic-auth, fragments and *all* query values,
    // including unfamiliar parameter names that the normal redactor does not recognize.
    public func safeURL(_ url: URL) -> String {
        let redacted = policy.redact(url)
        guard var parts = URLComponents(url: redacted, resolvingAgainstBaseURL: false) else {
            return "[REDACTED_URL]"
        }
        parts.user = nil
        parts.password = nil
        parts.fragment = nil
        parts.queryItems = parts.queryItems?.map { URLQueryItem(name: $0.name, value: policy.replacement) }
        if !includeURLPath { parts.path = "/" }
        return parts.string ?? "[REDACTED_URL]"
    }

    // Names remain useful; values are removed by default rather than depending
    // on a blacklist that may miss custom application credentials.
    public func safeHeaders(_ headers: [String: String]) -> [String: String] {
        policy.redact(headers).mapValues { _ in policy.replacement }
    }

    public func safeBody(_ body: PTNetworkBodyCapture, mimeType: String?) -> PTStudioBodySnapshot {
        let total = body.totalBytes
        guard maximumPreviewBytes > 0,
              let mimeType, mimeType.localizedCaseInsensitiveContains("json"),
              let data = body.previewData, !data.isEmpty, data.count <= maximumPreviewBytes,
              (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil else {
            return PTStudioBodySnapshot(totalBytes: total, preview: nil, truncated: total > 0)
        }
        // Apply the same recursive JSON privacy policy used by DebugNetwork.
        let filtered = policy.redact(data, mimeType: mimeType)
        guard filtered.count <= maximumPreviewBytes,
              let preview = String(data: filtered, encoding: .utf8) else {
            return PTStudioBodySnapshot(totalBytes: total, preview: nil, truncated: total > 0)
        }
        return PTStudioBodySnapshot(totalBytes: total, preview: preview,
                                    truncated: Int64(data.count) < total)
    }

    public func map(_ record: PTNetworkCaptureRecord) -> PTStudioCaptureSnapshot {
        // First run the canonical policy. Never encode PTNetworkCaptureRecord
        // directly: it can hold raw Data and .file(url:) local paths.
        let safe = record.redacted(using: policy)
        let requestContentType = record.request.headers.first {
            $0.key.caseInsensitiveCompare("Content-Type") == .orderedSame
        }?.value
        return PTStudioCaptureSnapshot(
            method: safe.request.method,
            url: safeURL(safe.request.url),
            requestHeaders: safeHeaders(safe.request.headers),
            responseHeaders: safeHeaders(safe.response?.headers ?? [:]),
            requestBody: safeBody(safe.request.body, mimeType: requestContentType),
            responseBody: safe.response.map { safeBody($0.body, mimeType: $0.mimeType) },
            status: safe.response?.statusCode,
            durationSeconds: safe.timing.duration,
            completion: safe.completion?.rawValue,
            // Do not transmit free-form error messages (they can embed token values).
            errorDomain: safe.error.map { _ in "[REDACTED_ERROR_DOMAIN]" },
            errorCode: safe.error?.code,
            redirectCount: safe.redirects.count,
            fetchSource: safe.fetchSource?.rawValue,
            recordSequence: safe.sequence,
            startedAt: safe.timing.startedAt
        )
    }
}
