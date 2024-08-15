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
    var urlParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }   
    
    func getFileSizeOnline(completion: @escaping (UInt64) -> Void) {
        var request = URLRequest(url: self)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 15  // 设置请求超时
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // 错误处理
            if let error = error {
                PTNSLogConsole("Error: \(error.localizedDescription)", levelType: .Error, loggerType: .URL)
                completion(0)
                return
            }

            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                PTNSLogConsole("Failed: Invalid response or status code.", levelType: .Error, loggerType: .URL)
                completion(0)
                return
            }

            // 安全解包 Content-Length
            if let contentLengthString = response.allHeaderFields["Content-Length"] as? String,
               let contentLength = UInt64(contentLengthString) {
                completion(contentLength)
            } else {
                PTNSLogConsole("Failed to retrieve file size.", levelType: .Error, loggerType: .URL)
                completion(0)
            }
        }

        task.resume()
    }
    
    func audioLinkGetDurationTime() ->Float {
        let audionAsset = AVURLAsset(url: self)
        return Float(CMTimeGetSeconds(audionAsset.duration))
    }
}
