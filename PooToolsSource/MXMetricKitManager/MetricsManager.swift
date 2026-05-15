//
//  MetricsManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 3/22/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import MetricKit

public class MetricsManager: NSObject, MXMetricManagerSubscriber {
    public static let shared = MetricsManager()
    
    override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }
    
    deinit {
        MXMetricManager.shared.remove(self)
    }

    public func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // 处理收集到的数据
            let dictionary = payload.dictionaryRepresentation()
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
                saveToDisk(jsonData) // 如果即時上傳失敗，還可以 retry
            }
        }
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            // 收到诊断信息，如崩溃、内存问题等
            let dictionary = payload.dictionaryRepresentation()
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
                saveToDisk(jsonData) // 如果即時上傳失敗，還可以 retry
            }
        }
    }
    
    func saveToDisk(_ data: Data) {
        let filename = "metric-\(UUID().uuidString).json"
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            PTNSLogConsole("📦 已儲存 Metric 到本地：\(filename)")
        } catch {
            PTNSLogConsole("❌ 儲存失敗：\(error)")
        }
    }
    
    //MARK: 用在applicationDidBecomeActive
    @MainActor public func uploadPendingMetrics() {
        let fileManager = FileManager.default
        let documentDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let files = try fileManager.contentsOfDirectory(atPath: documentDir.path)
            let metricFiles = files.filter { $0.hasPrefix("metric-") && $0.hasSuffix(".json") }

            for fileName in metricFiles {
                let fileURL = documentDir.appendingPathComponent(fileName)
                let data = try Data(contentsOf: fileURL)
                
                uploadToServer(data: data) { success in
                    if success {
                        try? fileManager.removeItem(at: fileURL)
                        PTNSLogConsole("✅ 上傳後刪除：\(fileName)")
                    } else {
                        PTNSLogConsole("⏳ 稍後重試：\(fileName)")
                    }
                }
            }
        } catch {
            PTNSLogConsole("❌ 上傳待處理檔案失敗：\(error)")
        }
    }
    
    @MainActor func uploadToServer(data: Data, completion: PTBoolTask? = nil) {
        if let uploadURL = URL(string: PTAppBaseConfig.share.MXMetricKitUploadAddress) {
            var request = URLRequest(url: uploadURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    PTNSLogConsole("❌ 上傳失敗: \(error)")
                    completion?(false)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                    PTNSLogConsole("⚠️ 伺服器錯誤")
                    completion?(false)
                    return
                }

                PTNSLogConsole("✅ 上傳成功")
                completion?(true)
            }
            task.resume()
        } else {
            completion?(false)
        }
    }
}
