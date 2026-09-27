// English: Local file portal built on top of the native PTools HTTP server.
// Español: Portal local de archivos construido sobre el servidor HTTP nativo de PTools.
// 中文：基于 PTools 原生 HTTP Server 的本地文件门户。

import Foundation
#if SWIFT_PACKAGE
import PToolsHTTPServer
#endif

public struct PTHTTPFilePortalConfiguration: Sendable {
    public let rootDirectory: URL
    public var allowsUpload: Bool
    public var allowsDownload: Bool
    public var allowsDelete: Bool
    public var allowsCreateDirectory: Bool
    public var allowsRename: Bool
    public var allowedFileExtensions: Set<String>
    public var maximumUploadBytes: Int64
    public var sessionToken: String?

    public init(rootDirectory: URL, allowsUpload: Bool = true, allowsDownload: Bool = true,
                allowsDelete: Bool = false, allowsCreateDirectory: Bool = false, allowsRename: Bool = false,
                allowedFileExtensions: Set<String> = [], maximumUploadBytes: Int64 = 256 * 1024 * 1024,
                sessionToken: String? = nil) {
        self.rootDirectory = rootDirectory.standardizedFileURL
        self.allowsUpload = allowsUpload
        self.allowsDownload = allowsDownload
        self.allowsDelete = allowsDelete
        self.allowsCreateDirectory = allowsCreateDirectory
        self.allowsRename = allowsRename
        self.allowedFileExtensions = Set(allowedFileExtensions.map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) })
        self.maximumUploadBytes = max(1, maximumUploadBytes)
        self.sessionToken = sessionToken
    }
}

public actor PTHTTPFilePortal {
    public let server: PTHTTPServer
    public let configuration: PTHTTPFilePortalConfiguration

    private var routesInstalled = false

    public init(configuration: PTHTTPFilePortalConfiguration,
                serverConfiguration: PTHTTPServerConfiguration = PTHTTPServerConfiguration(bindScope: .localNetwork)) {
        self.configuration = configuration
        var effectiveConfiguration = serverConfiguration
        effectiveConfiguration.maxBodyBytes = max(effectiveConfiguration.maxBodyBytes, configuration.maximumUploadBytes)
        effectiveConfiguration.bodyFileThreshold = min(effectiveConfiguration.bodyFileThreshold, effectiveConfiguration.maxBodyBytes)
        server = PTHTTPServer(configuration: effectiveConfiguration)
    }

    public func start() async throws -> PTHTTPServerEndpoint {
        try FileManager.default.createDirectory(at: configuration.rootDirectory, withIntermediateDirectories: true)
        if !routesInstalled {
            await installRoutes()
            routesInstalled = true
        }
        return try await server.start()
    }

    public func stop() async { await server.stop() }
    public func forceStop() async { await server.forceStop() }
    public func metrics() async -> PTHTTPServerMetrics { await server.currentMetrics() }

    private func installRoutes() async {
        await server.get("/") { [weak self] request in
            guard let self else { return .error(.serviceUnavailable) }
            return await self.indexResponse(request)
        }
        await server.get("/api/files") { [weak self] request in
            guard let self else { return .error(.serviceUnavailable) }
            return await self.listResponse(request)
        }
        await server.get("/download/*path") { [weak self] request in
            guard let self else { return .error(.serviceUnavailable) }
            return await self.downloadResponse(request)
        }
        await server.post("/api/upload") { [weak self] request in
            guard let self else { return .error(.serviceUnavailable) }
            return await self.uploadResponse(request)
        }
        await server.post("/api/directories") { [weak self] request in
            guard let self else { return .error(.serviceUnavailable) }
            return await self.createDirectoryResponse(request)
        }
        await server.patch("/api/files/*path") { [weak self] request in
            guard let self else { return .error(.serviceUnavailable) }
            return await self.renameResponse(request)
        }
        await server.delete("/api/files/*path") { [weak self] request in
            guard let self else { return .error(.serviceUnavailable) }
            return await self.deleteResponse(request)
        }
    }

    private func indexResponse(_ request: PTHTTPRequest) -> PTHTTPResponse {
        guard authorized(request) else { return .error(.unauthorized) }
        return PTHTTPResponse(status: .ok, headers: PTHTTPHeaders(["Content-Type": "text/html; charset=utf-8"]), body: .text(Self.indexHTML))
    }

    private func listResponse(_ request: PTHTTPRequest) async -> PTHTTPResponse {
        guard authorized(request) else { return .error(.unauthorized) }
        let items = listFiles(at: configuration.rootDirectory)
        do { return try .json(items) }
        catch { return .error(.internalServerError) }
    }

    private func downloadResponse(_ request: PTHTTPRequest) async -> PTHTTPResponse {
        guard authorized(request), configuration.allowsDownload else { return .error(.forbidden) }
        let handler = PTHTTPStaticFileHandler(root: configuration.rootDirectory, indexFile: nil, symlinkPolicy: .deny)
        return (try? await handler.handle(request: request)) ?? .error(.notFound)
    }

    private func uploadResponse(_ request: PTHTTPRequest) -> PTHTTPResponse {
        guard authorized(request), configuration.allowsUpload else { return .error(.forbidden) }
        guard request.body.byteCount <= configuration.maximumUploadBytes else { return .error(.requestEntityTooLarge) }
        let requestedName = request.query["name"] ?? "upload-\(UUID().uuidString)"
        let name = sanitizedFileName(requestedName)
        guard isAllowedExtension(name) else { return .error(.forbidden) }
        let destination = configuration.rootDirectory.appendingPathComponent(name)
        do {
            switch request.body {
            case .empty: try Data().write(to: destination, options: .atomic)
            case .data(let data): try data.write(to: destination, options: .atomic)
            case .file(let url):
                try FileManager.default.moveItem(at: url, to: destination)
            }
            return .text("uploaded", status: .created)
        } catch {
            return .error(.internalServerError)
        }
    }

    private func deleteResponse(_ request: PTHTTPRequest) -> PTHTTPResponse {
        guard authorized(request), configuration.allowsDelete else { return .error(.forbidden) }
        guard let url = safeURL(for: request.parameters["path"] ?? ""), url.path != configuration.rootDirectory.path else {
            return .error(.forbidden)
        }
        do {
            try FileManager.default.removeItem(at: url)
            return PTHTTPResponse(status: .noContent)
        } catch {
            return .error(.notFound)
        }
    }

    private func createDirectoryResponse(_ request: PTHTTPRequest) -> PTHTTPResponse {
        guard authorized(request), configuration.allowsCreateDirectory else { return .error(.forbidden) }
        guard let relativePath = request.query["path"],
              let url = safeURL(for: relativePath),
              url.path != configuration.rootDirectory.path else { return .error(.badRequest) }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
            return .text("created", status: .created)
        } catch {
            return .error(.internalServerError)
        }
    }

    private func renameResponse(_ request: PTHTTPRequest) -> PTHTTPResponse {
        guard authorized(request), configuration.allowsRename else { return .error(.forbidden) }
        guard let sourcePath = request.parameters["path"],
              let newName = request.query["name"],
              !newName.isEmpty,
              !newName.contains("/"),
              !newName.contains("\\"),
              let sourceURL = safeURL(for: sourcePath),
              sourceURL.path != configuration.rootDirectory.path else { return .error(.badRequest) }
        let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(newName).standardizedFileURL
        guard let safeDestination = safeURL(for: destinationURL.path.replacingOccurrences(of: configuration.rootDirectory.path + "/", with: "")) else {
            return .error(.forbidden)
        }
        do {
            try FileManager.default.moveItem(at: sourceURL, to: safeDestination)
            return PTHTTPResponse(status: .noContent)
        } catch {
            return .error(.internalServerError)
        }
    }

    private func authorized(_ request: PTHTTPRequest) -> Bool {
        guard let sessionToken = configuration.sessionToken else { return true }
        let token = request.headers.firstValue(for: "Authorization")?.replacingOccurrences(of: "Bearer ", with: "")
        return token == sessionToken
    }

    private func safeURL(for relativePath: String) -> URL? {
        let target = configuration.rootDirectory.appendingPathComponent(relativePath).standardizedFileURL
        let root = configuration.rootDirectory.resolvingSymlinksInPath().path
        let resolved = target.resolvingSymlinksInPath()
        guard resolved.path == root || resolved.path.hasPrefix(root + "/") else { return nil }
        return target
    }

    private func sanitizedFileName(_ value: String) -> String {
        let name = URL(fileURLWithPath: value).lastPathComponent
        return name.isEmpty || name == "." ? "upload-\(UUID().uuidString)" : name
    }

    private func isAllowedExtension(_ name: String) -> Bool {
        configuration.allowedFileExtensions.isEmpty || configuration.allowedFileExtensions.contains(URL(fileURLWithPath: name).pathExtension.lowercased())
    }

    private func listFiles(at directory: URL) -> [PTHTTPFilePortalItem] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey], options: [.skipsHiddenFiles])) ?? []
        return urls.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
            return PTHTTPFilePortalItem(name: url.lastPathComponent, path: url.lastPathComponent, isDirectory: values?.isDirectory == true, byteCount: Int64(values?.fileSize ?? 0))
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static let indexHTML = """
    <!doctype html><html><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>PTools File Portal</title>
    <style>body{font:16px -apple-system;margin:24px}button{padding:8px 12px}li{margin:10px 0}</style></head><body>
    <h1>PTools File Portal</h1><input id=file type=file><button onclick=upload()>Upload</button><ul id=list></ul>
    <script>async function refresh(){let r=await fetch('/api/files');let a=await r.json();list.innerHTML=a.map(x=>'<li><a href="/download/'+encodeURIComponent(x.path)+'">'+x.name+'</a> ('+x.byteCount+')</li>').join('')}async function upload(){let f=file.files[0];if(!f)return;await fetch('/api/upload?name='+encodeURIComponent(f.name),{method:'POST',body:f});refresh()}refresh()</script>
    </body></html>
    """
}

public struct PTHTTPFilePortalItem: Codable, Sendable, Equatable {
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let byteCount: Int64

    public init(name: String, path: String, isDirectory: Bool, byteCount: Int64) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.byteCount = byteCount
    }
}
