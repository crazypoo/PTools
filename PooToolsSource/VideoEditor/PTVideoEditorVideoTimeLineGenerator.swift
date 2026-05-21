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
                       numberOfFrames: Int) -> AnyPublisher<[CGImage], Error>
}

final class PTVideoEditorVideoTimeLineGenerator: PTVideoEditorVideoTimeLineGeneratorProtocol {

    func videoTimeline(for asset: AVAsset,
                       in bounds: CGRect,
                       numberOfFrames: Int) -> AnyPublisher<[CGImage], Error> {
        Future { promise in
            
            let generator = AVAssetImageGenerator(asset: asset)
            let times = self.frameTimes(for: asset, numberOfFrames: numberOfFrames)
            
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = .zero // TODO: 你可以在这里配置尺寸
            
            // 👉 步骤 1：实例化状态机，将 promise 和目标数量托付给它
            let state = PTTimelineGeneratorState(targetCount: numberOfFrames, promise: promise)
            
            generator.generateCGImagesAsynchronously(forTimes: times) { _, cgImage, _, result, error in
                // 👉 步骤 2：现在闭包只需捕获线程安全的 'state' 对象
                if let error = error {
                    // 安全抛出错误
                    state.fail(with: error)
                } else if let cgImage = cgImage {
                    // 安全追加图片并自动检查是否完成
                    state.appendImage(cgImage)
                } else {
                    // 处理极端情况下的异常
                    state.fail(with: NSError(domain: "PTVideoTimelineError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error while generating CGImages"]))
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
        
        // 获取 [CMTime] 数组 (let 常量，天生并发安全)
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
                
                // 👉 步骤 1：实例化我们的线程安全状态机
                let state = PTVideoTimelineState(totalCount: cmTimes.count, continuation: continuation)
                
                // 将 [CMTime] 包装为 [NSValue]
                let timeValues = cmTimes.map { NSValue(time: $0) }
                
                generator.generateCGImagesAsynchronously(forTimes: timeValues) { requestedTime, image, actualTime, result, error in
                    
                    if let error = error {
                        // 👉 步骤 2：发生错误时，调用状态机的 fail 方法
                        state.fail(with: error)
                        return
                    }
                    
                    // 使用纯净的 requestedTime (CMTime) 来查找对应索引，保证帧顺序正确
                    // cmTimes 是外部的 let 常量，跨线程读取是绝对安全的
                    if let index = cmTimes.firstIndex(of: requestedTime) {
                        // 👉 步骤 3：成功时，调用状态机的 append 方法
                        state.append(image: image, at: index)
                    } else {
                        // 防御性编程：如果没有找到对应索引，当作获取到空图片处理进度
                        state.append(image: nil, at: 0) // 此处的 0 只是占位，实际逻辑中极少发生
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
