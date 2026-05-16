//
//  PTVideoEditorVideoTimeLineGenerator.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation
import Combine
import UIKit

protocol PTVideoEditorVideoTimeLineGeneratorProtocol {
    func videoTimeline(for asset: AVAsset, 
                       in bounds: CGRect,
                       numberOfFrames: Int) -> AnyPublisher<[CGImage], Error>
}

final class PTVideoEditorVideoTimeLineGenerator: PTVideoEditorVideoTimeLineGeneratorProtocol {

    func videoTimeline(for asset: AVAsset,
                       in bounds: CGRect,
                       numberOfFrames: Int) -> AnyPublisher<[CGImage], Error> {
        Future { promise in

            let generator = AVAssetImageGenerator(asset: asset)
            var images = [CGImage]()
            let times = self.frameTimes(for: asset, numberOfFrames: numberOfFrames)

            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = .zero // TODO

            generator.generateCGImagesAsynchronously(forTimes: times) { _, cgImage, _, result, error in
                if let error = error {
                    promise(.failure(error))
                } else if let cgImage = cgImage {
                    images.append(cgImage)
                    if images.count == numberOfFrames {
                        promise(.success(images))
                    }
                } else {
                    fatalError("Error while generating CGImages")
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

fileprivate extension PTVideoEditorVideoTimeLineGenerator {
    func frameTimes(for asset: AVAsset,
                    numberOfFrames: Int) -> [NSValue] {
        let timeIncrement = (asset.duration.seconds * 1000) / Double(numberOfFrames)
        var timesForThumbnails = [CMTime]()

        for index in 0..<numberOfFrames {
            let cmTime = CMTime(value: Int64(timeIncrement * Float64(index)), timescale: 1000)
            timesForThumbnails.append(cmTime)
        }

        return timesForThumbnails.map(NSValue.init)
    }
}

// Timeline这个功能封装成一个独立的服务，职责更加单一
public final class PTVideoTimelineService:Sendable {
    
    /// 异步获取视频时间轴帧数组
    /// - Parameters:
    ///   - asset: 视频源
    ///   - numberOfFrames: 需要提取的总帧数
    ///   - maximumSize: 缩略图最大尺寸（默认 300x300，极大降低内存占用）
    /// - Returns: 保证按时间顺序排列的 CGImage 数组
    public static func generateVideoTimeline(
        for asset: AVAsset,
        numberOfFrames: Int,
        maximumSize: CGSize = CGSize(width: 300, height: 300)
    ) async throws -> [CGImage] {
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        // 限制尺寸，避免 OOM 内存溢出
        generator.maximumSize = maximumSize
        
        // 【修复点】：这里直接获取 [CMTime] 数组
        let cmTimes = frameTimes(for: asset, numberOfFrames: numberOfFrames)
        
        if #available(iOS 16.0, *) {
            var images: [CGImage] = []
            // iOS 16+ 原生 API：直接接收 [CMTime]
            for await result in generator.images(for: cmTimes) {
                if let image = try? result.image {
                    images.append(image)
                }
            }
            return images
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                var images = [CGImage?](repeating: nil, count: cmTimes.count)
                var completedCount = 0
                var hasFailed = false
                
                // 【修复点】：仅在调用旧版 API 时，将 [CMTime] 包装为 [NSValue]
                let timeValues = cmTimes.map { NSValue(time: $0) }
                
                generator.generateCGImagesAsynchronously(forTimes: timeValues) { requestedTime, image, actualTime, result, error in
                    guard !hasFailed else { return }
                    
                    if let error = error {
                        hasFailed = true
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    // 使用纯净的 requestedTime (CMTime) 来查找对应索引，保证帧顺序正确
                    if let image = image, let index = cmTimes.firstIndex(of: requestedTime) {
                        images[index] = image
                    }
                    
                    completedCount += 1
                    if completedCount == cmTimes.count {
                        continuation.resume(returning: images.compactMap { $0 })
                    }
                }
            }
        }
    }

    // 私有辅助方法：计算每个抽帧的时间点
    private static func frameTimes(for asset: AVAsset, numberOfFrames: Int) -> [CMTime] {
        let timeIncrement = (asset.duration.seconds * 1000) / Double(numberOfFrames)
        var timesForThumbnails = [CMTime]()
        
        for index in 0..<numberOfFrames {
            let cmTime = CMTime(value: Int64(timeIncrement * Float64(index)), timescale: 1000)
            timesForThumbnails.append(cmTime)
        }
        
        return timesForThumbnails
    }
}
