// English: URLProtocol forwards traffic and emits immutable observations only.
// Español: URLProtocol solo reenvía el tráfico y emite observaciones inmutables.
// 中文：URLProtocol 只转发流量并发布不可变观测结果。

import Foundation
import os.lock

private enum PTNetworkCaptureState {
    private static let lock = OSAllocatedUnfairLock<Bool>(initialState: false)

    static var isEnabled: Bool {
        get { lock.withLock { $0 } }
        set { lock.withLock { $0 = newValue } }
    }
}

private enum PTURLProtocolCaptureState: Equatable {
    case idle
    case running
    case finalized
}

// English: URLProtocol is an SDK callback boundary; its mutable state stays on one serial delegate queue.
// Español: URLProtocol es un límite de callbacks del SDK; su estado mutable vive en una cola serial del delegado.
// 中文：URLProtocol 属于 SDK 回调边界；其可变状态只在一个串行代理队列中访问。
final class PTCustomHTTPProtocol: URLProtocol, @unchecked Sendable {
    private static let requestProperty = "com.custom.http.protocol"
    private let bodyPolicy = PTNetworkBodyCapturePolicy()

    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var response: HTTPURLResponse?
    private var responseDate: Date?
    private var responseData = Data()
    private var capturedBytes: Int64 = 0
    private var startedAt = Date()
    private var endedAt: Date?
    private var metrics: PTNetworkTaskMetricsSnapshot?
    private var redirects: [PTNetworkRedirectSnapshot] = []
    private var captureState: PTURLProtocolCaptureState = .idle

    class func start() {
        PTNetworkCaptureState.isEnabled = true
        URLProtocol.registerClass(self)
    }

    class func stop() {
        PTNetworkCaptureState.isEnabled = false
        URLProtocol.unregisterClass(self)
    }

    private class func canServeRequest(_ request: URLRequest) -> Bool {
        guard PTNetworkCaptureState.isEnabled else { return false }
        guard property(forKey: requestProperty, in: request) == nil else { return false }
        guard let scheme = request.url?.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    override class func canInit(with request: URLRequest) -> Bool {
        canServeRequest(request)
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return canServeRequest(request)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        URLProtocol.setProperty(true, forKey: Self.requestProperty, in: mutableRequest)
        let requestToLaunch = mutableRequest as URLRequest
        startedAt = Date()
        captureState = .running

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = (configuration.protocolClasses ?? []).filter { $0 != Self.self }
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
        dataTask = session?.dataTask(with: requestToLaunch)
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
        finalize(error: URLError(.cancelled), completion: .cancelled)
    }

    private func append(_ data: Data) {
        capturedBytes += Int64(data.count)
        let remaining = bodyPolicy.absoluteCaptureLimit - responseData.count
        guard remaining > 0 else { return }
        responseData.append(contentsOf: data.prefix(remaining))
    }

    private func finalize(error: Error?, completion: PTNetworkCaptureCompletion) {
        guard PTNetworkCaptureState.isEnabled, captureState != .finalized else { return }
        captureState = .finalized
        endedAt = Date()

        let requestSnapshot = PTNetworkRequestSnapshot(request: request,
                                                       startedAt: startedAt,
                                                       bodyPolicy: bodyPolicy,
                                                       fileNamespace: UUID().uuidString)
        let responseSnapshot = response.map { value in
            let body = PTNetworkBodyCapture.make(data: responseData,
                                                 totalBytes: capturedBytes,
                                                 policy: bodyPolicy,
                                                 fileNamespace: UUID().uuidString)
            return PTNetworkCaptureResponseSnapshot(statusCode: value.statusCode,
                                             headers: value.allHeaderFields.reduce(into: [:]) { result, pair in
                                                 result[String(describing: pair.key)] = String(describing: pair.value)
                                             },
                                             mimeType: value.mimeType,
                                             body: body)
        }
        let captureError = error.map(PTNetworkCaptureError.init)
        let record = PTNetworkCaptureRecord(request: requestSnapshot,
                                            response: responseSnapshot,
                                            timing: PTNetworkTiming(startedAt: startedAt,
                                                                   responseAt: responseDate,
                                                                   endedAt: endedAt),
                                            metrics: metrics,
                                            error: captureError,
                                            source: .urlProtocol,
                                            completion: completion,
                                            phase: .finalized,
                                            redirects: redirects)
        let redacted = record.redacted()
        let payload: [String: String] = [
            "requestID": record.id.uuidString,
            "method": record.request.method,
            "url": redacted.request.url.absoluteString,
            "statusCode": String(record.response?.statusCode ?? 0),
            "responseBytes": String(record.response?.body.totalBytes ?? 0),
            "duration": String(record.timing.duration ?? 0),
            "source": record.source.rawValue,
            "completion": completion.rawValue
        ]

        Task {
            _ = await PTNetworkCaptureCenter.shared.record(record)
            await MainActor.run {
                PTDebugEventCenter.shared.publish(
                    PTDebugEvent(name: "network.request", source: "urlprotocol", payload: payload)
                )
            }
        }
    }
}

extension PTCustomHTTPProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let from = task.currentRequest?.url, let to = request.url {
            redirects.append(PTNetworkRedirectSnapshot(from: from,
                                                       to: to,
                                                       statusCode: response.statusCode))
        }
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
    }

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response as? HTTPURLResponse
        responseDate = Date()
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        append(data)
        if let startedAt = responseDate {
            let elapsed = Date().timeIntervalSince(startedAt)
            if elapsed > 0 {
                Task { await PTNetworkThroughputMeter.shared.addDownloadSpeed(Double(data.count) / elapsed) }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self.metrics = PTNetworkTaskMetricsSnapshot(metrics: metrics)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            client?.urlProtocol(self, didFailWithError: error)
            let completion: PTNetworkCaptureCompletion = (error as NSError).code == NSURLErrorCancelled ? .cancelled : .failed
            finalize(error: error, completion: completion)
        } else {
            client?.urlProtocolDidFinishLoading(self)
            finalize(error: nil, completion: .completed)
        }
        self.session = nil
        self.dataTask = nil
    }
}

private extension PTNetworkTaskMetricsSnapshot {
    init(metrics: URLSessionTaskMetrics) {
        let transaction = metrics.transactionMetrics.last
        func duration(_ start: Date?, _ end: Date?) -> Duration? {
            guard let start, let end else { return nil }
            return .seconds(max(0, end.timeIntervalSince(start)))
        }

        let requestStart = transaction?.requestStartDate
        let requestEnd = transaction?.requestEndDate
        let responseStart = transaction?.responseStartDate
        let responseEnd = transaction?.responseEndDate
        self.init(dnsDuration: duration(transaction?.domainLookupStartDate, transaction?.domainLookupEndDate),
                  connectDuration: duration(transaction?.connectStartDate, transaction?.connectEndDate),
                  secureConnectionDuration: duration(transaction?.secureConnectionStartDate, transaction?.secureConnectionEndDate),
                  requestDuration: duration(requestStart, requestEnd),
                  ttfb: duration(requestEnd, responseStart),
                  responseDuration: duration(responseStart, responseEnd),
                  redirectCount: max(0, metrics.transactionMetrics.count - 1),
                  protocolName: transaction?.networkProtocolName,
                  isReusedConnection: transaction?.isReusedConnection ?? false,
                  isProxyConnection: transaction?.isProxyConnection ?? false)
    }
}

// English: Keep the historical actor as the storage owner; the correctly named API below is a source-compatible alias.
// Español: Conserva el actor histórico como dueño del almacenamiento; la API con nombre correcto es un alias compatible.
// 中文：保留历史 Actor 作为存储所有者，规范命名 API 通过类型别名保持源码兼容。
public actor PTNetworkSpeedMonitor {
    public static let shared = PTNetworkSpeedMonitor()

    private var downloadSpeeds: [Double] = [0]
    private var uploadSpeeds: [Double] = [0]

    private init() {}

    public func getDownloadSpeeds() -> [Double] { downloadSpeeds }
    public func getUploadSpeeds() -> [Double] { uploadSpeeds }

    public func addDownloadSpeed(_ speed: Double) {
        downloadSpeeds.append(speed)
        if downloadSpeeds.count > 60 { downloadSpeeds.removeFirst(downloadSpeeds.count - 60) }
    }

    public func addUploadSpeed(_ speed: Double) {
        uploadSpeeds.append(speed)
        if uploadSpeeds.count > 60 { uploadSpeeds.removeFirst(uploadSpeeds.count - 60) }
    }

    public func averageDownloadSpeed() -> Double {
        guard !downloadSpeeds.isEmpty else { return 0 }
        return downloadSpeeds.reduce(0, +) / Double(downloadSpeeds.count)
    }

    public func averageUploadSpeed() -> Double {
        guard !uploadSpeeds.isEmpty else { return 0 }
        return uploadSpeeds.reduce(0, +) / Double(uploadSpeeds.count)
    }

    public func clearSpeeds() {
        downloadSpeeds = [0]
        uploadSpeeds = [0]
    }
}

// English: Canonical name for new code without duplicating the actor or its state.
// Español: Nombre canónico para el código nuevo sin duplicar el actor ni su estado.
// 中文：新代码使用的规范名称，不复制 Actor 和状态。
public typealias PTNetworkThroughputMeter = PTNetworkSpeedMonitor
