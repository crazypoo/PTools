// English: URLSession delegate adapter that owns pause, resume-data capture, progress, and completion exactly once.
// Español: Adaptador delegado de URLSession que posee pausa, captura de resume data, progreso y finalización una sola vez.
// 中文：URLSession delegate 适配器负责暂停、resume data 捕获、进度以及一次性完成。

import Foundation
#if SWIFT_PACKAGE
import PToolsTransferCore
#endif

// English: URLSession invokes this adapter from delegate queues; the lock protects continuation and task state.
// Español: URLSession invoca este adaptador desde colas de delegado; el lock protege el estado de la tarea y la continuation.
// 中文：URLSession 会从 delegate 队列调用此适配器，锁用于保护 continuation 和 task 状态。
final class PTTransferDownloadController: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private let request: PTTransferRequest
    private let session: URLSession
    private var continuation: CheckedContinuation<URL, Error>?
    private var completedResult: Result<URL, Error>?
    private var pauseContinuation: CheckedContinuation<Data?, Never>?
    private var resumeData: Data?
    private var task: URLSessionDownloadTask?
    private var isPausing = false
    private var pauseRequested = false
    private var resumedFromData = false
    private var didFallbackFromResumeData = false
    private let progressHandler: @Sendable (Int64, Int64, Int64) -> Void

    init(request: PTTransferRequest,
         resumeData: Data? = nil,
         session: URLSession,
         progressHandler: @escaping @Sendable (Int64, Int64, Int64) -> Void) {
        self.request = request
        self.resumeData = resumeData
        self.session = session
        self.progressHandler = progressHandler
        super.init()
    }

    func start() {
        let state = withStateLock { () -> URLSessionDownloadTask? in
            let data = resumeData
            resumeData = nil
            resumedFromData = data != nil
            pauseRequested = false
            if let data {
                let nextTask = session.downloadTask(withResumeData: data)
                task = nextTask
                return nextTask
            }
            guard case .download(let url) = request.source else { return nil }
            let nextTask = session.downloadTask(with: URLRequest(url: url))
            task = nextTask
            return nextTask
        }
        guard let nextTask = state else {
            finish(.failure(PTTransferError.invalidRequest))
            return
        }
        nextTask.resume()
    }

    func value() async throws -> URL {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let existingResult = withStateLock { () -> Result<URL, Error>? in
                    if completedResult != nil { return completedResult }
                    self.continuation = continuation
                    return nil
                }
                if let existingResult {
                    continuation.resume(with: existingResult)
                }
            }
        } onCancel: {
            cancel()
        }
    }

    func pause() async -> Data? {
        let currentTask = withStateLock { () -> URLSessionDownloadTask? in
            guard let task, !isPausing else { return nil }
            isPausing = true
            pauseRequested = true
            return task
        }
        guard let task = currentTask else { return withStateLock { resumeData } }
        return await withCheckedContinuation { continuation in
            withStateLock { pauseContinuation = continuation }
            task.cancel { [weak self] data in
                let pending = self?.withStateLock { () -> CheckedContinuation<Data?, Never>? in
                    self?.resumeData = data
                    self?.isPausing = false
                    let pending = self?.pauseContinuation
                    self?.pauseContinuation = nil
                    return pending
                }
                pending?.resume(returning: data)
            }
        }
    }

    func resume() {
        let canResume = withStateLock { () -> Bool in
            guard task == nil || completedResult != nil else { return false }
            completedResult = nil
            continuation = nil
            pauseRequested = false
            didFallbackFromResumeData = false
            return true
        }
        guard canResume else { return }
        start()
    }

    func cancel() {
        let task = withStateLock { () -> URLSessionDownloadTask? in
            isPausing = false
            return self.task
        }
        task?.cancel()
    }

    func currentResumeData() -> Data? {
        withStateLock { resumeData }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        progressHandler(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let destination = request.destination
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("ptools-\(request.id.rawValue.uuidString)")
        do {
            let parent = destination.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            finish(.success(destination))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error {
            if shouldFallbackFromResumeData(error) {
                withStateLock {
                    resumeData = nil
                    resumedFromData = false
                    didFallbackFromResumeData = true
                }
                start()
                return
            }
            let wasPaused = withStateLock { pauseRequested }
            finish(.failure(wasPaused ? CancellationError() : error))
        } else {
            finish(.failure(PTTransferError.destinationUnavailable))
        }
    }

    private func shouldFallbackFromResumeData(_ error: Error) -> Bool {
        let shouldTry = withStateLock { resumedFromData && !didFallbackFromResumeData }
        guard shouldTry else { return false }
        let code = (error as NSError).code
        return code == -3003 || code == NSURLErrorFileDoesNotExist
    }

    private func finish(_ result: Result<URL, Error>) {
        let values = withStateLock { () -> (CheckedContinuation<URL, Error>?, CheckedContinuation<Data?, Never>?, Data?)? in
            guard completedResult == nil else { return nil }
            completedResult = result
            let continuation = self.continuation
            self.continuation = nil
            let pauseContinuation = self.pauseContinuation
            self.pauseContinuation = nil
            self.task = nil
            return (continuation, pauseContinuation, self.resumeData)
        }
        guard let values else { return }
        let continuation = values.0
        let pauseContinuation = values.1
        let pendingResumeData = values.2
        pauseContinuation?.resume(returning: pendingResumeData)
        continuation?.resume(with: result)
    }

    private func withStateLock<Value>(_ body: () -> Value) -> Value {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
