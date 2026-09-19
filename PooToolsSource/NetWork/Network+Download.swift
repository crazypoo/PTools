//
//  Network+Download.swift
//  PooTools
//
// English: Keep download lifecycle code separate from request construction and response parsing.
// Español: Mantiene el ciclo de vida de descargas separado de la construcción y el análisis de respuestas.
// 中文：将下载生命周期代码从请求构造和响应解析中独立出来。
//

import UIKit
import Foundation
@preconcurrency import Alamofire

extension Network {
    // MARK: - ================= 8. 下载引擎与流式控制 =================
    
    // English: Build the download session once from the same initialization snapshot.
    // Español: Construye una sola sesión de descarga usando la misma instantánea inicial.
    // 中文：使用同一份初始化快照只创建一次下载 Session。
    private static func makeDownloadSession(configuration configurationSnapshot: PTNetworkSessionConfiguration,
                                            protocolClasses: [AnyClass]) -> Session {
        let urlConfiguration = URLSessionConfiguration.default
        urlConfiguration.timeoutIntervalForRequest = configurationSnapshot.downloadRequestTimeout
        urlConfiguration.timeoutIntervalForResource = configurationSnapshot.resourceTimeout
        urlConfiguration.httpMaximumConnectionsPerHost = 6
        if !protocolClasses.isEmpty {
            var protocols = urlConfiguration.protocolClasses ?? []
            protocols.insert(contentsOf: protocolClasses, at: 0)
            urlConfiguration.protocolClasses = protocols
        }
        return Session(configuration: urlConfiguration)
    }

    private var downloadSession: Session {
        downloadSessionLock.lock()
        defer { downloadSessionLock.unlock() }
        if let storedDownloadSession { return storedDownloadSession }
        let newSession = Self.makeDownloadSession(configuration: sessionConfiguration,
                                                  protocolClasses: protocolClasses)
        storedDownloadSession = newSession
        return newSession
    }
    
    actor DownloadStore {
        var tasks: [String: DownloadTask] = [:]
        public func get(_ url: String) -> DownloadTask? { tasks[url] }
        func set(_ url: String, task: DownloadTask) { tasks[url] = task }
        func remove(_ url: String) { tasks[url] = nil }
    }
    
    // 🌟 核心升级：直接声明为 actor，彻底告别 @unchecked 和 NSLock，编译器自动保证线程绝对安全！
    final actor DownloadTask {
        let url: String
        let destination: @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options)
        let store: DownloadStore
        var request: DownloadRequest?
        var resumeData: Data?
        
        private var progressHandlers: [FileDownloadProgress] = []
        private var successHandlers: [FileDownloadSuccess] = []
        private var failHandlers: [FileDownloadFail] = []
        private var lastProgressTime: CFTimeInterval = 0
        private(set) var isDownloading: Bool = false
        
        init(url: String,
             destination: @escaping @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options),
             store: DownloadStore) {
            self.url = url
            self.destination = destination
            self.store = store
        }
        
        func appendHandlers(progress: FileDownloadProgress?, success: FileDownloadSuccess?, fail: FileDownloadFail?) {
            if let p = progress { progressHandlers.append(p) }
            if let s = success { successHandlers.append(s) }
            if let f = fail { failHandlers.append(f) }
        }
        
        private func clearHandlers() {
            progressHandlers.removeAll()
            successHandlers.removeAll()
            failHandlers.removeAll()
        }
        
        func start(session: Session) {
            if isDownloading { return }
            isDownloading = true
            
            if let data = resumeData { request = session.download(resumingWith: data, to: destination) }
            else { request = session.download(url, to: destination) }
            
            // English: Capture Sendable progress values before entering the actor.
            // Español: Captura valores de progreso Sendable antes de entrar en el actor.
            // 中文：在进入 actor 前先捕获 Sendable 进度值。
            request?.downloadProgress(queue: .global()) { [weak self] p in
                guard let self = self else { return }
                let snapshot = PTProgressSnapshot(completedUnitCount: p.completedUnitCount,
                                                   totalUnitCount: p.totalUnitCount,
                                                   fractionCompleted: p.fractionCompleted)
                Task { await self.handleProgress(snapshot) }
            }
            
            request?.response { [weak self] resp in
                guard let self = self else { return }
                Task { await self.handleResponse(resp) }
            }
        }
        
        // English: Process an immutable progress snapshot inside the actor.
        // Español: Procesa una instantánea de progreso inmutable dentro del actor.
        // 中文：在 actor 内处理不可变的进度快照。
        private func handleProgress(_ snapshot: PTProgressSnapshot) {
            let now = CACurrentMediaTime()
            let isFinished = snapshot.totalUnitCount > 0
                && snapshot.completedUnitCount >= snapshot.totalUnitCount
            if now - lastProgressTime > 0.1 || isFinished {
                lastProgressTime = now
                let handlers = progressHandlers
                // English: Rebuild only the legacy scalar callback values on MainActor.
                // Español: Reconstruye solo los valores escalares del callback heredado en MainActor.
                // 中文：只在 MainActor 上重建旧回调需要的标量值。
                for cb in handlers {
                    Task { @MainActor in
                        cb(snapshot.completedUnitCount,
                           snapshot.totalUnitCount,
                           snapshot.fractionCompleted)
                    }
                }
            }
        }
        
        // 🌟 专门处理结束回调的内部方法，运行在 actor 隔离区内
        private func handleResponse(_ resp: AFDownloadResponse<URL?>) async {
            isDownloading = false
            resumeData = nil
            
            let currentFails = failHandlers
            let currentSuccesses = successHandlers
            clearHandlers() // 清空回调防止内存泄漏
            
            if let error = resp.error {
                if error.isExplicitlyCancelledError || (error.underlyingError as? URLError)?.code == .cancelled {
                    resumeData = resp.resumeData
                } else {
                    await store.remove(self.url)
                }
                for cb in currentFails { Task { @MainActor in cb(error) } }
            } else {
                await store.remove(self.url)
                for cb in currentSuccesses { Task { @MainActor in cb(resp) } }
            }
        }
        
        func suspend() {
            isDownloading = false
            request?.cancel { [weak self] data in
                Task { await self?.saveResumeData(data) }
            }
        }
        
        private func saveResumeData(_ data: Data?) {
            self.resumeData = data
            self.request = nil
        }
        
        func cancel() {
            isDownloading = false
            request?.cancel()
        }
    }
    
    @MainActor public func download(fileUrl: String, saveFilePath: String, queue: DispatchQueue? = .main, progress: FileDownloadProgress? = nil, success: FileDownloadSuccess? = nil, fail: FileDownloadFail? = nil) {
        guard fileUrl.isURL(), !fileUrl.stringIsEmpty() else { fail?(AFError.invalidURL(url: "PT URL Error")); return }
        let dest: @Sendable (URL, HTTPURLResponse) -> (URL, DownloadRequest.Options) = { _, _ in
            return (URL(fileURLWithPath: saveFilePath), [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Task {
            let task: DownloadTask
            if let existing = await store.get(fileUrl) {
                task = existing
                await task.appendHandlers(progress: progress, success: success, fail: fail)
            } else {
                task = DownloadTask(url: fileUrl, destination: dest, store: store)
                await task.appendHandlers(progress: progress, success: success, fail: fail)
                await store.set(fileUrl, task: task)
            }
            
            let isDownloading = await task.isDownloading
            if !isDownloading { await task.start(session: downloadSession) }
        }
    }
    
    @MainActor public func download(fileUrl: String, saveFilePath: String, progress: FileDownloadProgress? = nil) async throws -> URL {
        let cancellationBridge = PTDownloadCancellationBridge()
        // English: Keep cancellation outside the MainActor so the compiler and runtime use one clear boundary.
        // Español: Mantiene la cancelación fuera de MainActor para que el compilador y el tiempo de ejecución usen un límite claro.
        // 中文：让取消逻辑保持在 MainActor 之外，使编译器和运行时都只有一个清晰边界。
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                cancellationBridge.install(resumeCancellation: {
                    continuation.resume(throwing: CancellationError())
                })
                self.download(fileUrl: fileUrl, saveFilePath: saveFilePath, queue: nil, progress: progress, success: { response in
                    guard cancellationBridge.finish() else { return }
                    if let fileURL = response.fileURL { continuation.resume(returning: fileURL) }
                    else { continuation.resume(throwing: PTNetworkError.downloadFail) }
                }, fail: { error in
                    guard cancellationBridge.finish() else { return }
                    continuation.resume(throwing: error ?? PTNetworkError.downloadFail)
                })
                cancellationBridge.install(cancelUnderlying: { [weak self] in
                    self?.cancel(fileUrl: fileUrl)
                })
            }
        }, onCancel: {
            cancellationBridge.cancel()
        })
    }
    
    public func suspend(fileUrl: String) { Task { await store.get(fileUrl)?.suspend() } }
    public func resume(fileUrl: String)  { Task { await store.get(fileUrl)?.start(session: downloadSession) } }
    public func cancel(fileUrl: String)  { Task { if let task = await store.get(fileUrl) { await store.remove(fileUrl); await task.cancel() } } }
    
    /// 🌟 全新现代化的流式下载方法，支持在业务层循环获取进度
    public func downloadAsyncStream(fileUrl: String, saveFilePath: String) -> AsyncThrowingStream<(progress: Double, fileURL: URL?), Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                self.download(fileUrl: fileUrl, saveFilePath: saveFilePath, queue: nil) { _, _, progress in
                    continuation.yield((progress, nil))
                } success: { response in
                    if let fileURL = response.fileURL {
                        continuation.yield((1.0, fileURL))
                        continuation.finish()
                    } else { continuation.finish(throwing: PTNetworkError.downloadFail) }
                } fail: { error in continuation.finish(throwing: error ?? PTNetworkError.downloadFail) }
            }
            continuation.onTermination = { @Sendable _ in
                self.cancel(fileUrl: fileUrl)
            }
        }
    }
}
