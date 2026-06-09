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

private final class PTTimelineGeneratorState: @unchecked Sendable {
    private var images: [CGImage] = []
    private let targetCount: Int
    private let promise: (Result<[CGImage], Error>) -> Void
    private let lock = NSLock()
    private var hasFinished = false // 防御性机制，确保 Promise 只被调用一次
    
    init(targetCount: Int, promise: @escaping (Result<[CGImage], Error>) -> Void) {
        self.targetCount = targetCount
        self.promise = promise
    }
    
    /// 安全地追加图片
    func appendImage(_ image: CGImage) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !hasFinished else { return }
        
        images.append(image)
        if images.count == targetCount {
            hasFinished = true
            promise(.success(images))
        }
    }
    
    /// 安全地处理失败情况
    func fail(with error: Error) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !hasFinished else { return }
        hasFinished = true
        promise(.failure(error))
    }
}

protocol PTVideoEditorVideoTimeLineGeneratorProtocol {
    func videoTimeline(for asset: AVAsset,
                       in bounds: CGRect,
                       numberOfFrames: Int) async throws -> [CGImage]
}

final class PTVideoEditorVideoTimeLineGenerator: PTVideoEditorVideoTimeLineGeneratorProtocol {

    func videoTimeline(for asset: AVAsset,
                       in bounds: CGRect,
                       numberOfFrames: Int) async throws -> [CGImage] {
        return try await PTVideoTimelineService.generateVideoTimeline(for: asset, numberOfFrames: numberOfFrames, maximumSize: .zero)
    }
}

public class PTVideoFrameTimeLineFunction {
    public static func frameTimes(for asset: AVAsset,
                                  numberOfFrames: Int) async -> [CMTime] {
        // 增加一个小小的安全防御，防止除以 0
        guard numberOfFrames > 0 else { return [] }
        
        do {
            // 🌟 1. Swift 6 适配：异步读取时长，彻底告别主线程卡顿
            let duration = try await asset.load(.duration)
            
            let timeIncrement = (duration.seconds * 1000) / Double(numberOfFrames)
            var timesForThumbnails = [CMTime]()

            for index in 0..<numberOfFrames {
                let cmTime = CMTime(value: Int64(timeIncrement * Float64(index)), timescale: 1000)
                timesForThumbnails.append(cmTime)
            }

            // 🌟 2. 现代 Swift 写法：使用闭包明确指定构造器
            return timesForThumbnails
            
        } catch {
            PTNSLogConsole("⚠️ 获取视频时长失败: \(error.localizedDescription)")
            return []
        }
    }
}

fileprivate extension PTVideoEditorVideoTimeLineGenerator {
    func frameTimes(for asset: AVAsset,
                    numberOfFrames: Int) async -> [CMTime] {
        return await PTVideoFrameTimeLineFunction.frameTimes(for: asset, numberOfFrames: numberOfFrames)
    }
}

private final class PTVideoTimelineState: @unchecked Sendable {
    private var images: [CGImage?]
    private var completedCount = 0
    private var hasFailed = false
    private let totalCount: Int
    private let continuation: CheckedContinuation<[CGImage], Error>
    private let lock = NSLock()
    
    init(totalCount: Int, continuation: CheckedContinuation<[CGImage], Error>) {
        self.totalCount = totalCount
        self.continuation = continuation
        // 预先分配好空间，保证最后可以按顺序组装
        self.images = [CGImage?](repeating: nil, count: totalCount)
    }
    
    /// 成功获取一帧时的安全处理
    func append(image: CGImage?, at index: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !hasFailed else { return }
        
        // 按索引存入，确保最终时间线顺序正确
        images[index] = image
        completedCount += 1
        
        // 当所有帧都处理完毕时，返回结果
        if completedCount == totalCount {
            continuation.resume(returning: images.compactMap { $0 })
        }
    }
    
    /// 发生错误时的安全处理
    func fail(with error: Error) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !hasFailed else { return }
        
        hasFailed = true
        continuation.resume(throwing: error)
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
    public static func generateVideoTimeline(for asset: AVAsset,
                                             numberOfFrames: Int,
                                             maximumSize: CGSize = CGSize(width: 300, height: 300)) async throws -> [CGImage] {
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        // 限制尺寸，避免 OOM 内存溢出
        generator.maximumSize = maximumSize
        
        // 🌟 唯一修正点：因为 frameTimes 是异步函数，这里必须加上 await
        // (注意：因为当前方法是 static，请确保你的 frameTimes 方法也是 static 的)
        let cmTimes = await frameTimes(for: asset, numberOfFrames: numberOfFrames)
        
        var images: [CGImage] = []
        
        // 🚀 iOS 16+ 原生 API：直接接收 [CMTime]
        // 这里的 for await 写法极其标准，无需 try await，因为迭代本身不抛出错误
        for await result in generator.images(for: cmTimes) {
            // 这一步堪称点睛之笔：使用 try? 容错，如果某一帧坏了直接忽略，不影响整个时间轴的生成
            if let image = try? result.image {
                images.append(image)
            }
        }
        
        return images
    }

    // 私有辅助方法：计算每个抽帧的时间点
    private static func frameTimes(for asset: AVAsset, numberOfFrames: Int) async -> [CMTime] {
        return await PTVideoFrameTimeLineFunction.frameTimes(for: asset, numberOfFrames: numberOfFrames)
    }
}
