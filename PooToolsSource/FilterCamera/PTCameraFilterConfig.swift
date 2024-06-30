//
//  PTFilterCinfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation

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

public class PTCameraFilterConfig: NSObject {
    
    public static let share = PTCameraFilterConfig()

    public typealias Second = Int

    private var pri_minRecordDuration: PTCameraFilterConfig.Second = 0
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
        
    @available(iOS 11.0, *)
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
    @available(iOS 11.0, *)
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

    ///转换摄像头
    open var focusImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))

    ///转换摄像头
    open var switchCameraImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    open var switchCameraImageSelected:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))

    ///電筒圖片
    open var flashImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    open var flashImageSelected:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))

    open var backImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))

    ///Filters
    open var filtersImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    open var filtersImageSelected:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))

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
    @objc public class func mergeVideos(fileUrls: [URL], completion: @escaping (URL?, Error?) -> Void) {
        let composition = AVMutableComposition()
        let assets = fileUrls.map { AVURLAsset(url: $0) }
        
        var insertTime: CMTime = .zero
        var assetVideoTracks: [AVAssetTrack] = []
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID())!
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID())!
        
        for asset in assets {
            do {
                let timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
                if let videoTrack = asset.tracks(withMediaType: .video).first {
                    try compositionVideoTrack.insertTimeRange(
                        timeRange,
                        of: videoTrack,
                        at: insertTime
                    )
                    
                    assetVideoTracks.append(videoTrack)
                }
                
                if let audioTrack = asset.tracks(withMediaType: .audio).first {
                    try compositionAudioTrack.insertTimeRange(
                        timeRange,
                        of: audioTrack,
                        at: insertTime
                    )
                }
                
                insertTime = CMTimeAdd(insertTime, asset.duration)
            } catch {
                completion(nil, NSError.videoMergeError)
                return
            }
        }
        
        guard assetVideoTracks.count == assets.count else {
            completion(nil, NSError.videoMergeError)
            return
        }
        
        let renderSize = getNaturalSize(videoTrack: assetVideoTracks[0])
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = getInstructions(compositionTrack: compositionVideoTrack, assetVideoTracks: assetVideoTracks, assets: assets)
        videoComposition.frameDuration = assetVideoTracks[0].minFrameDuration
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
        exportSession.exportAsynchronously(completionHandler: {
            let suc = exportSession.status == .completed
            if exportSession.status == .failed {
                PTNSLogConsole("ZLPhotoBrowser: video merge failed:  \(exportSession.error?.localizedDescription ?? "")",levelType: .Error,loggerType: .Filter)
            }
            PTGCDManager.gcdMain {
                completion(suc ? outputUrl : nil, exportSession.error)
            }
        })
    }
    
    private static func getNaturalSize(videoTrack: AVAssetTrack) -> CGSize {
        var size = videoTrack.naturalSize
        if isPortraitVideoTrack(videoTrack) {
            swap(&size.width, &size.height)
        }
        return size
    }
    
    private static func getInstructions(
        compositionTrack: AVMutableCompositionTrack,
        assetVideoTracks: [AVAssetTrack],
        assets: [AVURLAsset]
    ) -> [AVMutableVideoCompositionInstruction] {
        var instructions: [AVMutableVideoCompositionInstruction] = []
        
        var start: CMTime = .zero
        for (index, videoTrack) in assetVideoTracks.enumerated() {
            let asset = assets[index]
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
            layerInstruction.setTransform(videoTrack.preferredTransform, at: .zero)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(start: start, duration: asset.duration)
            instruction.layerInstructions = [layerInstruction]
            instructions.append(instruction)
            
            start = CMTimeAdd(start, asset.duration)
        }
        
        return instructions
    }
    
    private static func isPortraitVideoTrack(_ track: AVAssetTrack) -> Bool {
        let transform = track.preferredTransform
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
