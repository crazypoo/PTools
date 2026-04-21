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

// MARK: - 错误定义
public enum PTLivePhotoError: Error, LocalizedError {
    case cacheDirectoryFailed
    case assetGenerationFailed
    case missingResources
    case libraryAccessDenied
    case exportFailed(Error?)
    
    public var errorDescription: String? {
        switch self {
        case .cacheDirectoryFailed: return "创建缓存文件夹失败"
        case .assetGenerationFailed: return "资源生成失败"
        case .missingResources: return "提取 Live Photo 资源失败或文件缺失"
        case .libraryAccessDenied: return "没有相册访问权限"
        case .exportFailed(let err): return "导出失败: \(err?.localizedDescription ?? "未知错误")"
        }
    }
}

public class PTLivePhoto {
    public typealias PTLivePhotoResources = (pairedImage: URL, pairedVideo: URL)
    
    public static let shared = PTLivePhoto()
    private static let queue = DispatchQueue(label: "com.crazypoo.PTLivePhoto.queue", attributes: .concurrent)
    
    // 优化1：改用 NSTemporaryDirectory，系统会在磁盘空间紧张时自动帮我们清理，更加安全
    fileprivate lazy var cacheDirectory: URL? = {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fullDirectory = tempDirectoryURL.appendingPathComponent("com.crazypoo.PTLivePhoto")
        if !FileManager.default.fileExists(atPath: fullDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                PTNSLogConsole("[PTLivePhoto] 创建缓存文件夹失败: \(error)")
                return nil
            }
        }
        return fullDirectory
    }()
    
    // 限制外部实例化，保证单例的唯一性
    private init() {}
    
    // MARK: - Public API
    
    /// 主动清理缓存 (单例的 deinit 不会被调用，需手动暴露)
    public func clearCache() {
        guard let cacheDirectory = cacheDirectory else { return }
        do {
            try FileManager.default.removeItem(at: cacheDirectory)
        } catch {
            PTNSLogConsole("[PTLivePhoto] 清除缓存失败: \(error)")
        }
    }
    
    /// 获取 Live Photo 配对的图片和视频资源
    public class func extractResources(from livePhoto: PHLivePhoto, completion: @escaping (Result<PTLivePhotoResources, PTLivePhotoError>) -> Void) {
        queue.async {
            shared.extractResources(from: livePhoto, completion: completion)
        }
    }
    
    /// 将图片和视频合成为 PHLivePhoto
    public class func generate(from imageURL: URL?, videoURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (Result<(PHLivePhoto, PTLivePhotoResources), PTLivePhotoError>) -> Void) {
        queue.async {
            shared.generate(from: imageURL, videoURL: videoURL, progress: progress, completion: completion)
        }
    }
    
    /// 将配词的图文资源保存到相册 (优化2：补充权限检查)
    public class func saveToLibrary(_ resources: PTLivePhotoResources, completion: @escaping (Result<Bool, PTLivePhotoError>) -> Void) {
        let saveAction = {
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                creationRequest.addResource(with: .pairedVideo, fileURL: resources.pairedVideo, options: options)
                creationRequest.addResource(with: .photo, fileURL: resources.pairedImage, options: options)
            }, completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        PTNSLogConsole("[PTLivePhoto] 保存到相册失败: \(error)")
                        completion(.failure(.exportFailed(error)))
                    } else {
                        completion(.success(success))
                    }
                }
            })
        }
        
        // 权限检查
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    saveAction()
                } else {
                    DispatchQueue.main.async { completion(.failure(.libraryAccessDenied)) }
                }
            }
        } else if status == .authorized || status == .limited {
            saveAction()
        } else {
            completion(.failure(.libraryAccessDenied))
        }
    }
    
    // MARK: - Private Implementations
    
    private func generateKeyPhoto(from videoURL: URL) -> URL? {
        var percent: Float = 0.5
        let videoAsset = AVURLAsset(url: videoURL)
        let duration = Float(videoAsset.duration.value)
        
        if let stillImageTime = videoAsset.stillImageTime(), duration > 0 {
            percent = Float(stillImageTime.value) / duration
        }
        
        guard let imageFrame = videoAsset.getAssetFrame(percent: percent),
              let jpegData = imageFrame.jpegData(compressionQuality: 1.0),
              let url = cacheDirectory?.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg") else {
            return nil
        }
        
        do {
            try jpegData.write(to: url)
            return url
        } catch {
            PTNSLogConsole("[PTLivePhoto] 写入封面图失败: \(error)")
            return nil
        }
    }
    
    private func generate(from imageURL: URL?, videoURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (Result<(PHLivePhoto, PTLivePhotoResources), PTLivePhotoError>) -> Void) {
        guard let cacheDirectory = cacheDirectory else {
            DispatchQueue.main.async { completion(.failure(.cacheDirectoryFailed)) }
            return
        }
        
        let assetIdentifier = UUID().uuidString
        let _keyPhotoURL = imageURL ?? generateKeyPhoto(from: videoURL)
        
        guard let keyPhotoURL = _keyPhotoURL,
              let pairedImageURL = addAssetID(assetIdentifier, toImage: keyPhotoURL, saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("jpg")) else {
            DispatchQueue.main.async { completion(.failure(.assetGenerationFailed)) }
            return
        }
        
        addAssetID(assetIdentifier, toVideo: videoURL, saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("mov"), progress: progress) { (_videoURL) in
            guard let pairedVideoURL = _videoURL else {
                DispatchQueue.main.async { completion(.failure(.assetGenerationFailed)) }
                return
            }
            
            _ = PHLivePhoto.request(withResourceFileURLs: [pairedVideoURL, pairedImageURL], placeholderImage: nil, targetSize: CGSize.zero, contentMode: .aspectFit) { (livePhoto, info) in
                if let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Bool, isDegraded { return }
                DispatchQueue.main.async {
                    if let lp = livePhoto {
                        completion(.success((lp, (pairedImageURL, pairedVideoURL))))
                    } else {
                        completion(.failure(.assetGenerationFailed))
                    }
                }
            }
        }
    }
    
    private func extractResources(from livePhoto: PHLivePhoto, to directoryURL: URL, completion: @escaping (PTLivePhotoResources?) -> Void) {
        let assetResources = PHAssetResource.assetResources(for: livePhoto)
        let group = DispatchGroup()
        var keyPhotoURL: URL?
        var videoURL: URL?
        
        for resource in assetResources {
            let buffer = NSMutableData()
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            group.enter()
            
            PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { (data) in
                buffer.append(data)
            }) { [weak self] (error) in
                guard let self = self else { group.leave(); return }
                if error == nil {
                    let fileURL = self.saveAssetResource(resource, to: directoryURL, resourceData: buffer as Data)
                    if resource.type == .pairedVideo {
                        videoURL = fileURL
                    } else if resource.type == .photo {
                        keyPhotoURL = fileURL
                    }
                } else {
                    PTNSLogConsole("[PTLivePhoto] 提取资源失败: \(String(describing: error))")
                }
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            guard let pairedPhotoURL = keyPhotoURL, let pairedVideoURL = videoURL else {
                completion(nil)
                return
            }
            completion((pairedPhotoURL, pairedVideoURL))
        }
    }
    
    private func extractResources(from livePhoto: PHLivePhoto, completion: @escaping (Result<PTLivePhotoResources, PTLivePhotoError>) -> Void) {
        if let cacheDirectory = cacheDirectory {
            extractResources(from: livePhoto, to: cacheDirectory) { resources in
                if let res = resources {
                    completion(.success(res))
                } else {
                    completion(.failure(.missingResources))
                }
            }
        } else {
            completion(.failure(.cacheDirectoryFailed))
        }
    }
    
    private func saveAssetResource(_ resource: PHAssetResource, to directory: URL, resourceData: Data) -> URL? {
        guard let utType = UTType(resource.uniformTypeIdentifier),
              let ext = utType.preferredFilenameExtension else {
            return nil
        }
        let fileUrl = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
        do {
            try resourceData.write(to: fileUrl, options: .atomic)
            return fileUrl
        } catch {
            PTNSLogConsole("[PTLivePhoto] 保存资源文件失败: \(error)")
            return nil
        }
    }
    
    // 给图片写入 Live Photo Asset ID
    private func addAssetID(_ assetIdentifier: String, toImage imageURL: URL, saveTo destinationURL: URL) -> URL? {
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil),
              let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
              var imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable : Any] else { return nil }
        
        // Asset ID 键值
        let assetIdentifierKey = "17"
        let assetIdentifierInfo = [assetIdentifierKey : assetIdentifier]
        imageProperties[kCGImagePropertyMakerAppleDictionary] = assetIdentifierInfo
        
        CGImageDestinationAddImage(imageDestination, imageRef, imageProperties as CFDictionary)
        CGImageDestinationFinalize(imageDestination)
        return destinationURL
    }
    
    // 给视频写入 Live Photo Asset ID
    private func addAssetID(_ assetIdentifier: String, toVideo videoURL: URL, saveTo destinationURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (URL?) -> Void ) {
        
        let videoAsset = AVURLAsset(url: videoURL)
        let frameCount = videoAsset.countFrames(exact: false)
        
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        
        do {
            let assetWriter = try AVAssetWriter(outputURL: destinationURL, fileType: .mov)
            let videoReader = try AVAssetReader(asset: videoAsset)
            
            let videoReaderSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
            videoReaderOutput.alwaysCopiesSampleData = false
            videoReader.add(videoReaderOutput)
            
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: videoTrack.naturalSize.width,
                AVVideoHeightKey: videoTrack.naturalSize.height
            ])
            videoWriterInput.transform = videoTrack.preferredTransform
            videoWriterInput.expectsMediaDataInRealTime = false
            assetWriter.add(videoWriterInput)
            
            var audioReader: AVAssetReader?
            var audioReaderOutput: AVAssetReaderTrackOutput?
            var audioWriterInput: AVAssetWriterInput?
            
            if let audioTrack = videoAsset.tracks(withMediaType: .audio).first {
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
            
            // Metadata
            let assetIdentifierMetadata = metadataForAssetID(assetIdentifier)
            let stillImageTimeMetadataAdapter = createMetadataAdaptorForStillImageTime()
            assetWriter.metadata = [assetIdentifierMetadata]
            assetWriter.add(stillImageTimeMetadataAdapter.assetWriterInput)
            
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            let stillPercent: Float = 0.5
            let timeRange = videoAsset.makeStillImageTimeRange(percent: stillPercent, inFrameCount: frameCount)
            stillImageTimeMetadataAdapter.append(AVTimedMetadataGroup(items: [metadataItemForStillImageTime()], timeRange: timeRange))
            
            // --- 线程安全设计 ---
            let lock = NSLock()
            var writingVideoFinished = false
            var writingAudioFinished = audioWriterInput == nil
            var isFinishing = false
            var currentFrame = 0
            
            func finishIfPossible() {
                lock.lock()
                defer { lock.unlock() }
                
                guard writingVideoFinished, writingAudioFinished, !isFinishing else { return }
                isFinishing = true
                
                assetWriter.finishWriting {
                    if assetWriter.status == .completed {
                        completion(destinationURL)
                    } else {
                        PTNSLogConsole("[PTLivePhoto] AssetWriter 失败状态: \(String(describing: assetWriter.error))")
                        completion(nil)
                    }
                }
            }
            
            // Video writing
            if videoReader.startReading() {
                videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "pt.livephoto.video")) {
                    while videoWriterInput.isReadyForMoreMediaData {
                        // 优化3：加入 autoreleasepool，防止大视频导致内存泄漏 (OOM)
                        autoreleasepool {
                            guard let sample = videoReaderOutput.copyNextSampleBuffer() else {
                                videoWriterInput.markAsFinished()
                                lock.lock()
                                writingVideoFinished = true
                                lock.unlock()
                                finishIfPossible()
                                return
                            }
                            
                            lock.lock()
                            currentFrame += 1
                            let frame = currentFrame
                            lock.unlock()
                            
                            var lastNotifiedProgress: Int = -1
                            let progressValue = frameCount > 0 ? CGFloat(frame) / CGFloat(frameCount) : 0
                            let currentIntProgress = Int(progressValue * 100)
                            
                            if currentIntProgress > lastNotifiedProgress {
                                lastNotifiedProgress = currentIntProgress
                                DispatchQueue.main.async { progress(progressValue) }
                            }

                            if !videoWriterInput.append(sample) {
                                videoReader.cancelReading()
                                lock.lock()
                                writingVideoFinished = true
                                lock.unlock()
                                finishIfPossible()
                                return
                            }
                        }
                    }
                }
            } else {
                writingVideoFinished = true
                finishIfPossible()
            }
            
            // Audio writing
            if let audioReader = audioReader, audioReader.startReading(), let audioWriterInput = audioWriterInput {
                audioWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "pt.livephoto.audio")) {
                    while audioWriterInput.isReadyForMoreMediaData {
                        // 优化3：同样加入 autoreleasepool
                        autoreleasepool {
                            guard let sample = audioReaderOutput?.copyNextSampleBuffer() else {
                                audioWriterInput.markAsFinished()
                                lock.lock()
                                writingAudioFinished = true
                                lock.unlock()
                                finishIfPossible()
                                return
                            }
                            if !audioWriterInput.append(sample) {
                                audioReader.cancelReading()
                                lock.lock()
                                writingAudioFinished = true
                                lock.unlock()
                                finishIfPossible()
                                return
                            }
                        }
                    }
                }
            } else {
                lock.lock()
                writingAudioFinished = true
                lock.unlock()
                finishIfPossible()
            }
            
        } catch {
            PTNSLogConsole("[PTLivePhoto] 生成视频资源出错: \(error)")
            completion(nil)
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

// MARK: - 功能扩展：Async/Await 支持 (优化4：支持抛出真实错误)
public extension PTLivePhoto {
    
    /// 异步获取 Live Photo 配对资源 (Async/Await 扩展)
    class func extractResources(from livePhoto: PHLivePhoto) async throws -> PTLivePhotoResources {
        try await withCheckedThrowingContinuation { continuation in
            extractResources(from: livePhoto) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// 异步保存到相册 (Async/Await 扩展)
    class func saveToLibrary(_ resources: PTLivePhotoResources) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            saveToLibrary(resources) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// 异步生成 Live Photo
    class func generate(from imageURL: URL?, videoURL: URL, progress: @escaping (CGFloat) -> Void) async throws -> (PHLivePhoto, PTLivePhotoResources) {
        try await withCheckedThrowingContinuation { continuation in
            generate(from: imageURL, videoURL: videoURL, progress: progress) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - Extension 工具方法
fileprivate extension AVAsset {
    func countFrames(exact: Bool) -> Int {
        var frameCount = 0
        if let videoTrack = self.tracks(withMediaType: .video).first {
            // 性能优化：优先使用预估帧数计算，避免全视频读取造成卡顿
            let estimatedFrames = Int(CMTimeGetSeconds(self.duration) * Float64(videoTrack.nominalFrameRate))
            if !exact && estimatedFrames > 0 {
                return estimatedFrames
            }
            
            // 只有强制要求精确或预估失败时，才进入耗时的逐帧遍历
            if let videoReader = try? AVAssetReader(asset: self) {
                let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
                videoReader.add(videoReaderOutput)
                if videoReader.startReading() {
                    while let _ = videoReaderOutput.copyNextSampleBuffer() {
                        // 优化3：防止逐帧遍历时的内存堆积
                        autoreleasepool {
                            frameCount += 1
                        }
                    }
                    videoReader.cancelReading()
                }
            }
        }
        return frameCount
    }
    
    func stillImageTime() -> CMTime? {
        var stillTime: CMTime? = nil
        if let videoReader = try? AVAssetReader(asset: self),
           let metadataTrack = self.tracks(withMediaType: .metadata).first {
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
    
    func makeStillImageTimeRange(percent: Float, inFrameCount: Int = 0) -> CMTimeRange {
        var time = self.duration
        let frameCount = inFrameCount == 0 ? self.countFrames(exact: false) : inFrameCount
        let safeFrameCount = max(frameCount, 1) // 避免除以 0
        
        let frameDuration = Int64(Float(time.value) / Float(safeFrameCount))
        time.value = Int64(Float(time.value) * percent)
        return CMTimeRangeMake(start: time, duration: CMTimeMake(value: frameDuration, timescale: time.timescale))
    }
    
    func getAssetFrame(percent: Float) -> UIImage? {
        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = CMTimeMake(value: 1, timescale: 100)
        imageGenerator.requestedTimeToleranceBefore = CMTimeMake(value: 1, timescale: 100)
        
        var time = self.duration
        time.value = Int64(Float(time.value) * percent)
        
        do {
            var actualTime = CMTime.zero
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            return UIImage(cgImage: imageRef)
        } catch {
            PTNSLogConsole("[PTLivePhoto] 生成帧图片失败: \(error)")
            return nil
        }
    }
}
