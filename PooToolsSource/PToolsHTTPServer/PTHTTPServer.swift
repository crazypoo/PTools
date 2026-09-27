// English: Actor-backed HTTP/1.1 server and Network.framework transport.
// Español: Servidor HTTP/1.1 respaldado por actores y transporte Network.framework.
// 中文：基于 Actor 和 Network.framework 的 HTTP/1.1 服务器。

import Foundation
import UniformTypeIdentifiers
import Security
@preconcurrency import Network

private struct PTHTTPRoute: Sendable {
    let method: PTHTTPMethod
    let path: String
    let priority: Int
    let order: UInt64
    let handler: PTHTTPHandler

    var segments: [Substring] { path.split(separator: "/", omittingEmptySubsequences: true) }

    func match(_ requestPath: String) -> (score: Int, parameters: [String: String])? {
        let routeSegments = segments
        let requestSegments = requestPath.split(separator: "/", omittingEmptySubsequences: true)
        var parameters: [String: String] = [:]
        var index = 0
        while index < routeSegments.count {
            let routeSegment = routeSegments[index]
            if routeSegment.first == "*" {
                let name = String(routeSegment.dropFirst())
                parameters[name] = requestSegments.dropFirst(index).map(String.init).joined(separator: "/")
                return (score: 100 + priority, parameters: parameters)
            }
            guard index < requestSegments.count else { return nil }
            let requestSegment = String(requestSegments[index])
            if routeSegment.first == ":" {
                parameters[String(routeSegment.dropFirst())] = requestSegment
            } else if routeSegment != Substring(requestSegment) {
                return nil
            }
            index += 1
        }
        guard index == requestSegments.count else { return nil }
        let exactness = routeSegments.reduce(0) { score, segment in score + (segment.first == ":" ? 10 : 20) }
        return (score: exactness + priority, parameters: parameters)
    }
}

private struct PTHTTPRouterSnapshot: Sendable {
    let routes: [PTHTTPRoute]

    func resolve(_ request: PTHTTPRequest) -> (PTHTTPRoute, [String: String])? {
        let candidates = routes.compactMap { route -> (PTHTTPRoute, [String: String], Int)? in
            guard route.method == request.method || (request.method == .head && route.method == .get) else { return nil }
            guard let match = route.match(request.path) else { return nil }
            return (route, match.parameters, match.score)
        }
        return candidates.sorted {
            if $0.2 != $1.2 { return $0.2 > $1.2 }
            return $0.0.order < $1.0.order
        }.first.map { ($0.0, $0.1) }
    }

    func allowedMethods(for path: String) -> [PTHTTPMethod] {
        routes.filter { $0.match(path) != nil }.map(\.method).reduce(into: []) { result, method in
            if !result.contains(method) { result.append(method) }
        }
    }
}

private final class PTHTTPNetworkConnectionTransport: @unchecked Sendable {
    let connection: NWConnection
    let queue: DispatchQueue
    let remoteEndpoint: String?
    let isLoopback: Bool

    init(connection: NWConnection) {
        self.connection = connection
        queue = DispatchQueue(label: "com.pootools.http.connection.\(UUID().uuidString)", qos: .userInitiated)
        remoteEndpoint = Self.endpointDescription(connection.endpoint)
        isLoopback = Self.isLoopbackEndpoint(connection.endpoint)
    }

    func start(onState: @escaping @Sendable (Bool, String?) -> Void) {
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready: onState(true, nil)
            case .failed(let error): onState(false, error.localizedDescription)
            case .cancelled: onState(false, "cancelled")
            default: break
            }
        }
        connection.start(queue: queue)
    }

    func receive(_ handler: @escaping @Sendable (Data?, Bool, String?) -> Void) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { content, _, complete, error in
            handler(content, complete, error?.localizedDescription)
        }
    }

    func send(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error { continuation.resume(throwing: PTHTTPServerError.listenerFailed(error.localizedDescription)) }
                else { continuation.resume(returning: ()) }
            })
        }
    }

    func cancel() { connection.cancel() }

    private static func endpointDescription(_ endpoint: NWEndpoint) -> String? {
        switch endpoint {
        case .hostPort(let host, let port): return "\(host):\(port)"
        default: return nil
        }
    }

    private static func isLoopbackEndpoint(_ endpoint: NWEndpoint) -> Bool {
        switch endpoint {
        case .hostPort(let host, _):
            let value = host.debugDescription.lowercased()
            return value == "127.0.0.1" || value == "localhost" || value == "::1" || value.contains("::1")
        default: return false
        }
    }
}

private enum PTHTTPListenerEvent: Sendable {
    case ready
    case failed(String)
    case cancelled
}

public actor PTHTTPServer {
    public private(set) var state: PTHTTPServerState = .stopped

    private let configuration: PTHTTPServerConfiguration
    private var listener: NWListener?
    private var startContinuation: CheckedContinuation<PTHTTPServerEndpoint, Error>?
    private var routes: [PTHTTPRoute] = []
    private var middlewares: [any PTHTTPMiddleware] = []
    private var nextRouteOrder: UInt64 = 0
    private var connections: [UUID: PTHTTPConnection] = [:]
    private var metrics = PTHTTPServerMetrics()
    private var endpoint: PTHTTPServerEndpoint?
    private var isStopping = false

    public init(configuration: PTHTTPServerConfiguration = PTHTTPServerConfiguration()) {
        self.configuration = configuration
    }

    public func get(_ path: String, priority: Int = 0, handler: @escaping PTHTTPHandler) {
        register(method: .get, path: path, priority: priority, handler: handler)
    }

    public func head(_ path: String, priority: Int = 0, handler: @escaping PTHTTPHandler) {
        register(method: .head, path: path, priority: priority, handler: handler)
    }

    public func post(_ path: String, priority: Int = 0, handler: @escaping PTHTTPHandler) {
        register(method: .post, path: path, priority: priority, handler: handler)
    }

    public func put(_ path: String, priority: Int = 0, handler: @escaping PTHTTPHandler) {
        register(method: .put, path: path, priority: priority, handler: handler)
    }

    public func patch(_ path: String, priority: Int = 0, handler: @escaping PTHTTPHandler) {
        register(method: .patch, path: path, priority: priority, handler: handler)
    }

    public func delete(_ path: String, priority: Int = 0, handler: @escaping PTHTTPHandler) {
        register(method: .delete, path: path, priority: priority, handler: handler)
    }

    public func options(_ path: String, priority: Int = 0, handler: @escaping PTHTTPHandler) {
        register(method: .options, path: path, priority: priority, handler: handler)
    }

    public func sse(_ path: String, priority: Int = 0,
                    handler: @escaping @Sendable (PTHTTPRequest) async throws -> PTHTTPSSEStream) {
        get(path, priority: priority) { request in
            PTHTTPResponse.sse(try await handler(request))
        }
    }

    public func use(_ middleware: any PTHTTPMiddleware) { middlewares.append(middleware) }

    public func serveDirectory(_ path: String = "/*path", directory: URL, index: String? = "index.html",
                               symlinkPolicy: PTHTTPSymlinkPolicy = .deny) {
        let handler = PTHTTPStaticFileHandler(root: directory, indexFile: index, symlinkPolicy: symlinkPolicy)
        get(path) { request in try await handler.handle(request: request) }
        if path != "/" {
            get("/") { request in try await handler.handle(request: request) }
        }
    }

    public func start() async throws -> PTHTTPServerEndpoint {
        guard listener == nil else { throw PTHTTPServerError.alreadyRunning }
        guard configuration.port <= 65_535 else { throw PTHTTPServerError.invalidConfiguration("端口无效 / Invalid port / Puerto inválido") }
        let parameters = try makeParameters()
        let listener: NWListener
        if configuration.port == 0 {
            listener = try NWListener(using: parameters)
        } else {
            guard let requestedPort = NWEndpoint.Port(rawValue: configuration.port) else {
                throw PTHTTPServerError.invalidConfiguration("端口无效 / Invalid port / Puerto inválido")
            }
            listener = try NWListener(using: parameters, on: requestedPort)
        }
        if let serviceName = configuration.serviceName {
            listener.service = NWListener.Service(name: serviceName, type: configuration.serviceType ?? "_ptools-http._tcp")
        }
        self.listener = listener
        isStopping = false
        state = .starting
        listener.stateUpdateHandler = { [weak self] (value: NWListener.State) in
            let event: PTHTTPListenerEvent
            switch value {
            case .ready: event = .ready
            case .failed(let error): event = .failed(error.localizedDescription)
            case .cancelled: event = .cancelled
            default: return
            }
            Task { await self?.handleListenerEvent(event) }
        }
        listener.newConnectionHandler = { [weak self] (connection: NWConnection) in
            let transport = PTHTTPNetworkConnectionTransport(connection: connection)
            Task { await self?.accept(transport) }
        }
        listener.start(queue: DispatchQueue(label: "com.pootools.http.listener", qos: .userInitiated))
        return try await withCheckedThrowingContinuation { continuation in
            startContinuation = continuation
        }
    }

    public func stop() async {
        guard listener != nil else { return }
        state = .stopping
        isStopping = true
        listener?.cancel()
        if !connections.isEmpty {
            try? await ContinuousClock().sleep(for: configuration.shutdownGracePeriod)
        }
        await forceStop()
    }

    public func forceStop() async {
        for connection in connections.values { await connection.stop() }
        connections.removeAll()
        listener = nil
        endpoint = nil
        state = .stopped
        isStopping = false
    }

    public func currentMetrics() -> PTHTTPServerMetrics { metrics }

    fileprivate func process(_ request: PTHTTPRequest) async -> PTHTTPResponse {
        metrics = PTHTTPServerMetrics(activeConnections: metrics.activeConnections, totalConnections: metrics.totalConnections,
                                      totalRequests: metrics.totalRequests + 1, bytesReceived: metrics.bytesReceived + UInt64(request.body.byteCount),
                                      bytesSent: metrics.bytesSent, parseErrors: metrics.parseErrors, activeSSEClients: metrics.activeSSEClients)
        let snapshot = PTHTTPRouterSnapshot(routes: routes)
        guard let resolution = snapshot.resolve(request) else {
            let methods = snapshot.allowedMethods(for: request.path)
            if !methods.isEmpty {
                return PTHTTPResponse.error(.methodNotAllowed).withHeader("Allow", methods.map(\.rawValue).joined(separator: ", "))
            }
            return .error(.notFound)
        }
        let enriched = PTHTTPRequest(id: request.id, method: request.method, scheme: request.scheme,
                                     authority: request.authority, path: request.path, query: request.query,
                                     headers: request.headers, body: request.body, httpVersion: request.httpVersion,
                                     remoteEndpoint: request.remoteEndpoint, parameters: resolution.1, trailers: request.trailers)
        var next: PTHTTPNext = { request in try await resolution.0.handler(request) }
        for middleware in middlewares.reversed() {
            let current = next
            next = { request in try await middleware.handle(request: request, next: current) }
        }
        do {
            return try await next(enriched)
        } catch let error as PTHTTPParserError {
            return .error(error.status, message: error.message)
        } catch let error as PTHTTPServerError {
            return .error(.serviceUnavailable, message: error.localizedDescription)
        } catch {
            return .error(.internalServerError)
        }
    }

    private func register(method: PTHTTPMethod, path: String, priority: Int, handler: @escaping PTHTTPHandler) {
        let normalized = path.isEmpty ? "/" : (path.hasPrefix("/") ? path : "/" + path)
        routes.append(PTHTTPRoute(method: method, path: normalized, priority: priority, order: nextRouteOrder, handler: handler))
        nextRouteOrder += 1
    }

    private func makeParameters() throws -> NWParameters {
        switch configuration.tls {
        case .disabled:
            return NWParameters.tcp
        case .identity(let identity):
            let tls = NWProtocolTLS.Options()
            guard let secIdentity = sec_identity_create(identity.value) else {
                throw PTHTTPServerError.invalidConfiguration("TLS 身份无效 / Invalid TLS identity / Identidad TLS inválida")
            }
            sec_protocol_options_set_local_identity(tls.securityProtocolOptions, secIdentity)
            return NWParameters(tls: tls, tcp: NWProtocolTCP.Options())
        }
    }

    private func handleListenerEvent(_ event: PTHTTPListenerEvent) {
        switch event {
        case .ready:
            let port = listener?.port?.rawValue ?? configuration.port
            let scheme = configuration.tls.isEnabled ? "https" : "http"
            let urls = ["\(scheme)://127.0.0.1:\(port)", "\(scheme)://localhost:\(port)"].compactMap(URL.init(string:))
            let endpoint = PTHTTPServerEndpoint(port: port, urls: urls, bonjourName: configuration.serviceName)
            self.endpoint = endpoint
            state = .ready(endpoint)
            startContinuation?.resume(returning: endpoint)
            startContinuation = nil
        case .failed(let message):
            listener = nil
            state = .failed(message)
            startContinuation?.resume(throwing: PTHTTPServerError.listenerFailed(message))
            startContinuation = nil
        case .cancelled:
            if state == .starting {
                state = .failed("监听器被取消 / Listener cancelled / El listener fue cancelado")
                startContinuation?.resume(throwing: PTHTTPServerError.cancelled)
                startContinuation = nil
            }
        }
    }

    private func accept(_ transport: PTHTTPNetworkConnectionTransport) async {
        guard !isStopping, connections.count < configuration.maxConnections else {
            transport.cancel()
            return
        }
        if configuration.bindScope == .loopback, !transport.isLoopback {
            transport.cancel()
            return
        }
        let id = UUID()
        let connection = PTHTTPConnection(id: id, transport: transport, server: self, configuration: configuration)
        connections[id] = connection
        metrics = PTHTTPServerMetrics(activeConnections: connections.count, totalConnections: metrics.totalConnections + 1,
                                      totalRequests: metrics.totalRequests, bytesReceived: metrics.bytesReceived,
                                      bytesSent: metrics.bytesSent, parseErrors: metrics.parseErrors, activeSSEClients: metrics.activeSSEClients)
        await connection.start()
    }

    fileprivate func removeConnection(_ id: UUID, bytesSent: UInt64 = 0, parseError: Bool = false) {
        connections[id] = nil
        metrics = PTHTTPServerMetrics(activeConnections: connections.count, totalConnections: metrics.totalConnections,
                                      totalRequests: metrics.totalRequests, bytesReceived: metrics.bytesReceived,
                                      bytesSent: metrics.bytesSent + bytesSent, parseErrors: metrics.parseErrors + (parseError ? 1 : 0),
                                      activeSSEClients: metrics.activeSSEClients)
    }

    fileprivate func startSSEClient() {
        metrics = PTHTTPServerMetrics(activeConnections: metrics.activeConnections, totalConnections: metrics.totalConnections,
                                      totalRequests: metrics.totalRequests, bytesReceived: metrics.bytesReceived,
                                      bytesSent: metrics.bytesSent, parseErrors: metrics.parseErrors,
                                      activeSSEClients: metrics.activeSSEClients + 1)
    }

    fileprivate func finishSSEClient() {
        metrics = PTHTTPServerMetrics(activeConnections: metrics.activeConnections, totalConnections: metrics.totalConnections,
                                      totalRequests: metrics.totalRequests, bytesReceived: metrics.bytesReceived,
                                      bytesSent: metrics.bytesSent, parseErrors: metrics.parseErrors,
                                      activeSSEClients: max(0, metrics.activeSSEClients - 1))
    }
}

private extension PTHTTPTLSConfiguration {
    var isEnabled: Bool {
        if case .identity = self { return true }
        return false
    }
}

private extension PTHTTPResponse {
    func withHeader(_ name: String, _ value: String) -> Self {
        var result = self
        result.headers = result.headers.setting(value, for: name)
        return result
    }
}

private actor PTHTTPConnection {
    private let id: UUID
    private let transport: PTHTTPNetworkConnectionTransport
    private let server: PTHTTPServer
    private let configuration: PTHTTPServerConfiguration
    private var parser: PTHTTPParser
    private var requestCount = 0
    private var closed = false
    private var sentBytes: UInt64 = 0
    private var idleTask: Task<Void, Never>?

    init(id: UUID, transport: PTHTTPNetworkConnectionTransport, server: PTHTTPServer, configuration: PTHTTPServerConfiguration) {
        self.id = id
        self.transport = transport
        self.server = server
        self.configuration = configuration
        parser = PTHTTPParser(limits: configuration.parserLimits, maximumBodyBytes: configuration.maxBodyBytes,
                              bodyFileThreshold: configuration.bodyFileThreshold, remoteEndpoint: transport.remoteEndpoint)
    }

    func start() {
        transport.start { [weak self] ready, error in
            Task { await self?.transportStateChanged(ready: ready, error: error) }
        }
    }

    func stop() {
        close()
    }

    private func transportStateChanged(ready: Bool, error: String?) async {
        guard !closed else { return }
        if ready {
            receiveNext()
        } else if error != nil {
            close()
        }
    }

    private func receiveNext() {
        guard !closed else { return }
        armIdleTimeout()
        transport.receive { [weak self] data, complete, error in
            Task { await self?.received(data: data, complete: complete, error: error) }
        }
    }

    private func received(data: Data?, complete: Bool, error: String?) async {
        guard !closed else { return }
        idleTask?.cancel()
        idleTask = nil
        if let data, !data.isEmpty {
            do {
                let requests = try parser.append(data)
                for request in requests {
                    requestCount += 1
                    let keepAlive = shouldKeepAlive(request)
                    let response = await process(request)
                    do {
                        try await write(response, headOnly: request.method == .head, keepAlive: keepAlive)
                    } catch {
                        close()
                        return
                    }
                    cleanup(request.body)
                    if !keepAlive || requestCount >= configuration.maxRequestsPerConnection {
                        close()
                        return
                    }
                }
            } catch let parserError as PTHTTPParserError {
                let response = PTHTTPResponse.error(parserError.status, message: parserError.message)
                try? await write(response, headOnly: false, keepAlive: false)
                cleanupParserFiles()
                await server.removeConnection(id, bytesSent: sentBytes, parseError: true)
                closeTransportOnly()
                return
            } catch {
                cleanupParserFiles()
                close()
                return
            }
        }
        if complete || error != nil {
            close()
        } else {
            receiveNext()
        }
    }

    private func process(_ request: PTHTTPRequest) async -> PTHTTPResponse {
        guard let timeout = configuration.handlerTimeout else {
            return await server.process(request)
        }

        let race = PTHTTPResponseRace()
        let handlerTask = Task {
            let response = await server.process(request)
            await race.resolve(response)
        }
        let timeoutTask = Task {
            do {
                try await ContinuousClock().sleep(for: timeout)
                await race.resolve(.error(.requestTimeout))
            } catch {
                // English: Cancellation is expected when the handler finishes first.
                // Español: La cancelación es esperada cuando el manejador termina primero.
                // 中文：处理器先完成时，取消超时任务是正常路径。
            }
        }
        let response = await race.wait()
        handlerTask.cancel()
        timeoutTask.cancel()
        return response
    }

    private func shouldKeepAlive(_ request: PTHTTPRequest) -> Bool {
        let connection = request.headers.firstValue(for: "Connection")?.lowercased()
        if request.httpVersion == "HTTP/1.0" { return connection?.contains("keep-alive") == true }
        return connection?.contains("close") != true
    }

    private func write(_ response: PTHTTPResponse, headOnly: Bool, keepAlive: Bool) async throws {
        var headers = response.headers
        let bodyLength: UInt64?
        switch response.body {
        case .empty: bodyLength = 0
        case .data(let data): bodyLength = UInt64(data.count)
        case .text(let text, let encoding): bodyLength = UInt64(text.data(using: encoding)?.count ?? 0)
        case .file(let file): bodyLength = file.length
        case .stream, .sse: bodyLength = nil
        }
        if let bodyLength, !headers.contains("Content-Length") { headers = headers.setting(String(bodyLength), for: "Content-Length") }
        if bodyLength == nil && !headers.contains("Transfer-Encoding") { headers = headers.setting("chunked", for: "Transfer-Encoding") }
        if !keepAlive { headers = headers.setting("close", for: "Connection") }
        if !headers.contains("Date") { headers = headers.setting(Self.httpDate(Date()), for: "Date") }
        if !headers.contains("Server") { headers = headers.setting("PToolsHTTPServer", for: "Server") }
        let statusLine = "HTTP/1.1 \(response.status.rawValue) \(response.status.reasonPhrase)\r\n"
        let headerData = Data((statusLine + headers.serialized() + "\r\n").utf8)
        try await transport.send(headerData)
        sentBytes += UInt64(headerData.count)
        guard !headOnly else { return }
        switch response.body {
        case .empty: break
        case .data(let data): try await sendData(data)
        case .text(let text, let encoding): try await sendData(text.data(using: encoding) ?? Data())
        case .file(let file): try await sendFile(file)
        case .stream(let stream):
            for try await chunk in stream {
                guard !chunk.isEmpty else { continue }
                try await sendChunk(chunk)
            }
            try await sendData(Data("0\r\n\r\n".utf8))
        case .sse(let stream):
            await server.startSSEClient()
            do {
                for try await chunk in stream.stream {
                    guard !chunk.isEmpty else { continue }
                    try await sendChunk(chunk)
                }
                try await sendData(Data("0\r\n\r\n".utf8))
            } catch {
                await server.finishSSEClient()
                throw error
            }
        }
    }

    private func sendData(_ data: Data) async throws {
        guard !data.isEmpty else { return }
        try await transport.send(data)
        sentBytes += UInt64(data.count)
    }

    private func sendChunk(_ data: Data) async throws {
        try await sendData(Data(String(data.count, radix: 16).appending("\r\n").utf8))
        try await sendData(data)
        try await sendData(Data("\r\n".utf8))
    }

    private func sendFile(_ file: PTHTTPFileBody) async throws {
        guard let handle = try? FileHandle(forReadingFrom: file.url) else { throw PTHTTPServerError.listenerFailed("文件无法读取 / File cannot be read / No se puede leer el archivo") }
        defer { try? handle.close() }
        try handle.seek(toOffset: file.offset)
        var remaining = file.length
        while remaining > 0 {
            let count = min(UInt64(64 * 1024), remaining)
            guard let data = try handle.read(upToCount: Int(count)), !data.isEmpty else { break }
            try await sendData(data)
            remaining -= UInt64(data.count)
        }
    }

    private func cleanup(_ body: PTHTTPRequestBody) {
        if case .file(let url) = body { try? FileManager.default.removeItem(at: url) }
    }

    private func cleanupParserFiles() {
        parser.cleanup()
    }

    private func armIdleTimeout() {
        idleTask?.cancel()
        let timeout = configuration.idleTimeout
        idleTask = Task { [weak self] in
            do {
                try await ContinuousClock().sleep(for: timeout)
                guard !Task.isCancelled else { return }
                await self?.idleTimeoutReached()
            } catch {
                // English: Cancellation is the normal path when a connection receives data.
                // Español: La cancelación es normal cuando la conexión recibe datos.
                // 中文：连接收到数据时取消计时任务是正常路径。
            }
        }
    }

    private func idleTimeoutReached() {
        guard !closed else { return }
        close()
    }

    private func close() {
        guard !closed else { return }
        closed = true
        idleTask?.cancel()
        idleTask = nil
        transport.cancel()
        Task { await server.removeConnection(id, bytesSent: sentBytes) }
    }

    private func closeTransportOnly() {
        guard !closed else { return }
        closed = true
        transport.cancel()
    }

    private static func httpDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter.string(from: date)
    }
}

private actor PTHTTPResponseRace {
    private var response: PTHTTPResponse?
    private var continuation: CheckedContinuation<PTHTTPResponse, Never>?

    func wait() async -> PTHTTPResponse {
        if let response { return response }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resolve(_ response: PTHTTPResponse) {
        guard self.response == nil else { return }
        self.response = response
        continuation?.resume(returning: response)
        continuation = nil
    }
}

public enum PTHTTPSymlinkPolicy: Sendable, Equatable {
    case deny
    case allowWithinRoot
}

public struct PTHTTPRange: Sendable, Equatable {
    public let offset: UInt64
    public let length: UInt64

    public init(offset: UInt64, length: UInt64) {
        self.offset = offset
        self.length = length
    }

    public static func parse(_ value: String, size: UInt64) -> Self? {
        guard value.lowercased().hasPrefix("bytes="), !value.contains(",") else { return nil }
        let part = value.dropFirst(6)
        let pieces = part.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        guard pieces.count == 2, size > 0 else { return nil }
        if pieces[0].isEmpty, let suffix = UInt64(pieces[1]), suffix > 0 {
            let length = min(suffix, size)
            return Self(offset: size - length, length: length)
        }
        guard let start = UInt64(pieces[0]), start < size else { return nil }
        let end = pieces[1].isEmpty ? size - 1 : (UInt64(pieces[1]) ?? 0)
        guard end >= start else { return nil }
        return Self(offset: start, length: min(end, size - 1) - start + 1)
    }
}

public struct PTHTTPStaticFileHandler: Sendable {
    public let root: URL
    public let indexFile: String?
    public let symlinkPolicy: PTHTTPSymlinkPolicy

    public init(root: URL, indexFile: String? = "index.html", symlinkPolicy: PTHTTPSymlinkPolicy = .deny) {
        self.root = root.standardizedFileURL
        self.indexFile = indexFile
        self.symlinkPolicy = symlinkPolicy
    }

    public func handle(request: PTHTTPRequest) async throws -> PTHTTPResponse {
        let relative = request.parameters["path"] ?? request.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let candidate = root.appendingPathComponent(relative, isDirectory: false).standardizedFileURL
        let target = candidate.path.isEmpty || candidate.path == root.path ? (indexFile.map { root.appendingPathComponent($0) } ?? root) : candidate
        let resolved = target.resolvingSymlinksInPath()
        guard isInsideRoot(resolved) else { return .error(.forbidden) }
        guard FileManager.default.fileExists(atPath: resolved.path) else { return .error(.notFound) }
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: resolved.path),
              let size = (attributes[.size] as? NSNumber)?.uint64Value else { return .error(.notFound) }
        if symlinkPolicy == .deny, resolved.path != target.standardizedFileURL.path { return .error(.forbidden) }
        let date = attributes[.modificationDate] as? Date
        let etag = "W/\"\(size)-\(Int(date?.timeIntervalSince1970 ?? 0))\""
        if request.headers.firstValue(for: "If-None-Match")?.split(separator: ",").map(String.init).contains(etag) == true {
            return PTHTTPResponse(status: .notModified, headers: PTHTTPHeaders(["ETag": etag]))
        }
        if let modified = date,
           let since = request.headers.firstValue(for: "If-Modified-Since"),
           let sinceDate = Self.httpDate(since),
           sinceDate >= modified {
            return PTHTTPResponse(status: .notModified, headers: PTHTTPHeaders(["ETag": etag]))
        }
        let contentType = UTType(filenameExtension: resolved.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        var headers = PTHTTPHeaders(["Content-Type": contentType, "Accept-Ranges": "bytes", "ETag": etag])
        if let date { headers = headers.setting(Self.httpDate(date), for: "Last-Modified") }
        if let rangeValue = request.headers.firstValue(for: "Range") {
            guard let range = PTHTTPRange.parse(rangeValue, size: size) else {
                return PTHTTPResponse(status: .rangeNotSatisfiable,
                                       headers: headers.setting("bytes */\(size)", for: "Content-Range"), body: .empty)
            }
            headers = headers.setting("bytes \(range.offset)-\(range.offset + range.length - 1)/\(size)", for: "Content-Range")
            return PTHTTPResponse(status: .partialContent, headers: headers,
                                  body: .file(PTHTTPFileBody(url: resolved, offset: range.offset, length: range.length,
                                                             contentType: contentType, etag: etag, modificationDate: date)))
        }
        return PTHTTPResponse(headers: headers, body: .file(PTHTTPFileBody(url: resolved, length: size,
                                                                            contentType: contentType, etag: etag, modificationDate: date)))
    }

    private func isInsideRoot(_ url: URL) -> Bool {
        let rootPath = root.resolvingSymlinksInPath().path
        let path = url.path
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }

    private static func httpDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter.date(from: value)
    }

    private static func httpDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter.string(from: date)
    }
}

public struct PTHTTPURLEncodedForm: Sendable, Equatable {
    public let values: [String: [String]]

    public init(values: [String: [String]]) { self.values = values }

    public static func parse(_ body: PTHTTPRequestBody) -> Self? {
        guard case .data(let data) = body, let string = String(data: data, encoding: .utf8) else { return nil }
        return Self(values: PTHTTPQuery.parse(string).values)
    }
}

public struct PTHTTPMultipartPart: Sendable, Equatable {
    public let headers: PTHTTPHeaders
    public let body: Data

    public init(headers: PTHTTPHeaders, body: Data) {
        self.headers = headers
        self.body = body
    }
}

public enum PTHTTPMultipartParser {
    public static func parse(_ body: PTHTTPRequestBody, boundary: String, maximumParts: Int = 100) -> [PTHTTPMultipartPart] {
        guard case .data(let data) = body, !boundary.isEmpty, let text = String(data: data, encoding: .isoLatin1) else { return [] }
        let marker = "--\(boundary)"
        let sections = text.components(separatedBy: marker).dropFirst().dropLast()
        return sections.prefix(maximumParts).compactMap { section -> PTHTTPMultipartPart? in
            let normalized = section.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n-"))
            guard let separator = normalized.range(of: "\r\n\r\n") else { return nil }
            let headerText = String(normalized[..<separator.lowerBound])
            let bodyText = String(normalized[separator.upperBound...])
            let headerValues = headerText.split(separator: "\r\n").compactMap { line -> (String, String)? in
                let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
                return parts.count == 2 ? (parts[0], parts[1].trimmingCharacters(in: .whitespaces)) : nil
            }
            return PTHTTPMultipartPart(headers: PTHTTPHeaders(values: headerValues), body: bodyText.data(using: .isoLatin1) ?? Data())
        }
    }
}
