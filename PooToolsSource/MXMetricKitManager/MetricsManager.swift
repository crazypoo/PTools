//
//  MetricsManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 3/22/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import MetricKit

// 标记为 final，防止被继承，有助于编译器进行优化和并发安全检查
public final class MetricsManager: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    
    public static let shared = MetricsManager()
    // English: MetricKit may call subscribers from a framework queue, so lifecycle state is lock-protected.
    // Español: MetricKit puede llamar al suscriptor desde una cola del framework; el estado queda protegido por lock.
    // 中文：MetricKit 可能从框架队列回调订阅者，因此生命周期状态使用锁保护。
    private let stateLock = NSLock()
    private var registered = false
    private var invalidated = false

    // English: Expose a lock-protected snapshot so callers and diagnostics can verify registration without touching mutable state.
    // Español: Expone una instantánea protegida por lock para que los llamadores y diagnósticos verifiquen el registro sin tocar estado mutable.
    // 中文：提供受锁保护的快照，让调用方和诊断逻辑可以确认订阅状态，而不直接访问可变状态。
    public var isRegistered: Bool {
        stateLock.withLock { registered }
    }
    
    // 私有化 init，保证单例唯一性
    private override init() {
        super.init()
        start()
    }
    
    deinit {
        let shouldRemove = stateLock.withLock {
            registered
        }
        if shouldRemove {
            MXMetricManager.shared.remove(self)
        }
    }

    // Lifecycle methods prevent duplicate MetricKit subscriptions.
    // Estos métodos de ciclo de vida evitan suscripciones duplicadas a MetricKit.
    // 生命周期方法用于避免 MetricKit 重复订阅。
    public func start() {
        let shouldRegister = stateLock.withLock { () -> Bool in
            guard !invalidated, !registered else { return false }
            registered = true
            return true
        }
        guard shouldRegister else { return }
        MXMetricManager.shared.add(self)
    }

    public func stop() {
        let shouldRemove = stateLock.withLock { () -> Bool in
            guard registered else { return false }
            registered = false
            return true
        }
        guard shouldRemove else { return }
        MXMetricManager.shared.remove(self)
    }

    public func invalidate() {
        let shouldRemove = stateLock.withLock { () -> Bool in
            guard !invalidated else { return false }
            invalidated = true
            let wasRegistered = registered
            registered = false
            return wasRegistered
        }
        if shouldRemove {
            MXMetricManager.shared.remove(self)
        }
    }

    private var isInvalidated: Bool {
        stateLock.withLock { invalidated }
    }

    // MARK: - MetricKit 代理方法
    public func didReceive(_ payloads: [MXMetricPayload]) {
        guard !isInvalidated else { return }
        // 1. 同步提纯：在跨越并发边界前，将非 Sendable 的 Payload 提取并转换为天生 Sendable 的 Data
        var safeDataArray: [Data] = []
        
        for payload in payloads {
            let dictionary = payload.dictionaryRepresentation()
            // 这一步是 CPU 内存计算，速度极快，在当前回调线程执行完全没问题
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
                safeDataArray.append(jsonData)
            }
        }
        
        // 2. 异步 IO：只把绝对线程安全的 safeDataArray 传给 Task
        Task {
            for data in safeDataArray {
                // 最耗时的磁盘写入 (IO 操作) 交给后台处理，不会卡主流程
                await saveToDisk(data)
            }
        }
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        guard !isInvalidated else { return }
        // 同理，处理诊断数据
        var safeDataArray: [Data] = []
        
        for payload in payloads {
            let dictionary = payload.dictionaryRepresentation()
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
                safeDataArray.append(jsonData)
            }
        }
        
        Task {
            for data in safeDataArray {
                await saveToDisk(data)
            }
        }
    }
    
    // MARK: - 磁盘与上传管理
    
    // 异步保存到本地
    private func saveToDisk(_ data: Data) async {
        let filename = "metric-\(UUID().uuidString).json"
        guard let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            PTNSLogConsole("📦 已儲存 Metric 到本地：\(filename)")
        } catch {
            PTNSLogConsole("❌ 儲存失敗：\(error)")
        }
    }
    
    /// 用在 applicationDidBecomeActive
    /// 这里的 Task 会自动开启异步任务，不会卡住启动流程
    @MainActor
    public func uploadPendingMetrics() {
        Task {
            let fileManager = FileManager.default
            guard let documentDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

            do {
                let files = try fileManager.contentsOfDirectory(atPath: documentDir.path)
                let metricFiles = files.filter { $0.hasPrefix("metric-") && $0.hasSuffix(".json") }

                for fileName in metricFiles {
                    let fileURL = documentDir.appendingPathComponent(fileName)
                    let data = try Data(contentsOf: fileURL)
                    
                    // 🌟 核心优化：使用 await 等待上传结果，告别闭包嵌套
                    let isSuccess = await uploadToServer(data: data)
                    
                    if isSuccess {
                        try? fileManager.removeItem(at: fileURL)
                        PTNSLogConsole("✅ 上傳後刪除：\(fileName)")
                    } else {
                        PTNSLogConsole("⏳ 稍後重試：\(fileName)")
                    }
                }
            } catch {
                PTNSLogConsole("❌ 上傳待處理檔案失敗：\(error)")
            }
        }
    }
    
    /// 原生 Async/Await 的网络请求方法，取代 completion handler
    private func uploadToServer(data: Data) async -> Bool {
        guard let uploadURL = await URL(string: PTAppBaseConfig.share.MXMetricKitUploadAddress) else {
            return false
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        do {
            // Swift 6 现代网络请求方式
            let (_, response) = try await URLSession.shared.data(for: request)
            
            // 校验 HTTP 状态码是否在 200~299 之间
            if let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) {
                PTNSLogConsole("✅ 上傳成功")
                return true
            } else {
                PTNSLogConsole("⚠️ 伺服器錯誤")
                return false
            }
        } catch {
            PTNSLogConsole("❌ 上傳失敗: \(error)")
            return false
        }
    }
}
