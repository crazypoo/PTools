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
    public var presets: [String] = []

    public var option: ConverterOption?

    private var assetExportsSession: AVAssetExportSession?
    
    // 💡 优化点：完全删除了 PTSafeExportSessionBox！因为 iOS 16+ 有原生异步方法了
    
    private struct PTSafeAudioExportBox: @unchecked Sendable {
        let reader: AVAssetReader
        let writer: AVAssetWriter
        let trackOutput: AVAssetReaderTrackOutput
        let writerInput: AVAssetWriterInput
    }
    
    // 进度回调，标记为 @Sendable 以允许跨线程安全传递
    private var progressCallback: (@Sendable (Double?) -> Void)?
    
    // 内部锁管理后台取消状态，供非主线程的音视频底层 API 安全读取
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

    // MARK: - 🌟 异步属性链 (Async Contagion) 完美适配
    
    private var videoTrack: AVAssetTrack? {
        get async {
            let tracks = try? await self.asset.loadTracks(withMediaType: .video)
            return tracks?.first
        }
    }

    private var radian: CGFloat? {
        get async {
            guard let videoTrack = await self.videoTrack else { return nil }
            // 🌟 物理矩阵也是废弃的同步属性，必须异步 load
            guard let transform = try? await videoTrack.load(.preferredTransform) else { return nil }
            return atan2(transform.b, transform.a) + (self.option?.rotate ?? 0)
        }
    }

    private var converterDegree: ConverterDegree? {
        get async {
            guard let radian = await self.radian else { return nil }
            let degree = radian * 180 / .pi
            return ConverterDegree.convert(degree: degree)
        }
    }

    private var naturalSize: CGSize? {
        get async {
            guard let videoTrack = await self.videoTrack,
                  let converterDegree = await self.converterDegree else {
                return nil
            }
            
            guard let size = try? await videoTrack.load(.naturalSize) else { return nil }
            
            if converterDegree == .degree90 || converterDegree == .degree270 {
                return CGSize(width: size.height, height: size.width)
            } else {
                return size
            }
        }
    }

    private var cropFrame: CGRect? {
        get async {
            guard let crop = self.option?.convertCrop else { return nil }
            guard let naturalSize = await self.naturalSize else { return nil }
            let contrastSize = crop.contrastSize
            let frame = crop.frame
            let cropX = frame.origin.x * naturalSize.width / contrastSize.width
            let cropY = frame.origin.y * naturalSize.height / contrastSize.height
            let cropWidth = frame.size.width * naturalSize.width / contrastSize.width
            let cropHeight = frame.size.height * naturalSize.height / contrastSize.height
            return CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        }
    }
    
    private var renderSize: CGSize? {
        get async {
            guard let naturalSize = await self.naturalSize else { return nil }
            var renderSize = naturalSize
            if let cropFrame = await self.cropFrame {
                let width = floor(cropFrame.size.width / 16) * 16
                let height = floor(cropFrame.size.height / 16) * 16
                renderSize = CGSize(width: width, height: height)
            }
            return renderSize
        }
    }

    private var transform: CGAffineTransform? {
        get async {
            guard let naturalSize = await self.naturalSize,
                  let radian = await self.radian,
                  let converterDegree = await self.converterDegree else { return nil }

            var transform = CGAffineTransform.identity
            transform = transform.rotated(by: radian)
            
            if converterDegree == .degree90 {
                transform = transform.translatedBy(x: 0, y: -naturalSize.width)
            } else if converterDegree == .degree180 {
                transform = transform.translatedBy(x: -naturalSize.width, y: -naturalSize.height)
            } else if converterDegree == .degree270 {
                transform = transform.translatedBy(x: -naturalSize.height, y: 0)
            }

            if let cropFrame = await self.cropFrame {
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
    }

    // MARK: - 初始化与清理
    
    public init(asset: AVAsset) async {
        self.asset = asset
        let allPresets = AVAssetExportSession.allExportPresets()
        
        struct UnsafeAssetBox: @unchecked Sendable {
            let safeAsset: AVAsset
        }
        let box = UnsafeAssetBox(safeAsset: asset)
        
        let compatiblePresets = await withTaskGroup(of: (String, Bool).self) { group in
            for preset in allPresets {
                group.addTask {
                    let isCompatible = await AVAssetExportSession.compatibility(
                        ofExportPreset: preset, with: box.safeAsset, outputFileType: nil)
                    return (preset, isCompatible)
                }
            }
            var validPresets: Set<String> = []
            for await (preset, isCompatible) in group {
                if isCompatible { validPresets.insert(preset) }
            }
            return allPresets.filter { validPresets.contains($0) }
        }
        self.presets = compatiblePresets
    }

    open func restore(cleanupDisk: Bool = false) {
        self.isCancelledState = true
        self.option = nil
        
        if let session = self.assetExportsSession, session.status == .exporting || session.status == .waiting {
            session.cancelExport()
        }
        self.assetExportsSession = nil
        self.progressCallback = nil
        
        if cleanupDisk, let fileURL = self.currentExportURL {
            Task.detached(priority: .background) {
                let filePath = fileURL.path
                if FileManager.default.fileExists(atPath: filePath) {
                    try? FileManager.default.removeItem(atPath: filePath)
                }
            }
        }
        self.currentExportURL = nil
    }

    // MARK: - 组装合成逻辑
    
    open func convert(_ option: ConverterOption? = nil) async throws -> (AVMutableComposition, AVMutableVideoComposition) {
        self.restore()
        self.isCancelledState = false
        self.option = option
        
        guard let videoTrack = await self.videoTrack else {
            throw NSError(domain: "Can't find video", code: 404, userInfo: nil)
        }
        
        // 🌟 并发获取需要的尺寸，避免单线程阻塞
        async let currentRenderSizeTask = self.renderSize
        async let currentTransformTask = self.transform
        
        let currentRenderSize = await currentRenderSizeTask
        let currentTransform = await currentTransformTask
        
        if currentRenderSize?.width == 0 || currentRenderSize?.height == 0 {
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
        
        // 🌟 时长也是底层的，必须 await
        let assetDuration = try await asset.load(.duration)
        
        if let trimPositions = option?.trimRange {
            let value = trimPositions.1 - trimPositions.0
            duration = CMTime(seconds: value * assetDuration.seconds, preferredTimescale: assetDuration.timescale)
            range = CMTimeRange(start: CMTimeMakeWithSeconds(assetDuration.seconds * trimPositions.0, preferredTimescale: Int32(NSEC_PER_MSEC)), duration: duration)
        } else {
            duration = assetDuration
            range = CMTimeRange(start: .zero, duration: duration)
        }
        
        try? videoCompositionTrack.insertTimeRange(range, of: videoTrack, at: .zero)

        let newDuration = Double(duration.seconds) / (self.option?.speed ?? 1)
        let time = CMTime(seconds: newDuration, preferredTimescale: duration.timescale)
        let newRange = CMTimeRange(start: .zero, duration: duration)
        videoCompositionTrack.scaleTimeRange(newRange, toDuration: time)
        
        // 🌟 PreferredTransform 也变成了 await
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        videoCompositionTrack.preferredTransform = preferredTransform

        if !(option?.isMute ?? false) {
            let audioTracks = try await self.asset.loadTracks(withMediaType: .audio)
            if let audioTrack = audioTracks.first {
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
        
        if let transform = currentTransform {
            layerInstructions.setTransform(transform, at: .zero)
        }
        compositionInstructions.layerInstructions = [layerInstructions]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [compositionInstructions]
        if let renderSize = currentRenderSize {
            videoComposition.renderSize = renderSize
        }
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        return (composition, videoComposition)
    }

    open func convert(_ option: ConverterOption? = nil, handler: @escaping @Sendable (AVMutableComposition, AVMutableVideoComposition) -> Void) {
        Task { @MainActor in
            do {
                let conver = try await convert(option)
                handler(conver.0, conver.1)
            } catch {
                PTNSLogConsole(error.localizedDescription, levelType: .error, loggerType: .media)
            }
        }
    }

    open func convert(_ option: ConverterOption? = nil, temporaryFileName: String? = nil, progress: (@Sendable (Double?) -> Void)? = nil, completion: @escaping @Sendable (URL?, Error?) -> Void) {
        Task { @MainActor in
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
            // 这里假设 OutputFilePath 是你全局定义的路径
            filePath = OutputFilePath.appendingPathComponent(fileName)
        }

        let url = URL(fileURLWithPath: filePath)
        self.currentExportURL = url
        
        let result = FileManager.pt.removefile(filePath: filePath)
        guard result.isSuccess else {
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
            Task {
                self.exportUsingAssetWriter(ac: ac, outputTypeType: outputTypeType, url: url, completion: completion)
            }
        }
    }

    // MARK: - 引擎 A (原生视频/m4a导出)
    private func exportUsingExportSession(ac: AVMutableComposition, avc: AVMutableVideoComposition, outputTypeType: AVFileType, url: URL, completion: @escaping @Sendable (URL?, Error?) -> Void) {
        
        var presetName = option?.quality ?? AVAssetExportPresetHighestQuality
        if outputTypeType == .m4a { presetName = AVAssetExportPresetAppleM4A }
        
        guard let exportSession = AVAssetExportSession(asset: ac, presetName: presetName) else {
            completion(nil, NSError(domain: "ExportError", code: 500, userInfo: nil))
            return
        }
        
        self.assetExportsSession = exportSession
        exportSession.outputFileType = outputTypeType
        exportSession.outputURL = url
        
        if [.mov, .mp4, .m4v].contains(outputTypeType) {
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.videoComposition = avc
        }

        // 🚀 终极改动：废弃丑陋的回调盒子，使用纯净的 Async/Await + 并发轮询
        Task { @MainActor in
            // 开启一个轮询子任务，专门向外播报进度
            let progressTask = Task { @MainActor in
                while exportSession.status == .exporting || exportSession.status == .waiting {
                    self.progressCallback?(Double(exportSession.progress))
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
            
            // 核心原生异步导出方法
            await exportSession.export()
            
            // 导出结束，取消轮询
            progressTask.cancel()
            
            if exportSession.status == .completed {
                self.progressCallback?(1.0)
                completion(url, nil)
                self.restore(cleanupDisk: false)
            } else {
                completion(nil, exportSession.error)
                self.restore(cleanupDisk: true)
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
                            Task { @MainActor  in
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
