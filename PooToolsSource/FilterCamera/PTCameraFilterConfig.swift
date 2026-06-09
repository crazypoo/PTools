//
//  PTFilterCinfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import SafeSFSymbols

extension NSError {
    convenience init(message: String) {
        let userInfo = [NSLocalizedDescriptionKey: message]
        self.init(domain: "com.PTCameraFilter.error", code: -1, userInfo: userInfo)
    }
}

extension NSError {
    static let videoMergeError = NSError(message: "video merge failed")
    
    static let videoExportTypeError = NSError(message: "The mediaType of asset must be video")
    
    static let videoExportError = NSError(message: "Video export failed")
    
    static let assetSaveError = NSError(message: "Asset save failed")
    
    static let timeoutError = NSError(message: "timeout")
}

@MainActor
public class PTCameraFilterConfig: NSObject {
    
    public static let share = PTCameraFilterConfig()

    public typealias Second = Int

    private var pri_minRecordDuration: PTCameraFilterConfig.Second = 1
    /// Minimum recording duration. Defaults to 0.
    public var minRecordDuration: PTCameraFilterConfig.Second {
        get {
            pri_minRecordDuration
        }
        set {
            pri_minRecordDuration = max(0, newValue)
        }
    }
    
    private var pri_maxRecordDuration: PTCameraFilterConfig.Second = 20
    /// Maximum recording duration. Defaults to 20, minimum is 1.
    public var maxRecordDuration: PTCameraFilterConfig.Second {
        get {
            pri_maxRecordDuration
        }
        set {
            pri_maxRecordDuration = max(1, newValue)
        }
    }

    /// Video export format for recording video and editing video. Defaults to mov.
    public var videoExportType: PTCameraFilterConfig.VideoExportType = .mov
    @objc public enum VideoExportType: Int {
        var format: String {
            switch self {
            case .mov:
                return "mov"
            case .mp4:
                return "mp4"
            }
        }
        
        var avFileType: AVFileType {
            switch self {
            case .mov:
                return .mov
            case .mp4:
                return .mp4
            }
        }
        
        case mov
        case mp4
    }
    
    @discardableResult
    func minRecordDuration(_ duration: PTCameraFilterConfig.Second) -> PTCameraFilterConfig {
        minRecordDuration = duration
        return self
    }
    
    @discardableResult
    func maxRecordDuration(_ duration: PTCameraFilterConfig.Second) -> PTCameraFilterConfig {
        maxRecordDuration = duration
        return self
    }

    @discardableResult
    func videoExportType(_ type: PTCameraFilterConfig.VideoExportType) -> PTCameraFilterConfig {
        videoExportType = type
        return self
    }
        
    @discardableResult
    func videoCodecType(_ type: AVVideoCodecType) -> PTCameraFilterConfig {
        videoCodecType = type
        return self
    }

    class func getVideoExportFilePath(format: String? = nil) -> String {
        let format = format ?? PTCameraFilterConfig.share.videoExportType.format
        return NSTemporaryDirectory().appendingFormat("%@.%@", UUID().uuidString, format)
    }
    
    private var pri_videoCodecType: Any?
    /// The codecs for video capture. Defaults to .h264
    public var videoCodecType: AVVideoCodecType {
        get {
            (pri_videoCodecType as? AVVideoCodecType) ?? .h264
        }
        set {
            pri_videoCodecType = newValue
        }
    }

    /// Animation duration for select button. Defaults to 0.5.
    public var selectBtnAnimationDuration: CFTimeInterval = 0.5
    
    /// Camera focus mode. Defaults to continuousAutoFocus
    public var focusMode: PTCameraFilterConfig.FocusMode = .continuousAutoFocus
    @objc public enum FocusMode: Int {
        var avFocusMode: AVCaptureDevice.FocusMode {
            switch self {
            case .autoFocus:
                return .autoFocus
            case .continuousAutoFocus:
                return .continuousAutoFocus
            }
        }
        
        case autoFocus
        case continuousAutoFocus
    }
    
    /// Camera exposure mode. Defaults to continuousAutoExposure
    public var exposureMode: PTCameraFilterConfig.ExposureMode = .continuousAutoExposure
    @objc public enum ExposureMode: Int {
        var avFocusMode: AVCaptureDevice.ExposureMode {
            switch self {
            case .autoExpose:
                return .autoExpose
            case .continuousAutoExposure:
                return .continuousAutoExposure
            }
        }
        
        case autoExpose
        case continuousAutoExposure
    }
    
    @discardableResult
    func focusMode(_ mode: PTCameraFilterConfig.FocusMode) -> PTCameraFilterConfig {
        focusMode = mode
        return self
    }
    
    @discardableResult
    func exposureMode(_ mode: PTCameraFilterConfig.ExposureMode) -> PTCameraFilterConfig {
        exposureMode = mode
        return self
    }
    
    open var onlyCamera:Bool = false

    ///转换摄像头
    open var focusImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))

    ///转换摄像头
    open var switchCameraImage:UIImage = UIImage(.camera)
    open var switchCameraImageSelected:UIImage = UIImage(.camera.fill)

    ///電筒圖片
    open var flashImage:UIImage = UIImage(.flashlight.offFill)
    open var flashImageSelected:UIImage = UIImage(.flashlight.onFill)

    open var backImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20))
    ///Filters
    open var filtersImage:UIImage = UIImage(.square.andArrowUp)
    open var filtersImageSelected:UIImage = UIImage(.square.andArrowUpFill)

    open var reloadCameraImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    open var outputVideImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    open var recordingLineColor:DynamicColor = .randomColor
    
    open var reviewImageBack:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20))
    open var reviewImageUse:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 20))
    open var reviewImageEdit:UIImage = UIImage(.pencil)

    private var pri_filters: [PTHarBethFilter] = [.none,.storyboard,.comicstrip,.oilpainting,.sketch]
    /// Filters for image editor.
    public var filters: [PTHarBethFilter] {
        get {
            if pri_filters.isEmpty {
                return [.storyboard,.comicstrip,.oilpainting,.sketch]
            } else {
                return pri_filters
            }
        }
        set {
            pri_filters = newValue
        }
    }
    
    private var pri_allowTakePhoto = true
    /// Allow taking photos in the camera (Need allowSelectImage to be true). Defaults to true.
    public var allowTakePhoto: Bool {
        get {
            pri_allowTakePhoto
        }
        set {
            pri_allowTakePhoto = newValue
        }
    }
    
    private var pri_allowRecordVideo = true
    /// Allow recording in the camera (Need allowSelectVideo to be true). Defaults to true.
    public var allowRecordVideo: Bool {
        get {
            pri_allowRecordVideo
        }
        set {
            pri_allowRecordVideo = newValue
        }
    }
    
    /// 没有针对不同分辨率视频做处理，仅用于处理相机拍照的视频
    @objc public class func mergeVideos(fileUrls: [URL], completion: @escaping @Sendable (URL?, Error?) -> Void) {
        // 🌟 1. 开启异步任务，把所有耗时操作放进后台执行
        Task {
            do {
                let composition = AVMutableComposition()
                let assets = fileUrls.map { AVURLAsset(url: $0) }
                
                var insertTime: CMTime = .zero
                var assetVideoTracks: [AVAssetTrack] = []
                
                // 使用 kCMPersistentTrackID_Invalid 是苹果推荐的做法，让系统自动分配 TrackID
                guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                      let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                    // 如果无法创建轨道，直接返回错误
                    completion(nil, NSError.videoMergeError) // 假设 NSError.videoMergeError 已在你的代码中定义
                    return
                }
                
                for asset in assets {
                    // 🌟 2. 异步获取视频时长和轨道
                    let duration = try await asset.load(.duration)
                    let timeRange = CMTimeRangeMake(start: .zero, duration: duration)
                    
                    let videoTracks = try await asset.loadTracks(withMediaType: .video)
                    if let videoTrack = videoTracks.first {
                        try compositionVideoTrack.insertTimeRange(
                            timeRange,
                            of: videoTrack,
                            at: insertTime
                        )
                        assetVideoTracks.append(videoTrack)
                    }
                    
                    let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                    if let audioTrack = audioTracks.first {
                        try compositionAudioTrack.insertTimeRange(
                            timeRange,
                            of: audioTrack,
                            at: insertTime
                        )
                    }
                    
                    insertTime = CMTimeAdd(insertTime, duration)
                }
                
                guard assetVideoTracks.count == assets.count, let firstVideoTrack = assetVideoTracks.first else {
                    completion(nil, NSError.videoMergeError)
                    return
                }
                
                // 🌟 3. 异步获取首个视频轨道的尺寸、帧率和矩阵
                let firstNaturalSize = try await firstVideoTrack.load(.naturalSize)
                let firstTransform = try await firstVideoTrack.load(.preferredTransform)
                let minFrameDuration = try await firstVideoTrack.load(.minFrameDuration)
                
                let renderSize = getNaturalSize(naturalSize: firstNaturalSize, transform: firstTransform)
                
                let videoComposition = AVMutableVideoComposition()
                // 异步获取 Instructions
                videoComposition.instructions = try await getInstructions(compositionTrack: compositionVideoTrack, assetVideoTracks: assetVideoTracks, assets: assets)
                videoComposition.frameDuration = minFrameDuration
                videoComposition.renderSize = renderSize
                videoComposition.renderScale = 1
                
                guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset1280x720) else {
                    completion(nil, NSError.videoMergeError)
                    return
                }
                
                let outputUrl = URL(fileURLWithPath: PTCameraFilterConfig.getVideoExportFilePath())
                exportSession.outputURL = outputUrl
                exportSession.shouldOptimizeForNetworkUse = true
                exportSession.outputFileType = PTCameraFilterConfig.share.videoExportType.avFileType
                exportSession.videoComposition = videoComposition
                
                // 🌟 4. 异步导出
                await exportSession.export()
                
                let suc = exportSession.status == .completed
                if exportSession.status == .failed {
                    PTNSLogConsole("PTPhotoBrowser: video merge failed:  \(exportSession.error?.localizedDescription ?? "")", levelType: .error, loggerType: .filter)
                }
                completion(suc ? outputUrl : nil, exportSession.error)
                
            } catch {
                // 捕获任何 load 或 insert 抛出的错误
                completion(nil, error)
            }
        }
    }

    // 🌟 辅助方法改造：直接接收已经异步解析好的值，不做重复的耗时加载
    private static func getNaturalSize(naturalSize: CGSize, transform: CGAffineTransform) -> CGSize {
        var size = naturalSize
        if isPortraitVideoTrack(transform) {
            swap(&size.width, &size.height)
        }
        return size
    }

    // 🌟 将内部的遍历改成 async 方式
    private static func getInstructions(compositionTrack: AVMutableCompositionTrack, assetVideoTracks: [AVAssetTrack], assets: [AVURLAsset]) async throws -> [AVMutableVideoCompositionInstruction] {
        var instructions: [AVMutableVideoCompositionInstruction] = []
        
        var start: CMTime = .zero
        for (index, videoTrack) in assetVideoTracks.enumerated() {
            let asset = assets[index]
            
            // 异步获取每次遍历所需的属性
            let duration = try await asset.load(.duration)
            let transform = try await videoTrack.load(.preferredTransform)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
            layerInstruction.setTransform(transform, at: .zero)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(start: start, duration: duration)
            instruction.layerInstructions = [layerInstruction]
            instructions.append(instruction)
            
            start = CMTimeAdd(start, duration)
        }
        
        return instructions
    }

    // 🌟 直接接收 transform 矩阵，而不是传入整个 track 再去解析
    private static func isPortraitVideoTrack(_ transform: CGAffineTransform) -> Bool {
        let tfA = transform.a
        let tfB = transform.b
        let tfC = transform.c
        let tfD = transform.d
        
        // Define patterns for each rotation case
        let patterns: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0, 1, -1, 0),
            (0, 1, 1, 0),
            (0, -1, 1, 0)
        ]
        
        // Check if the transform matches any of the patterns
        for pattern in patterns {
            if tfA == pattern.0 && tfB == pattern.1 && tfC == pattern.2 && tfD == pattern.3 {
                return true
            }
        }
        
        return false
    }
}
