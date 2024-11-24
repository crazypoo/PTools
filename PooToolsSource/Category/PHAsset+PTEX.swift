//
//  PHAsset+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Photos
import MobileCoreServices
import UIKit
import PhotosUI

extension PHAsset: PTProtocolCompatible {}

public extension PHAsset {
    // 使用 objc_Association 来存储 requestID
    private struct AssociatedKeys {
        static var requestID = 1
        static var exportSession = 2
        static var timer = 3

    }
    
    var requestID: PHImageRequestID? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.requestID) as? PHImageRequestID
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.requestID, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var exportSession: AVAssetExportSession? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.exportSession) as? AVAssetExportSession
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.exportSession, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var exportTimer: Timer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.timer) as? Timer
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.timer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func convertPHAssetToAVAsset(progressHandler: @escaping (Float) -> Void) async throws -> AVAsset? {
        await withUnsafeContinuation { continuation in
            self.convertPHAssetToAVAsset(progress: { progress in
                progressHandler(progress)
            }, completion: { avAsset in
                if avAsset != nil {
                    continuation.resume(returning: avAsset!)
                }
            })
        }
    }
    
    func convertPHAssetToAVAsset(progress:@escaping (Float)->Void,completion: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        
        // 请求 AVAssetExportSession
        PHImageManager.default().requestExportSession(forVideo: self, options: options, exportPreset: AVAssetExportPresetHighestQuality) { exportSession, info in
            guard let exportSession = exportSession else {
                PTNSLogConsole("导出会话创建失败")
                completion(nil)
                return
            }
            
            self.exportSession = exportSession
            var gotAvasset:AVAsset?
            self.createAVAssetFromExportSession() { asset in
                gotAvasset = asset
            }
            // 启动下载进度监控
            self.monitorExportProgress(exportSession: self.exportSession!,progressHandler: progress,handler: { finish in
                if finish {
                    completion(gotAvasset)
                }
            })
        }
    }
    
    func converPHAssetToAVURLAsset(completion:@escaping (AVURLAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        PHImageManager.default().requestAVAsset(forVideo: self, options: options) { avAsset, avAudioMix, info in
            if let urlAsset = avAsset as? AVURLAsset {
                completion(urlAsset)
            } else {
                completion(nil)
            }
        }
    }
    
    func monitorExportProgress(exportSession: AVAssetExportSession,progressHandler:@escaping (Float)->Void,handler:@escaping ((Bool)->Void)) {
        // 启动一个定时器来监控进度
        let progress = exportSession.progress
        self.exportTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            Task { @MainActor in
                PTNSLogConsole("当前下载进度：\(progress * 100)%")
                progressHandler(progress)
                // 当下载完成后，停止定时器
                if progress >= 1.0 {
                    timer.invalidate()
                    PTNSLogConsole("下载完成")
                    handler(true)
                }
            }
        }
    }
    
    func createAVAssetFromExportSession(completion: @escaping (AVAsset?) -> Void) {
        // 首先导出视频到指定的文件路径
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(Date().timeIntervalSince1970).mov")
        exportSession!.outputURL = outputURL
        exportSession!.outputFileType = .mov // 指定导出格式

        exportSession!.exportAsynchronously {
            switch self.exportSession!.status {
            case .completed:
                PTNSLogConsole("导出完成，路径: \(outputURL)")
                
                // 使用导出的 URL 创建 AVAsset
                let exportedAsset = AVAsset(url: outputURL)
                completion(exportedAsset)
                
            case .failed:
                PTNSLogConsole("导出失败: \(String(describing: self.exportSession!.error))")
                completion(nil)
                
            case .cancelled:
                PTNSLogConsole("导出被取消")
                completion(nil)
            default:
                break
            }
        }
    }
    
    func calcelExport() {
        if let exportSession = self.exportSession {
            exportSession.cancelExport()
            self.exportTimer?.invalidate()
        }
    }
}

public extension PTPOP where Base: PHAsset {
    var isInCloud: Bool {
        guard let resource = resource else {
            return false
        }
        return !(resource.value(forKey: "locallyAvailable") as? Bool ?? true)
    }

    var isGif: Bool {
        guard let filename = filename else {
            return false
        }
        
        return filename.hasSuffix("GIF")
    }
    
    var filename: String? {
        base.value(forKey: "filename") as? String
    }
    
    var resource: PHAssetResource? {
        PHAssetResource.assetResources(for: base).first
    }
    
    //MARK: 判斷是否為LivePhoto
    ///判斷是否為LivePhoto
    func isLivePhoto() -> Bool {
        return base.mediaSubtypes.contains(.photoLive)
    }
    
    //MARK: 根據如果是LivePhoto,可以獲取圖片真身
    ///根據如果是LivePhoto,可以獲取圖片真身
    func convertLivePhotoToImage(completion: @escaping (UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true

        imageManager.requestImage(for: base,
                                  targetSize: CGSize(width: base.pixelWidth, height: base.pixelHeight),
                                  contentMode: .aspectFit,
                                  options: options) { (image, info) in
            completion(image)
        }
    }
    
    func convertPHAssetToPHLivePhoto(completion: @escaping (PHLivePhoto?) -> Void) {
        // 检查该 PHAsset 是否为 Live Photo 类型
        guard base.pt.isLivePhoto() else {
            completion(nil)
            return
        }

        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true

        // 请求 Live Photo
        PHImageManager.default().requestLivePhoto(for: base, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { livePhoto, info in
            if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, !isDegraded {
                completion(livePhoto)
            } else {
                completion(nil)
            }
        }
    }
}
