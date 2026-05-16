//
//  PTLivePhoto.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/2/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos
import CoreMedia
import UniformTypeIdentifiers

// 1. 用于包裹不兼容 Sendable 的 AVFoundation 对象的安全容器
private final class AVContext: @unchecked Sendable {
    let writer: AVAssetWriter
    let videoReader: AVAssetReader
    let videoReaderOutput: AVAssetReaderTrackOutput
    let audioReader: AVAssetReader?
    let audioReaderOutput: AVAssetReaderTrackOutput?
    
    init(writer: AVAssetWriter,
         videoReader: AVAssetReader,
         videoReaderOutput: AVAssetReaderTrackOutput,
         audioReader: AVAssetReader?,
         audioReaderOutput: AVAssetReaderTrackOutput?) {
        self.writer = writer
        self.videoReader = videoReader
        self.videoReaderOutput = videoReaderOutput
        self.audioReader = audioReader
        self.audioReaderOutput = audioReaderOutput
    }
}

// 2. 用于安全记录进度的容器
private final class ProgressState: @unchecked Sendable {
    var currentFrame: Int = 0
    var lastNotifiedProgress: Int = -1
}

// MARK: - 错误定义 (支持 Swift 6 Error 协议)
public enum PTLivePhotoError: Error, LocalizedError, Sendable {
    case cacheDirectoryFailed
    case assetGenerationFailed
    case missingResources
    case libraryAccessDenied
    case exportFailed(String) // 优化：不再保存非 Sendable 的 Error，改为 String
    
    public var errorDescription: String? {
        switch self {
        case .cacheDirectoryFailed: return "创建缓存文件夹失败"
        case .assetGenerationFailed: return "资源生成失败"
        case .missingResources: return "提取 Live Photo 资源失败或文件缺失"
        case .libraryAccessDenied: return "没有相册访问权限"
        case .exportFailed(let msg): return "导出失败: \(msg)"
        }
    }
}

// 视频写入状态管理器，使用 actor 确保 Swift 6 严格并发下的线程安全
private actor VideoWriterState {
    var isVideoFinished = false
    var isAudioFinished = false
    var isFinishing = false
    
    func finishVideo() { isVideoFinished = true }
    func finishAudio() { isAudioFinished = true }
    func markFinishing() { isFinishing = true }
    
    func canFinish() -> Bool {
        return isVideoFinished && isAudioFinished && !isFinishing
    }
}

public final class PTLivePhoto: Sendable {
    public typealias PTLivePhotoResources = (pairedImage: URL, pairedVideo: URL)
    
    public static let shared = PTLivePhoto()
    
    // 使用非隐式解包的计算属性/常量组合，保证并发访问的安全性
    private let cacheDirectoryURL: URL
    
    private init() {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fullDirectory = tempDirectoryURL.appendingPathComponent("com.crazypoo.PTLivePhoto")
        
        if !FileManager.default.fileExists(atPath: fullDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                PTNSLogConsole("[PTLivePhoto] 创建缓存文件夹失败: \(error)")
            }
        }
        self.cacheDirectoryURL = fullDirectory
    }
    
    // MARK: - Public API (Native Async/Await)
    
    /// 主动清理缓存
    public func clearCache() {
        do {
            try FileManager.default.removeItem(at: cacheDirectoryURL)
            // 重新创建空文件夹
            try FileManager.default.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            PTNSLogConsole("[PTLivePhoto] 清除缓存失败: \(error)")
        }
    }
    
    /// 获取 Live Photo 配对的图片和视频资源
    public class func extractResources(from livePhoto: PHLivePhoto) async throws(PTLivePhotoError) -> PTLivePhotoResources {
        return try await shared.extractResources(from: livePhoto)
    }
    
    /// 将图片和视频合成为 PHLivePhoto
    public class func generate(from imageURL: URL?, videoURL: URL, progress: @Sendable @escaping (CGFloat) -> Void) async throws(PTLivePhotoError) -> (PHLivePhoto, PTLivePhotoResources) {
        return try await shared.generate(from: imageURL, videoURL: videoURL, progress: progress)
    }
    
    /// 将配词的图文资源保存到相册
    @MainActor
    public class func saveToLibrary(_ resources: PTLivePhotoResources) async throws(PTLivePhotoError) -> Bool {
        // 现代化的并发权限请求
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard newStatus == .authorized || newStatus == .limited else {
                throw .libraryAccessDenied
            }
        } else if status != .authorized && status != .limited {
            throw .libraryAccessDenied
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                creationRequest.addResource(with: .pairedVideo, fileURL: resources.pairedVideo, options: options)
                creationRequest.addResource(with: .photo, fileURL: resources.pairedImage, options: options)
            }
            return true
        } catch {
            PTNSLogConsole("[PTLivePhoto] 保存到相册失败: \(error)")
            throw .exportFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Implementations
    
    private func generateKeyPhoto(from videoURL: URL) async -> URL? {
        let videoAsset = AVURLAsset(url: videoURL)
        do {
            // Swift 6 推荐使用异步 load 方法获取属性
            let duration = try await videoAsset.load(.duration)
            let durationSeconds = Float(duration.value)
            var percent: Float = 0.5
            
            if let stillImageTime = try await videoAsset.stillImageTime(), durationSeconds > 0 {
                percent = Float(stillImageTime.value) / durationSeconds
            }
            
            guard let imageFrame = try await videoAsset.getAssetFrame(percent: percent),
                  let jpegData = imageFrame.jpegData(compressionQuality: 1.0) else { return nil }
            
            let url = cacheDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            try jpegData.write(to: url)
            return url
        } catch {
            PTNSLogConsole("[PTLivePhoto] 写入封面图失败: \(error)")
            return nil
        }
    }
    
    private func generate(from imageURL: URL?, videoURL: URL, progress: @Sendable @escaping (CGFloat) -> Void) async throws(PTLivePhotoError) -> (PHLivePhoto, PTLivePhotoResources) {
        let assetIdentifier = UUID().uuidString
        let _keyPhotoURL = await (imageURL != nil ? imageURL : generateKeyPhoto(from: videoURL))
        
        guard let keyPhotoURL = _keyPhotoURL,
              let pairedImageURL = addAssetID(assetIdentifier, toImage: keyPhotoURL, saveTo: cacheDirectoryURL.appendingPathComponent(assetIdentifier).appendingPathExtension("jpg")) else {
            throw .assetGenerationFailed
        }
        
        // 使用 continuation 桥接基于回调的 AVAssetWriter
        let pairedVideoURL: URL? = await withCheckedContinuation { continuation in
            addAssetID(assetIdentifier, toVideo: videoURL, saveTo: cacheDirectoryURL.appendingPathComponent(assetIdentifier).appendingPathExtension("mov"), progress: progress) { url in
                continuation.resume(returning: url)
            }
        }
        
        guard let finalVideoURL = pairedVideoURL else {
            throw .assetGenerationFailed
        }
        
        do {
            let livePhoto = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PHLivePhoto, Error>) in
                PHLivePhoto.request(withResourceFileURLs: [finalVideoURL, pairedImageURL], placeholderImage: nil, targetSize: CGSize.zero, contentMode: .aspectFit) { (livePhoto, info) in
                    if let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Bool, isDegraded { return }
                    if let lp = livePhoto {
                        continuation.resume(returning: lp)
                    } else {
                        continuation.resume(throwing: PTLivePhotoError.assetGenerationFailed)
                    }
                }
            }
            return (livePhoto, (pairedImageURL, finalVideoURL))
        } catch {
            throw .assetGenerationFailed
        }
    }
    
    private func extractResources(from livePhoto: PHLivePhoto) async throws(PTLivePhotoError) -> PTLivePhotoResources {
        let assetResources = PHAssetResource.assetResources(for: livePhoto)
        var keyPhotoURL: URL?
        var videoURL: URL?
        
        // 步骤 1：使用顺序遍历替代 TaskGroup。安全且逻辑直观。
        for resource in assetResources {
            guard let utType = UTType(resource.uniformTypeIdentifier),
                  let ext = utType.preferredFilenameExtension else {
                continue
            }
            
            let fileURL = cacheDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            
            do {
                // 步骤 2：使用 direct writeData API，直接把数据流写进沙盒文件，不仅免除并发报错，还能巨幅优化内存占用！
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    PHAssetResourceManager.default().writeData(for: resource, toFile: fileURL, options: options) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
                
                // 步骤 3：记录生成的文件路径
                if resource.type == .pairedVideo {
                    videoURL = fileURL
                } else if resource.type == .photo {
                    keyPhotoURL = fileURL
                }
                
            } catch {
                PTNSLogConsole("[PTLivePhoto] 提取或写入资源文件失败: \(error)")
                // 捕获到内部 Error 后，统一抛出我们自定义的强类型错误
                throw .missingResources
            }
        }
        
        // 步骤 4：验证资源是否齐全
        guard let photo = keyPhotoURL, let video = videoURL else {
            throw .missingResources
        }
        
        return (photo, video)
    }
    
    private func addAssetID(_ assetIdentifier: String, toImage imageURL: URL, saveTo destinationURL: URL) -> URL? {
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil),
              let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
              var imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable : Any] else { return nil }
        
        let assetIdentifierKey = "17"
        let assetIdentifierInfo = [assetIdentifierKey : assetIdentifier]
        imageProperties[kCGImagePropertyMakerAppleDictionary] = assetIdentifierInfo
        
        CGImageDestinationAddImage(imageDestination, imageRef, imageProperties as CFDictionary)
        CGImageDestinationFinalize(imageDestination)
        return destinationURL
    }
    
    // 这里保留了回调，因为 AVAssetWriterInput 的 requestMediaDataWhenReady 基于回调驱动
    // 给视频写入 Live Photo Asset ID
    private func addAssetID(_ assetIdentifier: String, toVideo videoURL: URL, saveTo destinationURL: URL, progress: @Sendable @escaping (CGFloat) -> Void, completion: @Sendable @escaping (URL?) -> Void) {
        
        Task {
            let videoAsset = AVURLAsset(url: videoURL)
            guard let videoTrack = try? await videoAsset.loadTracks(withMediaType: .video).first else {
                completion(nil)
                return
            }
            
            let frameCount = await videoAsset.countFrames(exact: false)
            
            do {
                let assetWriter = try AVAssetWriter(outputURL: destinationURL, fileType: .mov)
                let videoReader = try AVAssetReader(asset: videoAsset)
                
                let videoReaderSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
                videoReaderOutput.alwaysCopiesSampleData = false
                videoReader.add(videoReaderOutput)
                
                let naturalSize = try await videoTrack.load(.naturalSize)
                let transform = try await videoTrack.load(.preferredTransform)
                
                let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: naturalSize.width,
                    AVVideoHeightKey: naturalSize.height
                ])
                videoWriterInput.transform = transform
                videoWriterInput.expectsMediaDataInRealTime = false
                assetWriter.add(videoWriterInput)
                
                var audioReader: AVAssetReader?
                var audioReaderOutput: AVAssetReaderTrackOutput?
                var audioWriterInput: AVAssetWriterInput?
                
                if let audioTrack = try? await videoAsset.loadTracks(withMediaType: .audio).first {
                    let _audioReader = try AVAssetReader(asset: videoAsset)
                    let _audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
                    _audioReader.add(_audioReaderOutput)
                    
                    let _audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
                    _audioWriterInput.expectsMediaDataInRealTime = false
                    assetWriter.add(_audioWriterInput)
                    
                    audioReader = _audioReader
                    audioReaderOutput = _audioReaderOutput
                    audioWriterInput = _audioWriterInput
                }
                
                let assetIdentifierMetadata = metadataForAssetID(assetIdentifier)
                let stillImageTimeMetadataAdapter = createMetadataAdaptorForStillImageTime()
                assetWriter.metadata = [assetIdentifierMetadata]
                assetWriter.add(stillImageTimeMetadataAdapter.assetWriterInput)
                
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: .zero)
                
                let timeRange = await videoAsset.makeStillImageTimeRange(percent: 0.5, inFrameCount: frameCount)
                stillImageTimeMetadataAdapter.append(AVTimedMetadataGroup(items: [metadataItemForStillImageTime()], timeRange: timeRange))
                
                // 👉 这里的改动最关键：把所有 AV 对象（包括 Output）都塞进常量容器里
                let state = VideoWriterState()
                let avContext = AVContext(
                    writer: assetWriter,
                    videoReader: videoReader,
                    videoReaderOutput: videoReaderOutput, // 新增
                    audioReader: audioReader,
                    audioReaderOutput: audioReaderOutput    // 新增
                )
                let pState = ProgressState()
                
                if audioWriterInput == nil {
                    await state.finishAudio()
                }
                
                @Sendable func finishIfPossible() async {
                    let canFinish = await state.canFinish()
                    if canFinish {
                        await state.markFinishing()
                        avContext.writer.finishWriting {
                            if avContext.writer.status == .completed {
                                completion(destinationURL)
                            } else {
                                PTNSLogConsole("[PTLivePhoto] AssetWriter 失败")
                                completion(nil)
                            }
                        }
                    }
                }
                
                // 视频写入
                if avContext.videoReader.startReading() {
                    videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "pt.livephoto.video")) {
                        while videoWriterInput.isReadyForMoreMediaData {
                            autoreleasepool {
                                // 👉 修改点：使用 avContext.videoReaderOutput
                                guard let sample = avContext.videoReaderOutput.copyNextSampleBuffer() else {
                                    videoWriterInput.markAsFinished()
                                    Task {
                                        await state.finishVideo()
                                        await finishIfPossible()
                                    }
                                    return
                                }
                                
                                pState.currentFrame += 1
                                let progressValue = frameCount > 0 ? CGFloat(pState.currentFrame) / CGFloat(frameCount) : 0
                                let currentIntProgress = Int(progressValue * 100)
                                
                                if currentIntProgress > pState.lastNotifiedProgress {
                                    pState.lastNotifiedProgress = currentIntProgress
                                    Task { @MainActor in progress(progressValue) }
                                }
                                
                                if !videoWriterInput.append(sample) {
                                    avContext.videoReader.cancelReading()
                                    Task {
                                        await state.finishVideo()
                                        await finishIfPossible()
                                    }
                                    return
                                }
                            }
                        }
                    }
                } else {
                    await state.finishVideo()
                    await finishIfPossible()
                }
                
                // 音频写入
                if let aReader = avContext.audioReader, aReader.startReading(), let aWriterInput = audioWriterInput {
                    aWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "pt.livephoto.audio")) {
                        while aWriterInput.isReadyForMoreMediaData {
                            autoreleasepool {
                                // 👉 修复点：通过 avContext 调用 audioReaderOutput
                                guard let sample = avContext.audioReaderOutput?.copyNextSampleBuffer() else {
                                    aWriterInput.markAsFinished()
                                    Task {
                                        await state.finishAudio()
                                        await finishIfPossible()
                                    }
                                    return
                                }
                                if !aWriterInput.append(sample) {
                                    aReader.cancelReading()
                                    Task {
                                        await state.finishAudio()
                                        await finishIfPossible()
                                    }
                                    return
                                }
                            }
                        }
                    }
                } else {
                    await state.finishAudio()
                    await finishIfPossible()
                }
                
            } catch {
                PTNSLogConsole("[PTLivePhoto] 生成视频资源出错: \(error)")
                completion(nil)
            }
        }
    }
    
    // Metadata Creators
    private func metadataForAssetID(_ assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = "com.apple.quicktime.content.identifier" as NSCopying & NSObjectProtocol
        item.keySpace = AVMetadataKeySpace(rawValue: "mdta")
        item.value = assetIdentifier as NSCopying & NSObjectProtocol
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }
    
    private func createMetadataAdaptorForStillImageTime() -> AVAssetWriterInputMetadataAdaptor {
        let spec: NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString: "mdta/com.apple.quicktime.still-image-time",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString: "com.apple.metadata.datatype.int8"
        ]
        var desc: CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [spec] as CFArray, formatDescriptionOut: &desc)
        let input = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }
    
    private func metadataItemForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = "com.apple.quicktime.still-image-time" as NSCopying & NSObjectProtocol
        item.keySpace = AVMetadataKeySpace(rawValue: "mdta")
        item.value = 0 as NSCopying & NSObjectProtocol
        item.dataType = "com.apple.metadata.datatype.int8"
        return item
    }
}

// MARK: - Extension 工具方法 (原生 Async/Await 化)
fileprivate extension AVAsset {
    func countFrames(exact: Bool) async -> Int {
        var frameCount = 0
        guard let videoTrack = try? await self.loadTracks(withMediaType: .video).first else { return 0 }
        
        let duration = try? await self.load(.duration)
        let nominalFrameRate = try? await videoTrack.load(.nominalFrameRate)
        
        if let d = duration, let fps = nominalFrameRate {
            let estimatedFrames = Int(CMTimeGetSeconds(d) * Float64(fps))
            if !exact && estimatedFrames > 0 {
                return estimatedFrames
            }
        }
        
        if let videoReader = try? AVAssetReader(asset: self) {
            let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
            videoReader.add(videoReaderOutput)
            if videoReader.startReading() {
                while let _ = videoReaderOutput.copyNextSampleBuffer() {
                    autoreleasepool {
                        frameCount += 1
                    }
                }
                videoReader.cancelReading()
            }
        }
        return frameCount
    }
    
    func stillImageTime() async throws -> CMTime? {
        var stillTime: CMTime? = nil
        guard let metadataTrack = try await self.loadTracks(withMediaType: .metadata).first else { return nil }
        
        if let videoReader = try? AVAssetReader(asset: self) {
            let videoReaderOutput = AVAssetReaderTrackOutput(track: metadataTrack, outputSettings: nil)
            videoReader.add(videoReaderOutput)
            
            if videoReader.startReading() {
                var found = false
                while !found, let sampleBuffer = videoReaderOutput.copyNextSampleBuffer() {
                    if CMSampleBufferGetNumSamples(sampleBuffer) != 0,
                       let group = AVTimedMetadataGroup(sampleBuffer: sampleBuffer) {
                        for item in group.items {
                            if item.key as? String == "com.apple.quicktime.still-image-time" && item.keySpace?.rawValue == "mdta" {
                                stillTime = group.timeRange.start
                                found = true
                                break
                            }
                        }
                    }
                }
                videoReader.cancelReading()
            }
        }
        return stillTime
    }
    
    func makeStillImageTimeRange(percent: Float, inFrameCount: Int = 0) async -> CMTimeRange {
        guard let time = try? await self.load(.duration) else { return .zero }
        var computedTime = time
        let frameCount = inFrameCount == 0 ? await self.countFrames(exact: false) : inFrameCount
        let safeFrameCount = max(frameCount, 1)
        
        let frameDuration = Int64(Float(computedTime.value) / Float(safeFrameCount))
        computedTime.value = Int64(Float(computedTime.value) * percent)
        return CMTimeRangeMake(start: computedTime, duration: CMTimeMake(value: frameDuration, timescale: computedTime.timescale))
    }
    
    func getAssetFrame(percent: Float) async throws -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = CMTimeMake(value: 1, timescale: 100)
        imageGenerator.requestedTimeToleranceBefore = CMTimeMake(value: 1, timescale: 100)
        
        let duration = try await self.load(.duration)
        var time = duration
        time.value = Int64(Float(time.value) * percent)
        
        // 拥抱现代 Async 的图片生成 API (iOS 16+)
        // 若需兼容更低版本，可替换回 copyCGImage 配合 withCheckedThrowingContinuation
        if #available(iOS 16.0, *) {
            let (imageRef, _) = try await imageGenerator.image(at: time)
            return UIImage(cgImage: imageRef)
        } else {
            var actualTime = CMTime.zero
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            return UIImage(cgImage: imageRef)
        }
    }
}
