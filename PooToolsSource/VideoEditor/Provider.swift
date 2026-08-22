//
//  Provider.swift
//  KakaposExamples
//
//  Created by Condy on 2023/7/31.
//

import Foundation
import AVFoundation

extension Exporter {
    
    /// Setup input source and output link URL.
    public struct Provider {
        let asset: AVAsset
        let outputURL: URL
        let fileType: MovieFileType
    }
}

extension Exporter.Provider {
    
    public init(with videoURL: URL, to outputURL: URL? = nil) {
        let urlAsset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        self.init(with: urlAsset, to: outputURL)
    }
    
    public init(with asset: AVAsset, to outputURL: URL? = nil) {
        self.asset = asset
        if let outputURL = outputURL {
            self.outputURL = outputURL
            self.fileType = MovieFileType.from(url: outputURL) ?? .mp4
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let outputURL = documents.appendingPathComponent("PTVideoEditor_\(UUID().uuidString).mp4")
            // 默认输出路径使用唯一文件名，避免并发导出互相覆盖。
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try? FileManager.default.removeItem(at: outputURL)
            }
            self.outputURL = outputURL
            self.fileType = .mp4
        }
    }
}
