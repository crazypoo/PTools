//
//  VideoConverter.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVKit

open class VideoConverter {
    // 新增：记录当前正在导出的目标路径，用于失败/取消时的安全清理
    private var currentExportURL: URL?

    public let asset: AVAsset
    public let presets: [String]

    public var option: ConverterOption?

    private var assetExportsSession: AVAssetExportSession?
    private var timer: Timer?

    private var progressCallback: ((Double?) -> Void)?

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
        let cropFrame = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        return cropFrame
    }

    public init(asset: AVAsset) {
        self.asset = asset
        self.presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
    }

    // Restore & Clean up
    open func restore(cleanupDisk: Bool = false) {
        self.option = nil
        
        // 取消正在进行的导出任务
        if let session = self.assetExportsSession, session.status == .exporting || session.status == .waiting {
            session.cancelExport()
        }
        self.assetExportsSession = nil
        
        self.timer?.invalidate()
        self.timer = nil
        self.progressCallback = nil
        
        // 如果指定需要清理，立即删除残缺文件释放用户存储空间
        if cleanupDisk, let fileURL = self.currentExportURL {
            PTGCDManager.gcdBackground {
                let filePath = fileURL.path
                if FileManager.default.fileExists(atPath: filePath) {
                    do {
                        try FileManager.default.removeItem(atPath: filePath)
                    } catch {
                        // 清理失败可以忽略
                    }
                }
            }
        }
        
        // 【极其关键的修复】：将 currentExportURL 的置空操作移到外部！
        // 无论刚才是否删除了文件，只要任务归零，就彻底忘掉这个路径。
        // 这样即使后续页面触发 deinit(cleanupDisk: true)，也绝对不会误删已经成功导出的视频。
        self.currentExportURL = nil
    }

    open func convert(_ option: ConverterOption? = nil) async throws -> (AVMutableComposition,AVMutableVideoComposition) {
        await withUnsafeContinuation { continuation in
            self.restore()
            guard let videoTrack = self.videoTrack else {
                continuation.resume(throwing: NSError(domain: "Can't find video", code: 404, userInfo: nil) as! Never)
                return
            }
            self.option = option
            if self.renderSize?.width == 0 || self.renderSize?.height == 0 {
                self.restore()
                continuation.resume(throwing: NSError(domain: "The crop size is too small", code: 503, userInfo: nil) as! Never)
                return
            }

            let composition = AVMutableComposition()

            guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                self.restore()
                continuation.resume(throwing: NSError(domain: "Can't find video", code: 404, userInfo: nil) as! Never)
                return
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
                    // mute trim
                    try? audioCompositionTrack?.insertTimeRange(range, of: audioTrack, at: .zero)
                    audioCompositionTrack?.scaleTimeRange(CMTimeRange(start: .zero, duration: duration), toDuration: time)
                }
            }

            let compositionInstructions = AVMutableVideoCompositionInstruction()
            compositionInstructions.timeRange = CMTimeRange(start: .zero, duration: time)
            compositionInstructions.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1).cgColor

            let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
            // opacity
            layerInstructions.setOpacity(1.0, at: .zero)
            // transform
            if let transform = self.transform {
                layerInstructions.setTransform(transform, at: .zero)
            }
            compositionInstructions.layerInstructions = [layerInstructions]

            let videoComposition = AVMutableVideoComposition()
            videoComposition.instructions = [compositionInstructions]
            // size
            if let renderSize = self.renderSize {
                videoComposition.renderSize = renderSize
            }
            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
            continuation.resume(returning: (composition,videoComposition))
        }
    }

    open func convert(_ option: ConverterOption? = nil,handler:@escaping ((AVMutableComposition,AVMutableVideoComposition)->Void)) {
        
        Task.init {
            do {
                let conver = try await convert(option)
                handler(conver.0,conver.1)
            } catch {
                PTNSLogConsole(error.localizedDescription, levelType: .error,loggerType: .media)
            }
        }
    }

    // Convert
    open func convert(_ option: ConverterOption? = nil, temporaryFileName: String? = nil, progress: ((Double?) -> Void)? = nil, completion: @escaping ((URL?, Error?) -> Void)) {

        Task.init {
            do {
                let convert = try await self.convert(option)
                self.convert(ac: convert.0, avc: convert.1,progress: progress, completion: completion)
            } catch {
                completion(nil,(error.localizedDescription as! Error))
            }
        }
    }
    
    func convert(ac: AVMutableComposition, avc: AVMutableVideoComposition, temporaryFileName: String? = nil, progress: ((Double?) -> Void)? = nil, completion: @escaping ((URL?, Error?) -> Void)) {
        
        let outputType: String = option?.outputModel.name ?? "mov"
        let outputTypeType: AVFileType = option?.outputModel.type ?? .mov
                
        guard outputType.lowercased() != "unknown" else {
            PTGCDManager.gcdMain {
                let error = NSError(domain: "PTVideoEditorError", code: 401, userInfo: [NSLocalizedDescriptionKey: "无法识别的输出格式 (Unknown)"])
                completion(nil, error)
            }
            return
        }

        var filePath = ""
        switch outputTypeType {
        case .mov, .mp4, .m4v, .mobile3GPP, .mobile3GPP2:
            let temporaryFileName = temporaryFileName ?? "TrimmedMovie.\(outputType)"
            filePath = FileManager.pt.TmpDirectory().appendingPathComponent(temporaryFileName)
        default:
            let random = Int(arc4random_uniform(89999) + 10000)
            let fileName = "condy_export_audio_\(random).\(outputType)"
            filePath = OutputFilePath.appendingPathComponent(fileName)
        }

        let url = URL(fileURLWithPath: filePath)
        // 【优化点 1】：记录当前文件 URL
        self.currentExportURL = url
        
        let result = FileManager.pt.removefile(filePath: filePath)
        guard result.isSuccess else {
            Task { @MainActor in
                PTAlertTipsViewController.tipsAlertShow(title: "PT Alert Opps".localized(), subtitle: result.error, icon: .Error)
            }
            return
        }
        
        self.progressCallback = progress
        
        // 【核心升级】：双引擎智能路由
        let nativeSupportedFormats: [AVFileType] = [.mov, .mp4, .m4v, .mobile3GPP, .mobile3GPP2, .m4a]
        
        if nativeSupportedFormats.contains(outputTypeType) {
            // 引擎 A：走苹果原生硬件加速的 ExportSession
            self.exportUsingExportSession(ac: ac, avc: avc, outputTypeType: outputTypeType, url: url, completion: completion)
        } else if outputTypeType == .mp3 {
            // 引擎 C：走第三方 MP3 编码 (需集成 lame)
            self.exportMP3UsingLame(ac: ac, url: url, completion: completion)
        } else {
            // 引擎 B：走底层流媒体读写器 (支持 wav, caf, aiff 等)
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

    // Progress Time Timer
    @objc private func timerAction(_ sender: Timer) {
        if let progress = self.assetExportsSession?.progress {
            self.progressCallback?(Double(progress))
            if progress >= 1 {
                self.timer?.invalidate()
                self.timer = nil
            }
        } else if self.assetExportsSession == nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    // MARK: - 引擎 A (原生视频/m4a导出)
    private func exportUsingExportSession(ac: AVMutableComposition, avc: AVMutableVideoComposition, outputTypeType: AVFileType, url: URL, completion: @escaping ((URL?, Error?) -> Void)) {
        
        PTGCDManager.gcdMain {
            self.timer = Timer.scheduledTimer(timeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if let progress = self.assetExportsSession?.progress {
                    self.progressCallback?(Double(progress))
                }
            }
        }
        
        var presetName = option?.quality ?? AVAssetExportPresetHighestQuality
        if outputTypeType == .m4a {
            presetName = AVAssetExportPresetAppleM4A
        }
        
        self.assetExportsSession = AVAssetExportSession(asset: ac, presetName: presetName)
        self.assetExportsSession?.outputFileType = outputTypeType
        self.assetExportsSession?.outputURL = url
        
        if [.mov, .mp4, .m4v].contains(outputTypeType) {
            self.assetExportsSession?.shouldOptimizeForNetworkUse = true
            self.assetExportsSession?.videoComposition = avc
        }

        self.assetExportsSession?.exportAsynchronously { [weak self] in
            guard let self = self else { return }
            self.timer?.invalidate()
            self.timer = nil
            
            PTGCDManager.gcdMain {
                if self.assetExportsSession?.status == .completed {
                    self.progressCallback?(1)
                    completion(url, nil)
                    self.restore(cleanupDisk: false)
                } else {
                    completion(nil, self.assetExportsSession?.error)
                    self.restore(cleanupDisk: true)
                }
            }
        }
    }
    
    // MARK: - 引擎 B (自定义格式 wav/caf/aiff 等导出)
    private func exportUsingAssetWriter(ac: AVMutableComposition, outputTypeType: AVFileType, url: URL, completion: @escaping ((URL?, Error?) -> Void)) {
        
        // 1. 提取音频轨道
        guard let audioTrack = ac.tracks(withMediaType: .audio).first else {
            let error = NSError(domain: "PTVideoEditorError", code: 404, userInfo: [NSLocalizedDescriptionKey: "源视频不包含任何音频轨道，无法导出。"])
            PTGCDManager.gcdMain {
                completion(nil, error)
                self.restore(cleanupDisk: true)
            }
            return
        }
        
        do {
            // 2. 初始化读取器 (Reader) - 读取解压后的原始 PCM 数据
            let assetReader = try AVAssetReader(asset: ac)
            let readerOutputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM
            ]
            let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: readerOutputSettings)
            if assetReader.canAdd(trackOutput) {
                assetReader.add(trackOutput)
            }
            
            // 3. 初始化写入器 (Writer) - 将 PCM 封装为您选择的容器 (如 wav, caf)
            let assetWriter = try AVAssetWriter(outputURL: url, fileType: outputTypeType)
            
            // 配置标准 CD 音质参数 (44.1kHz, 16-bit, 立体声)
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
            
            // 4. 启动底层引擎
            assetWriter.startWriting()
            assetReader.startReading()
            assetWriter.startSession(atSourceTime: .zero)
            
            // 5. 创建专属音频处理队列 (脱离主线程)
            let audioQueue = DispatchQueue(label: "com.ptools.audioExportQueue", qos: .userInitiated)
            let totalDuration = ac.duration.seconds
            
            // 6. 开启异步数据传输流
            writerInput.requestMediaDataWhenReady(on: audioQueue) { [weak self] in
                guard let self = self else { return }
                
                // 循环注水：只要写入器准备好，并且任务未被取消 (self.option != nil)
                while writerInput.isReadyForMoreMediaData {
                    
                    // 【安全机制】：如果外部调用了 restore()，self.option 会变为 nil。立刻中断死循环。
                    guard self.option != nil else {
                        writerInput.markAsFinished()
                        assetWriter.cancelWriting()
                        assetReader.cancelReading()
                        // 内部取消不回调成功，外部已有 restore 逻辑处理
                        return
                    }
                    
                    if let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                        // 将提取到的音频帧写入目标文件
                        writerInput.append(sampleBuffer)
                        
                        // 进度计算与抛出
                        if totalDuration > 0 {
                            let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                            let progress = timeStamp.seconds / totalDuration
                            PTGCDManager.gcdMain {
                                self.progressCallback?(progress)
                            }
                        }
                    } else {
                        // 数据读取完毕，关闭阀门
                        writerInput.markAsFinished()
                        
                        assetWriter.finishWriting {
                            PTGCDManager.gcdMain {
                                if assetWriter.status == .completed {
                                    self.progressCallback?(1.0)
                                    completion(url, nil)
                                    self.restore(cleanupDisk: false)
                                } else {
                                    completion(nil, assetWriter.error)
                                    self.restore(cleanupDisk: true)
                                }
                            }
                        }
                        break // 任务完成，跳出循环
                    }
                }
            }
        } catch {
            // 初始化抛出异常时的安全处理
            PTGCDManager.gcdMain {
                completion(nil, error)
                self.restore(cleanupDisk: true)
            }
        }
    }

    // MARK: - 引擎 C (MP3 第三方转换)
    private func exportMP3UsingLame(ac: AVMutableComposition, url: URL, completion: @escaping ((URL?, Error?) -> Void)) {
        // iOS 原生无法写入 MP3。
        // 此处需要先将 ac 导出为临时的 .wav PCM 文件，然后再调用 LAME C++ 库进行硬编码转码。
        PTNSLogConsole("准备调用第三方库转码 MP3...")
    }
}
