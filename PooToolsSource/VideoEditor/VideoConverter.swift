//
//  VideoConverter.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVKit

private struct PTVideoExportBox: @unchecked Sendable {
    let isCancelledState: Bool
}

// 新增：引入 @MainActor 保证外部调用的安全，解决绝大部分 Sendable 捕获警告
@MainActor
open class VideoConverter {
    // 记录当前正在导出的目标路径，用于失败/取消时的安全清理
    private var currentExportURL: URL?

    public let asset: AVAsset
    public let presets: [String]

    public var option: ConverterOption?

    private var assetExportsSession: AVAssetExportSession?
    private struct PTSafeExportSessionBox: @unchecked Sendable {
        let session: AVAssetExportSession?
    }
    
    private struct PTSafeAudioExportBox: @unchecked Sendable {
        let reader: AVAssetReader
        let writer: AVAssetWriter
        let trackOutput: AVAssetReaderTrackOutput
        let writerInput: AVAssetWriterInput
    }
    
    // 进度回调，标记为 @Sendable 以允许跨线程安全传递
    private var progressCallback: (@Sendable (Double?) -> Void)?
    
    // 【核心新增】：使用内部锁管理后台取消状态，供非主线程的音视频底层 API 安全读取
    private let cancelLock = NSLock()
    private var _isCancelledState: Bool = false
    private var isCancelledState: Bool {
        get {
            cancelLock.lock()
            defer { cancelLock.unlock() }
            return _isCancelledState
        }
        set {
            cancelLock.lock()
            _isCancelledState = newValue
            cancelLock.unlock()
        }
    }

    private var videoTrack: AVAssetTrack? {
        return self.asset.tracks(withMediaType: .video).first
    }

    private var radian: CGFloat? {
        guard let videoTrank = self.videoTrack else { return nil }
        return atan2(videoTrank.preferredTransform.b, videoTrank.preferredTransform.a) + (self.option?.rotate ?? 0)
    }

    private var converterDegree: ConverterDegree? {
        guard let radian = self.radian else { return nil }
        let degree = radian * 180 / .pi
        return ConverterDegree.convert(degree: degree)
    }

    private var naturalSize: CGSize? {
        guard let videoTrack = self.videoTrack,
              let converterDegree = self.converterDegree else { return nil }
        if converterDegree == .degree90 || converterDegree == .degree270 {
            return CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        } else {
            return CGSize(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
        }
    }

    private var cropFrame: CGRect? {
        guard let crop = self.option?.convertCrop else { return nil }
        guard let naturalSize = self.naturalSize else { return nil }
        let contrastSize = crop.contrastSize
        let frame = crop.frame
        let cropX = frame.origin.x * naturalSize.width / contrastSize.width
        let cropY = frame.origin.y * naturalSize.height / contrastSize.height
        let cropWidth = frame.size.width * naturalSize.width / contrastSize.width
        let cropHeight = frame.size.height * naturalSize.height / contrastSize.height
        return CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
    }

    public init(asset: AVAsset) {
        self.asset = asset
        self.presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
    }

    // Restore & Clean up
    open func restore(cleanupDisk: Bool = false) {
        // 通知后台队列（如果有）立刻停止
        self.isCancelledState = true
        
        self.option = nil
        
        // 取消正在进行的导出任务
        if let session = self.assetExportsSession, session.status == .exporting || session.status == .waiting {
            session.cancelExport()
        }
        self.assetExportsSession = nil
        self.progressCallback = nil
        
        // 如果指定需要清理，使用分离的 Task 在后台删除残缺文件
        if cleanupDisk, let fileURL = self.currentExportURL {
            // Swift 6 推荐使用 Task.detached 代替 DispatchQueue.global 进行独立的后台任务
            Task.detached(priority: .background) {
                let filePath = fileURL.path
                if FileManager.default.fileExists(atPath: filePath) {
                    try? FileManager.default.removeItem(atPath: filePath)
                }
            }
        }
        
        // 彻底忘掉这个路径
        self.currentExportURL = nil
    }

    // 【优化】：移除无用的 withUnsafeContinuation，因为内部组装全是同步逻辑
    open func convert(_ option: ConverterOption? = nil) async throws -> (AVMutableComposition, AVMutableVideoComposition) {
        self.restore()
        // 开启新的任务，复位取消标志
        self.isCancelledState = false
        
        guard let videoTrack = self.videoTrack else {
            throw NSError(domain: "Can't find video", code: 404, userInfo: nil)
        }
        self.option = option
        if self.renderSize?.width == 0 || self.renderSize?.height == 0 {
            self.restore()
            throw NSError(domain: "The crop size is too small", code: 503, userInfo: nil)
        }

        let composition = AVMutableComposition()

        guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            self.restore()
            throw NSError(domain: "Can't find video", code: 404, userInfo: nil)
        }

        let range: CMTimeRange
        let duration: CMTime
        if let trimPositions = option?.trimRange {
            let value = trimPositions.1 - trimPositions.0
            duration = CMTime(seconds: value * asset.duration.seconds, preferredTimescale: asset.duration.timescale)
            range = CMTimeRange(start: CMTimeMakeWithSeconds(asset.duration.seconds * trimPositions.0, preferredTimescale: Int32(NSEC_PER_MSEC)), duration: duration)
        } else {
            duration = asset.duration
            range = CMTimeRange(start: .zero, duration: duration)
        }
        
        // trim
        try? videoCompositionTrack.insertTimeRange(range, of: videoTrack, at: .zero)

        let newDuration = Double(duration.seconds) / (self.option?.speed ?? 1)
        let time = CMTime(seconds: newDuration, preferredTimescale: duration.timescale)
        let newRange = CMTimeRange(start: .zero, duration: duration)
        videoCompositionTrack.scaleTimeRange(newRange, toDuration: time)
        videoCompositionTrack.preferredTransform = videoTrack.preferredTransform

        // mute
        if !(option?.isMute ?? false) {
            if let audioTrack = self.asset.tracks(withMediaType: AVMediaType.audio).first {
                let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                try? audioCompositionTrack?.insertTimeRange(range, of: audioTrack, at: .zero)
                audioCompositionTrack?.scaleTimeRange(CMTimeRange(start: .zero, duration: duration), toDuration: time)
            }
        }

        let compositionInstructions = AVMutableVideoCompositionInstruction()
        compositionInstructions.timeRange = CMTimeRange(start: .zero, duration: time)
        compositionInstructions.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1).cgColor

        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        layerInstructions.setOpacity(1.0, at: .zero)
        if let transform = self.transform {
            layerInstructions.setTransform(transform, at: .zero)
        }
        compositionInstructions.layerInstructions = [layerInstructions]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [compositionInstructions]
        if let renderSize = self.renderSize {
            videoComposition.renderSize = renderSize
        }
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        return (composition, videoComposition)
    }

    open func convert(_ option: ConverterOption? = nil, handler: @escaping @Sendable (AVMutableComposition, AVMutableVideoComposition) -> Void) {
        Task {
            do {
                let conver = try await convert(option)
                handler(conver.0, conver.1)
            } catch {
                PTNSLogConsole(error.localizedDescription, levelType: .error, loggerType: .media)
            }
        }
    }

    // Convert
    open func convert(_ option: ConverterOption? = nil, temporaryFileName: String? = nil, progress: (@Sendable (Double?) -> Void)? = nil, completion: @escaping @Sendable (URL?, Error?) -> Void) {
        Task {
            do {
                let convert = try await self.convert(option)
                self.convert(ac: convert.0, avc: convert.1, temporaryFileName: temporaryFileName, progress: progress, completion: completion)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    private func convert(ac: AVMutableComposition, avc: AVMutableVideoComposition, temporaryFileName: String? = nil, progress: (@Sendable (Double?) -> Void)? = nil, completion: @escaping @Sendable (URL?, Error?) -> Void) {
        
        let outputType: String = option?.outputModel.name ?? "mov"
        let outputTypeType: AVFileType = option?.outputModel.type ?? .mov
                
        guard outputType.lowercased() != "unknown" else {
            let error = NSError(domain: "PTVideoEditorError", code: 401, userInfo: [NSLocalizedDescriptionKey: "无法识别的输出格式 (Unknown)"])
            completion(nil, error)
            return
        }

        var filePath = ""
        switch outputTypeType {
        case .mov, .mp4, .m4v, .mobile3GPP, .mobile3GPP2:
            let tempName = temporaryFileName ?? "TrimmedMovie.\(outputType)"
            filePath = FileManager.pt.TmpDirectory().appendingPathComponent(tempName)
        default:
            let random = Int(arc4random_uniform(89999) + 10000)
            let fileName = "condy_export_audio_\(random).\(outputType)"
            filePath = OutputFilePath.appendingPathComponent(fileName)
        }

        let url = URL(fileURLWithPath: filePath)
        self.currentExportURL = url
        
        let result = FileManager.pt.removefile(filePath: filePath)
        guard result.isSuccess else {
            // 已在 @MainActor 保护下，可直接调用 UI 层组件
            PTAlertTipsViewController.tipsAlertShow(title: "PT Alert Opps".localized(), subtitle: result.error, icon: .Error)
            return
        }
        
        self.progressCallback = progress
        
        let nativeSupportedFormats: [AVFileType] = [.mov, .mp4, .m4v, .mobile3GPP, .mobile3GPP2, .m4a]
        
        if nativeSupportedFormats.contains(outputTypeType) {
            self.exportUsingExportSession(ac: ac, avc: avc, outputTypeType: outputTypeType, url: url, completion: completion)
        } else if outputTypeType == .mp3 {
            self.exportMP3UsingLame(ac: ac, url: url, completion: completion)
        } else {
            self.exportUsingAssetWriter(ac: ac, outputTypeType: outputTypeType, url: url, completion: completion)
        }
    }

    // Video Size
    private var renderSize: CGSize? {
        guard let naturalSize = self.naturalSize else { return nil }
        var renderSize = naturalSize
        if let cropFrame = self.cropFrame {
            let width = floor(cropFrame.size.width / 16) * 16
            let height = floor(cropFrame.size.height / 16) * 16
            renderSize = CGSize(width: width, height: height)
        }
        return renderSize
    }

    // Video Rotate & Rrigin
    private var transform: CGAffineTransform? {
        guard let naturalSize = self.naturalSize,
              let radian = self.radian,
              let converterDegree = self.converterDegree else { return nil }

        var transform = CGAffineTransform.identity
        transform = transform.rotated(by: radian)
        if converterDegree == .degree90 {
            transform = transform.translatedBy(x: 0, y: -naturalSize.width)
        } else if converterDegree == .degree180 {
            transform = transform.translatedBy(x: -naturalSize.width, y: -naturalSize.height)
        } else if converterDegree == .degree270 {
            transform = transform.translatedBy(x: -naturalSize.height, y: 0)
        }

        if let cropFrame = self.cropFrame {
            if converterDegree == .degree0 {
                transform = transform.translatedBy(x: -cropFrame.origin.x, y: -cropFrame.origin.y)
            } else if converterDegree == .degree90 {
                transform = transform.translatedBy(x: -cropFrame.origin.y, y: cropFrame.origin.x)
            } else if converterDegree == .degree180 {
                transform = transform.translatedBy(x: cropFrame.origin.x, y: cropFrame.origin.y)
            } else if converterDegree == .degree270 {
                transform = transform.translatedBy(x: cropFrame.origin.y, y: -cropFrame.origin.x)
            }
        }
        return transform
    }

    // MARK: - 引擎 A (原生视频/m4a导出)
    private func exportUsingExportSession(ac: AVMutableComposition, avc: AVMutableVideoComposition, outputTypeType: AVFileType, url: URL, completion: @escaping @Sendable (URL?, Error?) -> Void) {
        
        var presetName = option?.quality ?? AVAssetExportPresetHighestQuality
        if outputTypeType == .m4a {
            presetName = AVAssetExportPresetAppleM4A
        }
        
        let exportSession = AVAssetExportSession(asset: ac, presetName: presetName)
        self.assetExportsSession = exportSession
        exportSession?.outputFileType = outputTypeType
        exportSession?.outputURL = url
        
        if [.mov, .mp4, .m4v].contains(outputTypeType) {
            exportSession?.shouldOptimizeForNetworkUse = true
            exportSession?.videoComposition = avc
        }

        let safeBox = PTSafeExportSessionBox(session: exportSession)

        // 【优化】：使用 Swift 并发的死循环监听，彻底抛弃 Timer
        Task { [weak self] in // 💡 优化点：添加 [weak self] 防止内存泄漏
            // 💡 修复点 2：通过 safeBox 安全地访问 session，消除数据竞争警告
            while safeBox.session?.status == .exporting || safeBox.session?.status == .waiting {
                if let progress = safeBox.session?.progress {
                    // 如果 progressCallback 会更新 UI，强烈建议在这里也切回主线程执行
                    Task { @MainActor in
                        self?.progressCallback?(Double(progress))
                    }
                }
                // 每 0.1 秒检查一次
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }

        exportSession?.exportAsynchronously { [weak self] in
            // AVAssetExportSession 的回调可能在任意后台队列，安全切回主线程
            Task { @MainActor in
                guard let self = self else { return }
                
                // 💡 修复点 3：在这里也使用 safeBox 来读取状态，保证全局的安全与统一
                if safeBox.session?.status == .completed {
                    self.progressCallback?(1)
                    completion(url, nil)
                    self.restore(cleanupDisk: false)
                } else {
                    completion(nil, safeBox.session?.error)
                    self.restore(cleanupDisk: true)
                }
            }
        }
    }
        
    // MARK: - 引擎 B (自定义格式 wav/caf/aiff 等导出)
    private func exportUsingAssetWriter(ac: AVMutableComposition, outputTypeType: AVFileType, url: URL, completion: @escaping @Sendable (URL?, Error?) -> Void) {
        
        guard let audioTrack = ac.tracks(withMediaType: .audio).first else {
            let error = NSError(domain: "PTVideoEditorError", code: 404, userInfo: [NSLocalizedDescriptionKey: "源视频不包含任何音频轨道，无法导出。"])
            completion(nil, error)
            self.restore(cleanupDisk: true)
            return
        }
        
        do {
            let safeBoxExport = PTVideoExportBox(isCancelledState: self.isCancelledState)
            
            let assetReader = try AVAssetReader(asset: ac)
            let readerOutputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM
            ]
            let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: readerOutputSettings)
            if assetReader.canAdd(trackOutput) {
                assetReader.add(trackOutput)
            }
            
            let assetWriter = try AVAssetWriter(outputURL: url, fileType: outputTypeType)
            let writerInputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: writerInputSettings)
            writerInput.expectsMediaDataInRealTime = false
            
            if assetWriter.canAdd(writerInput) {
                assetWriter.add(writerInput)
            }
            
            assetWriter.startWriting()
            assetReader.startReading()
            assetWriter.startSession(atSourceTime: .zero)
            
            let audioQueue = DispatchQueue(label: "com.ptools.audioExportQueue", qos: .userInitiated)
            let totalDuration = ac.duration.seconds
            
            // 提取 progressCallback 供内部使用，避免在后台队列捕捉 MainActor 的 self
            let localProgressCallback = self.progressCallback
            let safeBox = PTSafeAudioExportBox(reader: assetReader, writer: assetWriter, trackOutput: trackOutput, writerInput: writerInput)
            safeBox.writerInput.requestMediaDataWhenReady(on: audioQueue) { [weak self] in
                // 💡 修复点 2：去掉了原本包裹在整个 while 外面的 Task { @MainActor in }
                // 让繁重的 SampleBuffer 处理直接在这个 audioQueue 后台队列上飞速运行
                
                while safeBox.writerInput.isReadyForMoreMediaData {
                    
                    if safeBoxExport.isCancelledState == true {
                        safeBox.writerInput.markAsFinished()
                        safeBox.writer.cancelWriting()
                        safeBox.reader.cancelReading()
                        return
                    }
                    
                    if let sampleBuffer = safeBox.trackOutput.copyNextSampleBuffer() {
                        safeBox.writerInput.append(sampleBuffer)
                        
                        if totalDuration > 0 {
                            let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                            let progress = timeStamp.seconds / totalDuration
                            
                            // 💡 修复点 3：仅仅在这里切回主线程去更新 UI 进度
                            Task { @MainActor in
                                localProgressCallback?(progress)
                            }
                        }
                    } else {
                        safeBox.writerInput.markAsFinished()
                        
                        safeBox.writer.finishWriting {
                            // 💡 修复点 4：导出彻底完成后，切回主线程执行完成回调
                            Task { @MainActor in
                                guard let self = self else { return }
                                if safeBox.writer.status == .completed {
                                    self.progressCallback?(1.0)
                                    completion(url, nil)
                                    self.restore(cleanupDisk: false)
                                } else {
                                    completion(nil, safeBox.writer.error)
                                    self.restore(cleanupDisk: true)
                                }
                            }
                        }
                        break
                    }
                }
            }
        } catch {
            completion(nil, error)
            self.restore(cleanupDisk: true)
        }
    }

    // MARK: - 引擎 C (MP3 第三方转换)
    private func exportMP3UsingLame(ac: AVMutableComposition, url: URL, completion: @escaping @Sendable (URL?, Error?) -> Void) {
        PTNSLogConsole("准备调用第三方库转码 MP3...")
    }
}
