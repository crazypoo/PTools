//
//  Network+Download.swift
//  PooTools
//
// English: Keep the legacy download facade while routing file execution through the shared transfer core.
// Español: Mantiene la fachada heredada de descargas y dirige la ejecución al núcleo de transferencias compartido.
// 中文：保留旧下载门面，同时将文件执行统一到共享传输核心。
//

import Foundation
import UIKit
#if SWIFT_PACKAGE
import ptools
import PToolsCore
import PToolsTransferCore
#endif
@preconcurrency import Alamofire

private actor PTNetworkDownloadRegistry {
    struct Plan: Sendable {
        let sourceURL: URL
        let destinationURL: URL
        let headers: [String: String]
        let allowsResume: Bool
        let retryPolicy: PTTransferRetryPolicy
        let policy: PTTransferPolicy
        let configuration: PTTransferDownloadConfiguration
        let progress: FileDownloadProgress?
        let success: FileDownloadSuccess?
        let fail: FileDownloadFail?
    }

    private struct Entry {
        let plan: Plan
        var task: Task<Void, Never>?
        var isSuspended: Bool
    }

    private var entries: [UUID: Entry] = [:]
    private var idsByURL: [String: Set<UUID>] = [:]

    func insert(_ plan: Plan) -> UUID {
        let id = UUID()
        entries[id] = Entry(plan: plan, task: nil, isSuspended: false)
        idsByURL[plan.sourceURL.absoluteString, default: []].insert(id)
        return id
    }

    func attach(_ task: Task<Void, Never>, to id: UUID) {
        guard var entry = entries[id] else {
            task.cancel()
            return
        }
        if entry.isSuspended {
            task.cancel()
        } else {
            entry.task = task
            entries[id] = entry
        }
    }

    func suspend(sourceURL: String) -> [Task<Void, Never>] {
        let ids = idsByURL[sourceURL] ?? []
        var tasks: [Task<Void, Never>] = []
        for id in ids {
            guard var entry = entries[id] else { continue }
            entry.isSuspended = true
            if let task = entry.task {
                tasks.append(task)
                entry.task = nil
            }
            entries[id] = entry
        }
        return tasks
    }

    func plansToResume(sourceURL: String) -> [Plan] {
        let ids = idsByURL[sourceURL] ?? []
        var plans: [Plan] = []
        for id in ids {
            guard let entry = entries[id], entry.isSuspended else { continue }
            plans.append(entry.plan)
            remove(id)
        }
        return plans
    }

    func tasksToCancel(sourceURL: String) -> [Task<Void, Never>] {
        let ids = idsByURL[sourceURL] ?? []
        var tasks: [Task<Void, Never>] = []
        for id in ids {
            if let task = entries[id]?.task { tasks.append(task) }
            remove(id)
        }
        return tasks
    }

    func finished(_ id: UUID) -> Plan? {
        guard let entry = entries[id], !entry.isSuspended else { return nil }
        remove(id)
        return entry.plan
    }

    private func remove(_ id: UUID) {
        guard let entry = entries.removeValue(forKey: id) else { return }
        let key = entry.plan.sourceURL.absoluteString
        idsByURL[key]?.remove(id)
        if idsByURL[key]?.isEmpty == true { idsByURL[key] = nil }
    }
}

extension Network {
    // English: One legacy callback call owns one transfer-core subscription, so cancelling one caller does not cancel its peers.
    // Español: Cada llamada heredada posee una suscripción propia al núcleo; cancelar una no cancela a sus compañeras.
    // 中文：每次旧回调调用都拥有独立的核心订阅，取消一个调用不会取消其他订阅者。
    private static let downloadRegistry = PTNetworkDownloadRegistry()

    @MainActor
    public func download(fileUrl: String,
                         saveFilePath: String,
                         queue: DispatchQueue? = .main,
                         progress: FileDownloadProgress? = nil,
                         success: FileDownloadSuccess? = nil,
                         fail: FileDownloadFail? = nil) {
        guard fileUrl.isURL(), !fileUrl.stringIsEmpty(),
              let sourceURL = URL(string: fileUrl) else {
            fail?(AFError.invalidURL(url: "PT URL Error"))
            return
        }

        let configuration = sessionConfiguration
        let retryPolicy = PTRetryPolicy(maxAttempts: configuration.retryTimes,
                                        baseDelay: configuration.retryDelay,
                                        retryableStatusCodes: [408, 425, 429, 500, 502, 503, 504, configuration.retryAPIStatusCode])
        let transferRetryPolicy = PTTransferRetryPolicy(maxAttempts: retryPolicy.maxAttempts,
                                                        baseDelay: .milliseconds(Int(max(0, retryPolicy.baseDelay) * 1_000)),
                                                        maxDelay: .milliseconds(Int(max(retryPolicy.baseDelay, retryPolicy.maxDelay) * 1_000)))
        let transferPolicy = PTTransferPolicy(waitsForConnectivity: configuration.waitsForConnectivity)
        let downloadConfiguration = PTTransferDownloadConfiguration(requestTimeout: configuration.downloadRequestTimeout,
                                                                     resourceTimeout: configuration.resourceTimeout)
        let destinationURL = URL(fileURLWithPath: saveFilePath)
        let plan = PTNetworkDownloadRegistry.Plan(
            sourceURL: sourceURL,
            destinationURL: destinationURL,
            headers: [:],
            allowsResume: true,
            retryPolicy: transferRetryPolicy,
            policy: transferPolicy,
            configuration: downloadConfiguration,
            progress: Self.makeLegacyProgressCallback(progress, queue: queue),
            success: Self.makeLegacySuccessCallback(success, queue: queue),
            fail: Self.makeLegacyFailureCallback(fail, queue: queue)
        )
        Self.startDownload(plan)
    }

    @MainActor
    public func download(fileUrl: String,
                         saveFilePath: String,
                         progress: FileDownloadProgress? = nil) async throws -> URL {
        guard fileUrl.isURL(), !fileUrl.stringIsEmpty(),
              let sourceURL = URL(string: fileUrl) else {
            throw AFError.invalidURL(url: "PT URL Error")
        }

        let configuration = sessionConfiguration
        let retryPolicy = PTRetryPolicy(maxAttempts: configuration.retryTimes,
                                        baseDelay: configuration.retryDelay,
                                        retryableStatusCodes: [408, 425, 429, 500, 502, 503, 504, configuration.retryAPIStatusCode])
        let transferRetryPolicy = PTTransferRetryPolicy(maxAttempts: retryPolicy.maxAttempts,
                                                        baseDelay: .milliseconds(Int(max(0, retryPolicy.baseDelay) * 1_000)),
                                                        maxDelay: .milliseconds(Int(max(retryPolicy.baseDelay, retryPolicy.maxDelay) * 1_000)))
        let transferPolicy = PTTransferPolicy(waitsForConnectivity: configuration.waitsForConnectivity)
        let downloadConfiguration = PTTransferDownloadConfiguration(requestTimeout: configuration.downloadRequestTimeout,
                                                                     resourceTimeout: configuration.resourceTimeout)
        let progressHandler = Self.makeTransferProgressHandler(progress)
        let resultURL = try await PTTransferFileDownloadService.shared.download(
            from: sourceURL,
            to: URL(fileURLWithPath: saveFilePath),
            allowsResume: true,
            retryPolicy: transferRetryPolicy,
            policy: transferPolicy,
            configuration: downloadConfiguration,
            progress: progressHandler
        )
        return resultURL
    }

    public func suspend(fileUrl: String) {
        Task {
            let tasks = await Self.downloadRegistry.suspend(sourceURL: fileUrl)
            tasks.forEach { $0.cancel() }
        }
    }

    public func resume(fileUrl: String) {
        Task {
            let plans = await Self.downloadRegistry.plansToResume(sourceURL: fileUrl)
            plans.forEach(Self.startDownload)
        }
    }

    public func cancel(fileUrl: String) {
        Task {
            let tasks = await Self.downloadRegistry.tasksToCancel(sourceURL: fileUrl)
            tasks.forEach { $0.cancel() }
        }
    }

    public func downloadAsyncStream(fileUrl: String,
                                    saveFilePath: String) -> AsyncThrowingStream<(progress: Double, fileURL: URL?), Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    let fileURL = try await self.download(fileUrl: fileUrl,
                                                           saveFilePath: saveFilePath) { completed, total, fraction in
                        continuation.yield((fraction, nil))
                        _ = completed
                        _ = total
                    }
                    continuation.yield((1, fileURL))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    private static func startDownload(_ plan: PTNetworkDownloadRegistry.Plan) {
        Task {
            let id = await downloadRegistry.insert(plan)
            let task: Task<Void, Never> = Task {
                await Self.performDownload(plan: plan, id: id)
            }
            await downloadRegistry.attach(task, to: id)
        }
    }

    private static func performDownload(plan: PTNetworkDownloadRegistry.Plan,
                                        id: UUID) async {
        do {
            let result = try await PTTransferFileDownloadService.shared.downloadResult(
                from: plan.sourceURL,
                to: plan.destinationURL,
                headers: plan.headers,
                allowsResume: plan.allowsResume,
                retryPolicy: plan.retryPolicy,
                policy: plan.policy,
                configuration: plan.configuration,
                progress: makeProgressHandler(plan.progress)
            )
            guard let finishedPlan = await downloadRegistry.finished(id) else { return }
            let response = makeDownloadResponse(sourceURL: finishedPlan.sourceURL,
                                                headers: finishedPlan.headers,
                                                result: result)
            await MainActor.run { finishedPlan.success?(response) }
        } catch {
            guard let finishedPlan = await downloadRegistry.finished(id) else { return }
            let legacyError: Error = (error is CancellationError)
                ? AFError.explicitlyCancelled
                : (error as? AFError ?? AFError.sessionTaskFailed(error: error))
            await MainActor.run { finishedPlan.fail?(legacyError) }
        }
    }

    private static func makeProgressHandler(_ progress: FileDownloadProgress?) -> PTTransferProgressHandler? {
        guard let progress else { return nil }
        return { snapshot in
            await MainActor.run {
                progress(snapshot.completed, snapshot.total ?? 0, snapshot.fraction)
            }
        }
    }

    // English: Build legacy callbacks separately so Swift 6 can type-check each actor boundary independently.
    // Español: Construye los callbacks heredados por separado para que Swift 6 compruebe cada límite de actor de forma independiente.
    // 中文：将旧回调分开构造，让 Swift 6 能分别检查每个 actor 边界。
    @MainActor
    private static func makeLegacyProgressCallback(_ progress: FileDownloadProgress?,
                                                   queue: DispatchQueue?) -> FileDownloadProgress? {
        guard let progress else { return nil }
        return { completed, total, fraction in
            if let queue {
                queue.async {
                    Task { @MainActor in progress(completed, total, fraction) }
                }
            } else {
                progress(completed, total, fraction)
            }
        }
    }

    @MainActor
    private static func makeLegacySuccessCallback(_ success: FileDownloadSuccess?,
                                                  queue: DispatchQueue?) -> FileDownloadSuccess? {
        guard let success else { return nil }
        return { response in
            if let queue {
                queue.async {
                    Task { @MainActor in success(response) }
                }
            } else {
                success(response)
            }
        }
    }

    @MainActor
    private static func makeLegacyFailureCallback(_ fail: FileDownloadFail?,
                                                  queue: DispatchQueue?) -> FileDownloadFail? {
        guard let fail else { return nil }
        return { error in
            if let queue {
                queue.async {
                    Task { @MainActor in fail(error) }
                }
            } else {
                fail(error)
            }
        }
    }

    private static func makeTransferProgressHandler(_ progress: FileDownloadProgress?) -> PTTransferProgressHandler? {
        guard let progress else { return nil }
        return { snapshot in
            await MainActor.run {
                progress(snapshot.completed, snapshot.total ?? 0, snapshot.fraction)
            }
        }
    }

    private static func makeDownloadResponse(sourceURL: URL,
                                             headers: [String: String],
                                             result: PTTransferDownloadResult) -> AFDownloadResponse<URL?> {
        var request = URLRequest(url: sourceURL)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let response = result.statusCode.flatMap {
            HTTPURLResponse(url: sourceURL,
                            statusCode: $0,
                            httpVersion: "HTTP/1.1",
                            headerFields: result.headers)
        }
        return AFDownloadResponse(request: request,
                                  response: response,
                                  fileURL: result.fileURL,
                                  resumeData: nil,
                                  metrics: nil,
                                  serializationDuration: 0,
                                  result: .success(result.fileURL))
    }
}
