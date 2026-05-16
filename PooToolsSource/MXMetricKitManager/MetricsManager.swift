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
    
    // 私有化 init，保证单例唯一性
    private override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }
    
    deinit {
        MXMetricManager.shared.remove(self)
    }

    // MARK: - MetricKit 代理方法
    
    public func didReceive(_ payloads: [MXMetricPayload]) async {
        // 使用 Task 将处理逻辑放入后台，不阻塞 MetricKit 的系统回调
        for payload in payloads {
            let dictionary = payload.dictionaryRepresentation()
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
                await saveToDisk(jsonData)
            }
        }
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) async {
        for payload in payloads {
            let dictionary = payload.dictionaryRepresentation()
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
                await saveToDisk(jsonData)
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
