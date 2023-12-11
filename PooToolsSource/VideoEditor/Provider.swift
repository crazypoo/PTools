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
            let random = Int(arc4random_uniform(89999) + 10000)
            let outputURL = documents.appendingPathComponent("condy_export_video_\(random).mp4")
            // Check if the file already exists then remove the previous file
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try? FileManager.default.removeItem(at: outputURL)
            }
            self.outputURL = outputURL
            self.fileType = .mp4
        }
    }
}
