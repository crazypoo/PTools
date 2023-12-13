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

    // Restore
    open func restore() {
        self.option = nil
        self.assetExportsSession?.cancelExport()
        self.assetExportsSession = nil
        self.timer?.invalidate()
        self.timer = nil
        self.progressCallback = nil
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
                }
            }

            let compositionInstructions = AVMutableVideoCompositionInstruction()
            compositionInstructions.timeRange = CMTimeRange(start: .zero, duration: self.asset.duration)
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
                PTNSLogConsole(error.localizedDescription)
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
    
    func convert(ac:AVMutableComposition,avc:AVMutableVideoComposition,temporaryFileName: String? = nil, progress: ((Double?) -> Void)? = nil, completion: @escaping ((URL?, Error?) -> Void)) {
        let temporaryFileName = temporaryFileName ?? "TrimmedMovie.mp4"
        let filePath = FileManager.pt.TmpDirectory().appendingPathComponent(temporaryFileName)
        let url = URL(fileURLWithPath: filePath)
        
        let result = FileManager.pt.removefile(filePath: filePath)
        if result.isSuccess {
            self.progressCallback = progress
            // progress timer
            PTGCDManager.gcdMain {
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (time) in
                    if let progress = self?.assetExportsSession?.progress {
                        self?.progressCallback?(Double(progress))
                        if progress >= 1 {
                            self?.timer?.invalidate()
                            self?.timer = nil
                        }
                    } else if self?.assetExportsSession == nil {
                        self?.timer?.invalidate()
                        self?.timer = nil
                    }
                }
            }
            
            let presetName = option?.quality ?? AVAssetExportPresetHighestQuality
            self.assetExportsSession = AVAssetExportSession(asset: ac, presetName: presetName)
            self.assetExportsSession?.outputFileType = AVFileType.mp4
            self.assetExportsSession?.shouldOptimizeForNetworkUse = true
            self.assetExportsSession?.videoComposition = avc
            self.assetExportsSession?.outputURL = url
            
            //        PTNSLogConsole("\(ac)\n\(avc)")
            self.assetExportsSession?.exportAsynchronously {
                self.timer?.invalidate()
                self.timer = nil
                PTGCDManager.gcdMain {
                    self.progressCallback?(1)
                    self.progressCallback = nil
                    if let url = self.assetExportsSession?.outputURL, self.assetExportsSession?.status == .completed {
                        completion(url, nil)
                    } else {
                        completion(nil, self.assetExportsSession?.error)
                    }
                    self.restore()
                }
            }
        } else {
            PTAlertTipControl.present(title:"",subtitle:result.error,icon:.Error,style: .Normal)
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
}
