// English: Immutable, typed records form the public boundary of the network observer.
// Español: Los registros inmutables y tipados forman el límite público del observador de red.
// 中文：不可变、类型化的记录构成网络观测器的公开边界。

import Foundation

public enum PTNetworkCaptureSource: String, Codable, Sendable {
    case ptoolsNetwork
    case urlProtocol
    case urlSessionDelegate
    case importedHAR
}

public enum PTNetworkFetchSource: String, Codable, Sendable {
    case network
    case urlCacheMemory
    case urlCacheDisk
    case businessCache
}

public enum PTNetworkCapturePhase: String, Codable, Sendable {
    case created
    case requestStarted
    case responseReceived
    case receivingBody
    case finalized
}

public enum PTNetworkCaptureCompletion: String, Codable, Sendable {
    case completed
    case failed
    case cancelled
    case cacheHit
}

public struct PTNetworkBodyCapturePolicy: Sendable, Codable, Equatable {
    public var memoryPreviewLimit: Int
    public var fileThreshold: Int
    public var absoluteCaptureLimit: Int
    public var totalStoreMemoryBudget: Int

    public init(memoryPreviewLimit: Int = 512 * 1024,
                fileThreshold: Int = 2 * 1024 * 1024,
                absoluteCaptureLimit: Int = 50 * 1024 * 1024,
                totalStoreMemoryBudget: Int = 64 * 1024 * 1024) {
        self.memoryPreviewLimit = max(0, memoryPreviewLimit)
        self.fileThreshold = max(self.memoryPreviewLimit, fileThreshold)
        self.absoluteCaptureLimit = max(self.fileThreshold, absoluteCaptureLimit)
        self.totalStoreMemoryBudget = max(self.memoryPreviewLimit, totalStoreMemoryBudget)
    }
}

public enum PTNetworkBodyCapture: Sendable, Codable, Equatable {
    case none
    case complete(data: Data, totalBytes: Int64)
    case truncated(preview: Data, capturedBytes: Int64, totalBytes: Int64)
    case file(url: URL, preview: Data?, totalBytes: Int64)

    public var totalBytes: Int64 {
        switch self {
        case .none:
            return 0
        case let .complete(_, totalBytes), let .truncated(_, _, totalBytes), let .file(_, _, totalBytes):
            return totalBytes
        }
    }

    public var previewData: Data? {
        switch self {
        case .none:
            return nil
        case let .complete(data, _):
            return data
        case let .truncated(preview, _, _):
            return preview
        case let .file(_, preview, _):
            return preview
        }
    }

    public var memoryCost: Int {
        previewData?.count ?? 0
    }

    public var diskURL: URL? {
        guard case let .file(url, _, _) = self else { return nil }
        return url
    }

    public static func make(data: Data?,
                            totalBytes: Int64? = nil,
                            policy: PTNetworkBodyCapturePolicy = .init(),
                            fileNamespace: String? = nil) -> PTNetworkBodyCapture {
        guard let data, !data.isEmpty else { return .none }
        let totalBytes = totalBytes ?? Int64(data.count)
        let boundedData = data.prefix(policy.absoluteCaptureLimit)
        let preview = Data(boundedData.prefix(policy.memoryPreviewLimit))

        if data.count > policy.fileThreshold,
           let fileNamespace,
           let directory = try? FileManager.default.url(for: .cachesDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: nil,
                                                         create: true) {
            let directoryURL = directory.appendingPathComponent("PTools/DebugNetwork", isDirectory: true)
            try? FileManager.default.createDirectory(at: directoryURL,
                                                     withIntermediateDirectories: true)
            let fileURL = directoryURL.appendingPathComponent("\(fileNamespace)-\(UUID().uuidString).body")
            if (try? Data(boundedData).write(to: fileURL, options: [.atomic])) != nil {
                return .file(url: fileURL, preview: preview, totalBytes: totalBytes)
            }
        }

        if data.count <= policy.absoluteCaptureLimit {
            return .complete(data: data, totalBytes: totalBytes)
        }
        return .truncated(preview: preview,
                          capturedBytes: Int64(preview.count),
                          totalBytes: totalBytes)
    }
}

public struct PTNetworkRequestSnapshot: Sendable, Codable, Equatable {
    public let url: URL
    public let method: String
    public let headers: [String: String]
    public let body: PTNetworkBodyCapture
    public let startedAt: Date

    public init(url: URL,
                method: String = "GET",
                headers: [String: String] = [:],
                body: PTNetworkBodyCapture = .none,
                startedAt: Date = .now) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.startedAt = startedAt
    }

    public init(request: URLRequest,
                startedAt: Date = .now,
                bodyPolicy: PTNetworkBodyCapturePolicy = .init(),
                fileNamespace: String? = nil) {
        let body: PTNetworkBodyCapture
        if let httpBody = request.httpBody {
            body = .make(data: httpBody,
                         policy: bodyPolicy,
                         fileNamespace: fileNamespace.map { "request-\($0)" })
        } else if request.httpBodyStream != nil {
            // English: Never consume an HTTP body stream just to inspect it; preserve a bounded unknown-size marker.
            // Español: Nunca consume un stream HTTP solo para inspeccionarlo; conserva un marcador acotado de tamaño desconocido.
            // 中文：不要为了检查 HTTP body stream 而消费它，只保留一个有界的未知大小标记。
            body = .truncated(preview: Data(), capturedBytes: 0, totalBytes: -1)
        } else {
            body = .none
        }
        self.init(url: request.url ?? URL(fileURLWithPath: "/"),
                  method: request.httpMethod ?? "GET",
                  headers: request.allHTTPHeaderFields ?? [:],
                  body: body,
                  startedAt: startedAt)
    }
}

public struct PTNetworkCaptureResponseSnapshot: Sendable, Codable, Equatable {
    public let statusCode: Int
    public let headers: [String: String]
    public let mimeType: String?
    public let body: PTNetworkBodyCapture

    public init(statusCode: Int,
                headers: [String: String] = [:],
                mimeType: String? = nil,
                body: PTNetworkBodyCapture = .none) {
        self.statusCode = statusCode
        self.headers = headers
        self.mimeType = mimeType
        self.body = body
    }
}

public struct PTNetworkTiming: Sendable, Codable, Equatable {
    public let startedAt: Date
    public let responseAt: Date?
    public let endedAt: Date?

    public init(startedAt: Date, responseAt: Date? = nil, endedAt: Date? = nil) {
        self.startedAt = startedAt
        self.responseAt = responseAt
        self.endedAt = endedAt
    }

    public var duration: TimeInterval? {
        guard let endedAt else { return nil }
        return max(0, endedAt.timeIntervalSince(startedAt))
    }
}

public struct PTNetworkTaskMetricsSnapshot: Sendable, Codable, Equatable {
    public let dnsDuration: Duration?
    public let connectDuration: Duration?
    public let secureConnectionDuration: Duration?
    public let requestDuration: Duration?
    public let ttfb: Duration?
    public let responseDuration: Duration?
    public let redirectCount: Int
    public let protocolName: String?
    public let isReusedConnection: Bool
    public let isProxyConnection: Bool

    public init(dnsDuration: Duration? = nil,
                connectDuration: Duration? = nil,
                secureConnectionDuration: Duration? = nil,
                requestDuration: Duration? = nil,
                ttfb: Duration? = nil,
                responseDuration: Duration? = nil,
                redirectCount: Int = 0,
                protocolName: String? = nil,
                isReusedConnection: Bool = false,
                isProxyConnection: Bool = false) {
        self.dnsDuration = dnsDuration
        self.connectDuration = connectDuration
        self.secureConnectionDuration = secureConnectionDuration
        self.requestDuration = requestDuration
        self.ttfb = ttfb
        self.responseDuration = responseDuration
        self.redirectCount = max(0, redirectCount)
        self.protocolName = protocolName
        self.isReusedConnection = isReusedConnection
        self.isProxyConnection = isProxyConnection
    }

    private enum CodingKeys: String, CodingKey {
        case dnsDuration, connectDuration, secureConnectionDuration, requestDuration, ttfb, responseDuration
        case redirectCount, protocolName, isReusedConnection, isProxyConnection
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.seconds(dnsDuration), forKey: .dnsDuration)
        try container.encode(Self.seconds(connectDuration), forKey: .connectDuration)
        try container.encode(Self.seconds(secureConnectionDuration), forKey: .secureConnectionDuration)
        try container.encode(Self.seconds(requestDuration), forKey: .requestDuration)
        try container.encode(Self.seconds(ttfb), forKey: .ttfb)
        try container.encode(Self.seconds(responseDuration), forKey: .responseDuration)
        try container.encode(redirectCount, forKey: .redirectCount)
        try container.encode(protocolName, forKey: .protocolName)
        try container.encode(isReusedConnection, forKey: .isReusedConnection)
        try container.encode(isProxyConnection, forKey: .isProxyConnection)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dnsDuration = Self.duration(try container.decodeIfPresent(Double.self, forKey: .dnsDuration))
        connectDuration = Self.duration(try container.decodeIfPresent(Double.self, forKey: .connectDuration))
        secureConnectionDuration = Self.duration(try container.decodeIfPresent(Double.self, forKey: .secureConnectionDuration))
        requestDuration = Self.duration(try container.decodeIfPresent(Double.self, forKey: .requestDuration))
        ttfb = Self.duration(try container.decodeIfPresent(Double.self, forKey: .ttfb))
        responseDuration = Self.duration(try container.decodeIfPresent(Double.self, forKey: .responseDuration))
        redirectCount = try container.decodeIfPresent(Int.self, forKey: .redirectCount) ?? 0
        protocolName = try container.decodeIfPresent(String.self, forKey: .protocolName)
        isReusedConnection = try container.decodeIfPresent(Bool.self, forKey: .isReusedConnection) ?? false
        isProxyConnection = try container.decodeIfPresent(Bool.self, forKey: .isProxyConnection) ?? false
    }

    private static func seconds(_ value: Duration?) -> Double? {
        guard let value else { return nil }
        let components = value.components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }

    private static func duration(_ value: Double?) -> Duration? {
        guard let value, value >= 0 else { return nil }
        return .seconds(value)
    }
}

public struct PTNetworkCaptureError: Error, Sendable, Codable, Equatable {
    public let domain: String
    public let code: Int
    public let description: String
    public let failureReason: String?

    public init(domain: String, code: Int, description: String, failureReason: String? = nil) {
        self.domain = domain
        self.code = code
        self.description = description
        self.failureReason = failureReason
    }

    public init(error: Error) {
        let nsError = error as NSError
        self.init(domain: nsError.domain,
                  code: nsError.code,
                  description: nsError.localizedDescription,
                  failureReason: nsError.localizedFailureReason)
    }
}

public struct PTNetworkRedirectSnapshot: Sendable, Codable, Equatable {
    public let from: URL
    public let to: URL
    public let statusCode: Int
    public let timestamp: Date

    public init(from: URL, to: URL, statusCode: Int, timestamp: Date = .now) {
        self.from = from
        self.to = to
        self.statusCode = statusCode
        self.timestamp = timestamp
    }
}

public struct PTNetworkCaptureRecord: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let sequence: UInt64
    public let request: PTNetworkRequestSnapshot
    public let response: PTNetworkCaptureResponseSnapshot?
    public let timing: PTNetworkTiming
    public let metrics: PTNetworkTaskMetricsSnapshot?
    public let error: PTNetworkCaptureError?
    public let source: PTNetworkCaptureSource
    public let completion: PTNetworkCaptureCompletion?
    public let phase: PTNetworkCapturePhase
    public let redirects: [PTNetworkRedirectSnapshot]
    public let fetchSource: PTNetworkFetchSource?
    public let retryCount: Int

    public init(id: UUID = UUID(),
                sequence: UInt64 = 0,
                request: PTNetworkRequestSnapshot,
                response: PTNetworkCaptureResponseSnapshot? = nil,
                timing: PTNetworkTiming,
                metrics: PTNetworkTaskMetricsSnapshot? = nil,
                error: PTNetworkCaptureError? = nil,
                source: PTNetworkCaptureSource,
                completion: PTNetworkCaptureCompletion? = nil,
                phase: PTNetworkCapturePhase = .created,
                redirects: [PTNetworkRedirectSnapshot] = [],
                fetchSource: PTNetworkFetchSource? = nil,
                retryCount: Int = 0) {
        self.id = id
        self.sequence = sequence
        self.request = request
        self.response = response
        self.timing = timing
        self.metrics = metrics
        self.error = error
        self.source = source
        self.completion = completion
        self.phase = phase
        self.redirects = redirects
        self.fetchSource = fetchSource
        self.retryCount = max(0, retryCount)
    }

    public var isSuccessful: Bool {
        guard error == nil else { return false }
        guard let statusCode = response?.statusCode else { return completion == .completed || completion == .cacheHit }
        return (200..<400).contains(statusCode)
    }

    public var totalBytes: Int64 {
        (request.body.totalBytes) + (response?.body.totalBytes ?? 0)
    }

    public func redacted(using policy: PTNetworkPrivacyPolicy = .default) -> PTNetworkCaptureRecord {
        PTNetworkCaptureRecord(id: id,
                               sequence: sequence,
                               request: policy.redact(request),
                               response: response.map(policy.redact),
                               timing: timing,
                               metrics: metrics,
                               error: error.map(policy.redact),
                               source: source,
                               completion: completion,
                               phase: phase,
                               redirects: redirects.map { policy.redact($0) },
                               fetchSource: fetchSource,
                               retryCount: retryCount)
    }
}

public struct PTNetworkCaptureSummary: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let sequence: UInt64
    public let url: URL
    public let method: String
    public let statusCode: Int?
    public let duration: TimeInterval?
    public let requestBytes: Int64
    public let responseBytes: Int64
    public let mimeType: String?
    public let errorDescription: String?
    public let redirectCount: Int
    public let source: PTNetworkCaptureSource
    public let fetchSource: PTNetworkFetchSource?
    public let completion: PTNetworkCaptureCompletion?
    public let isSuccessful: Bool

    public init(record: PTNetworkCaptureRecord) {
        id = record.id
        sequence = record.sequence
        url = record.request.url
        method = record.request.method
        statusCode = record.response?.statusCode
        duration = record.timing.duration
        requestBytes = record.request.body.totalBytes
        responseBytes = record.response?.body.totalBytes ?? 0
        mimeType = record.response?.mimeType
        errorDescription = record.error?.description
        redirectCount = record.redirects.count
        source = record.source
        fetchSource = record.fetchSource
        completion = record.completion
        isSuccessful = record.isSuccessful
    }
}

public struct PTNetworkCaptureFilter: Sendable, Codable, Equatable {
    public var keyword: String?
    public var host: String?
    public var method: String?
    public var statusCodes: Set<Int>?
    public var minimumDuration: TimeInterval?
    public var minimumResponseBytes: Int64?
    public var minimumRequestBytes: Int64?
    public var mimeType: String?
    public var onlyFailures: Bool
    public var onlyCancelled: Bool
    public var onlyRedirected: Bool
    public var fetchSource: PTNetworkFetchSource?

    public init(keyword: String? = nil,
                host: String? = nil,
                method: String? = nil,
                statusCodes: Set<Int>? = nil,
                minimumDuration: TimeInterval? = nil,
                minimumResponseBytes: Int64? = nil,
                minimumRequestBytes: Int64? = nil,
                mimeType: String? = nil,
                onlyFailures: Bool = false,
                onlyCancelled: Bool = false,
                onlyRedirected: Bool = false,
                fetchSource: PTNetworkFetchSource? = nil) {
        self.keyword = keyword
        self.host = host
        self.method = method
        self.statusCodes = statusCodes
        self.minimumDuration = minimumDuration
        self.minimumResponseBytes = minimumResponseBytes
        self.minimumRequestBytes = minimumRequestBytes
        self.mimeType = mimeType
        self.onlyFailures = onlyFailures
        self.onlyCancelled = onlyCancelled
        self.onlyRedirected = onlyRedirected
        self.fetchSource = fetchSource
    }

    public func matches(_ summary: PTNetworkCaptureSummary) -> Bool {
        if let keyword, !keyword.isEmpty {
            let text = "\(summary.url.absoluteString) \(summary.method) \(summary.statusCode ?? 0)".lowercased()
            guard text.contains(keyword.lowercased()) else { return false }
        }
        if let host, summary.url.host?.localizedCaseInsensitiveCompare(host) != .orderedSame { return false }
        if let method, summary.method.caseInsensitiveCompare(method) != .orderedSame { return false }
        if let statusCodes, !statusCodes.isEmpty, !statusCodes.contains(summary.statusCode ?? 0) { return false }
        if let minimumDuration, (summary.duration ?? 0) < minimumDuration { return false }
        if let minimumResponseBytes, summary.responseBytes < minimumResponseBytes { return false }
        if let minimumRequestBytes, summary.requestBytes < minimumRequestBytes { return false }
        if let mimeType, summary.mimeType?.localizedCaseInsensitiveContains(mimeType) != true { return false }
        if onlyFailures, summary.isSuccessful { return false }
        if onlyCancelled, summary.completion != .cancelled { return false }
        if onlyRedirected, summary.redirectCount == 0 { return false }
        if let fetchSource, summary.fetchSource != fetchSource { return false }
        return true
    }
}

public enum PTNetworkCaptureChange: Sendable, Equatable {
    case inserted(UUID)
    case updated(UUID)
    case removed(UUID)
    case reset
}
