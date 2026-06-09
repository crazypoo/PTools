//
//  URL+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation

public extension URL {
    var urlQueryParameters: [String: String]? {
        var params: [String: String] = [:]
        
        if let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           !queryItems.isEmpty {
            for item in queryItems {
                if let value = item.value {
                    params[item.name] = value
                }
            }
        } else {
            // 手动解析 scheme 里可能没有 "?" 的情况，如 scheme://key=value&key2=value2
            let raw = self.absoluteString
            if let range = raw.range(of: "://") {
                let queryPart = String(raw[range.upperBound...])
                let keyValuePairs = queryPart.components(separatedBy: "&")
                for pair in keyValuePairs {
                    let kv = pair.components(separatedBy: "=")
                    if kv.count == 2 {
                        params[kv[0]] = kv[1]
                    }
                }
            }
        }
        
        return params.isEmpty ? nil : params
    }
    
    var urlParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }   
    
    func getFileSizeOnline(completion: @escaping @Sendable (UInt64) -> Void) {
        var request = URLRequest(url: self)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 15  // 设置请求超时
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // 错误处理
            if let error = error {
                PTNSLogConsole("Error: \(error.localizedDescription)", levelType: .error, loggerType: .url)
                completion(0)
                return
            }

            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                PTNSLogConsole("Failed: Invalid response or status code.", levelType: .error, loggerType: .url)
                completion(0)
                return
            }

            // 安全解包 Content-Length
            if let contentLengthString = response.allHeaderFields["Content-Length"] as? String,
               let contentLength = UInt64(contentLengthString) {
                completion(contentLength)
            } else {
                PTNSLogConsole("Failed to retrieve file size.", levelType: .error, loggerType: .url)
                completion(0)
            }
        }

        task.resume()
    }
    
    func audioLinkGetDurationTime() async -> Float {
        let audioAsset = AVURLAsset(url: self)
        
        do {
            // 🌟 核心适配改动：异步安全地加载时长
            let duration = try await audioAsset.load(.duration)
            return Float(CMTimeGetSeconds(duration))
        } catch {
            // 捕获可能出现的文件损坏或解析错误
            PTNSLogConsole("获取链接时长失败: \(error.localizedDescription)")
            return 0.0 // 失败时提供一个默认值（也可以根据业务需求改为返回可选型 Float?）
        }
    }
    
    //MARK: URL获取数据字符串
    func queryToJSON() -> String? {
        guard let fragment = self.fragment, // 取 # 后面的部分
              let fragmentComponents = URLComponents(string: fragment),
              let queryItems = fragmentComponents.queryItems else {
            return nil
        }

        let dict = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
}
