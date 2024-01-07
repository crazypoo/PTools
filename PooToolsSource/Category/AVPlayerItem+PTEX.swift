//
//  AVPlayerItem+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/1/7.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import AVFoundation

extension AVPlayerItem {
    func generateThumbnail(startTime:Double = 0,completion: @escaping (UIImage?) -> Void) {
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: startTime, preferredTimescale: 1) // 时间为视频开始的时间，这里设置为0秒
        assetImageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { (_, image, _, _, _) in
            if let cgImage = image {
                let thumbnail = UIImage(cgImage: cgImage)
                completion(thumbnail)
            } else {
                completion(nil)
            }
        }
    }
}
