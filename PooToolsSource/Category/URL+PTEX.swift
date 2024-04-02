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

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse, error == nil else {
                PTNSLogConsole("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion(0)
                return
            }
            
            if let contentLength = response.allHeaderFields["Content-Length"] as? String,
               let fileSize = UInt64(contentLength) {
                completion(fileSize)
            } else {
                PTNSLogConsole("Failed to retrieve file size.")
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
