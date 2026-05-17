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
    // 使用 objc_Association 来存储状态
    @MainActor
    private struct AssociatedKeys {
        static var requestID = 1
        static var exportSession = 2
        // 🌟 修复 1：将 Timer 替换为 Task，完美契合 Swift 6 且不受 RunLoop 限制
        static var exportTask = 3
    }
    
    private struct PTSendableExportSession: @unchecked Sendable {
        let session: AVAssetExportSession
    }

    // 🌟 修改：接收 PTSendableExportSession 包装器
    @MainActor private func startExportProgressMonitoring(sendableSession: PTSendableExportSession, progressHandler: @escaping @Sendable (Float) -> Void) {
        exportTask?.cancel() // 停止之前的任务
        
        exportTask = Task {
            // 在 Task 内部安全地解包拿出 session
            let session = sendableSession.session
            
            // 只要任务未被取消，就不断轮询进度
            while !Task.isCancelled {
                let progress = session.progress
                PTNSLogConsole("当前下载进度：\(progress * 100)%")
                progressHandler(progress)

                // 达到完成状态即刻退出循环
                if progress >= 1.0 || session.status == .completed || session.status == .failed || session.status == .cancelled {
                    PTNSLogConsole("下载监控结束")
                    break
                }
                
                // 暂停 0.1 秒 (100,000,000 纳秒) 后继续下一次检查
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
    
    struct PTSendableAVAsset: @unchecked Sendable {
        let asset: AVAsset
    }

    @MainActor var requestID: PHImageRequestID? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.requestID) as? PHImageRequestID
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.requestID, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @MainActor var exportSession: AVAssetExportSession? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.exportSession) as? AVAssetExportSession
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.exportSession, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // 🌟 将原本的 exportTimer 改为 exportTask
    @MainActor var exportTask: Task<Void, Never>? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.exportTask) as? Task<Void, Never>
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.exportTask, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 🌟 修复 2：将 progressHandler 标记为 @Sendable，并使用 withCheckedContinuation
    @MainActor
    func convertPHAssetToAVAsset(progressHandler: @escaping @Sendable (Float) -> Void) async throws -> AVAsset? {
        
        // continuation 期待返回安全的 PTSendableAVAsset? 类型
        let safeResult = await withCheckedContinuation { continuation in
            self.convertPHAssetToAVAsset(progress: { progress in
                progressHandler(progress)
            }, completion: { safeAssetWrapper in
                // 此时 safeAssetWrapper 是 Sendable 的，跨越隔离边界绝对安全！
                continuation.resume(returning: safeAssetWrapper)
            })
        }
        
        // 当代码执行到这里，我们已经安全地回到了 @MainActor 隔离区。
        // 现在可以放心地将原始的 AVAsset 剥离出来并返回了。
        return safeResult?.asset
    }

    // 🌟 修改：将 completion 的参数改为我们新建的安全包装器 PTSendableAVAsset?
    @MainActor func convertPHAssetToAVAsset(progress: @escaping @Sendable (Float) -> Void,
                                 completion: @escaping @Sendable (PTSendableAVAsset?) -> Void) {
        
        let options = PHVideoRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestExportSession(forVideo: self, options: options, exportPreset: AVAssetExportPresetHighestQuality) { [weak self] exportSession, info in
            guard let self = self, let exportSession = exportSession else {
                PTNSLogConsole("导出会话创建失败")
                completion(nil)
                return
            }

            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("\(Date().timeIntervalSince1970).mov")

            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mov
            self.exportSession = exportSession
            
            let safeSession = PTSendableExportSession(session: exportSession)

            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    switch safeSession.session.status {
                    case .completed:
                        PTNSLogConsole("导出完成，路径: \(outputURL)")
                        let asset = AVAsset(url: outputURL)
                        // 🌟 核心修复点：将 asset 包装成安全类型后再通过闭包传递！
                        completion(PTSendableAVAsset(asset: asset))
                    case .failed, .cancelled:
                        completion(nil)
                    default:
                        break
                    }
                }
            }

            self.startExportProgressMonitoring(sendableSession: safeSession, progressHandler: progress)
        }
    }

    // 🌟 修复 3：使用 Swift 并发中的 Task 替代 Timer，彻底解决后台线程无法触发定时器的问题
    @MainActor private func startExportProgressMonitoring(exportSession: AVAssetExportSession, progressHandler: @escaping @Sendable (Float) -> Void) {
        exportTask?.cancel() // 停止之前的任务
        
        exportTask = Task { [weak exportSession] in
            guard let session = exportSession else { return }
            
            // 只要任务未被取消且导出还在进行中，就不断轮询进度
            while !Task.isCancelled {
                let progress = session.progress
                PTNSLogConsole("当前下载进度：\(progress * 100)%")
                progressHandler(progress)

                // 达到完成状态即刻退出循环
                if progress >= 1.0 || session.status == .completed || session.status == .failed || session.status == .cancelled {
                    PTNSLogConsole("下载监控结束")
                    break
                }
                
                // 暂停 0.1 秒 (100,000,000 纳秒) 后继续下一次检查
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    // MARK: - PHAsset 转换为 AVURLAsset
    func converPHAssetToAVURLAsset(version: PHVideoRequestOptionsVersion = .current,
                                   supportIcloud: Bool = true,
                                   deliveryMode: PHVideoRequestOptionsDeliveryMode = .highQualityFormat,
                                   completion: @escaping @Sendable (AVURLAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = version
        options.isNetworkAccessAllowed = supportIcloud
        options.deliveryMode = deliveryMode
        
        PHImageManager.default().requestAVAsset(forVideo: self, options: options) { avAsset, _, _ in
            if let urlAsset = avAsset as? AVURLAsset {
                completion(urlAsset)
            } else {
                completion(nil)
            }
        }
    }
            
    func converPHAssetToAVURLAssetAsync() async -> AVURLAsset? {
        await withCheckedContinuation { continuation in
            converPHAssetToAVURLAsset { aSet in
                continuation.resume(returning: aSet)
            }
        }
    }
    
    // 🌟 修复 4：适配新的 Task 取消机制
    @MainActor func calcelExport() {
        if let exportSession = self.exportSession {
            exportSession.cancelExport()
        }
        self.exportTask?.cancel()
        self.exportTask = nil
    }
    
    // MARK: - LivePhoto 转换 Image
    func convertLivePhotoToImage(completion: @escaping @Sendable (UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true

        imageManager.requestImage(for: self,
                                  targetSize: CGSize(width: self.pixelWidth, height: self.pixelHeight),
                                  contentMode: .aspectFit,
                                  options: options) { (image, _) in
            completion(image)
        }
    }
    
    func convertLivePhotoToImageAsync() async -> UIImage? {
        await withCheckedContinuation { continuation in
            convertLivePhotoToImage { image in
                continuation.resume(returning: image)
            }
        }
    }
    
    // MARK: - PHAsset 转换为图片
    func fetchImage(targetSize: CGSize = PHImageManagerMaximumSize,
                    contentMode: PHImageContentMode = .aspectFit,
                    deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat,
                    version: PHImageRequestOptionsVersion = .current,
                    supportIcloud: Bool  = true,
                    completion: @escaping @Sendable (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.version = version
        options.deliveryMode = deliveryMode
        options.isNetworkAccessAllowed = supportIcloud

        PHImageManager.default().requestImage(for: self, targetSize: targetSize, contentMode: contentMode, options: options) { image, _ in
            completion(image)
        }
    }
    
    // MARK: - 获取 PHAsset 的视频第一帧
    func fetchVideoFirstFrame(targetSize: CGSize = CGSize(width: 300, height: 300),
                              version: PHVideoRequestOptionsVersion = .current,
                              supportIcloud: Bool  = true,
                              deliveryMode: PHVideoRequestOptionsDeliveryMode = .highQualityFormat,
                              completion: @escaping @Sendable (UIImage?) -> Void) {
        self.converPHAssetToAVURLAsset(version: version, supportIcloud: supportIcloud, deliveryMode: deliveryMode) { asset in
            asset?.getVideoFirstImage(maximumSize: targetSize) { image in
                completion(image)
            }
        }
    }
    
    /// 导出 PHAsset 视频为临时文件
    func exportVideo(version: PHVideoRequestOptionsVersion = .current,
                     supportIcloud: Bool = true,
                     deliveryMode: PHVideoRequestOptionsDeliveryMode = .highQualityFormat,
                     completion: @escaping @Sendable (URL?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = version
        options.isNetworkAccessAllowed = supportIcloud
        options.deliveryMode = deliveryMode

        PHImageManager.default().requestExportSession(forVideo: self, options: options, exportPreset: AVAssetExportPresetHighestQuality) { exportSession, _ in
            guard let session = exportSession else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")

            session.outputURL = outputURL
            session.outputFileType = .mp4
            session.shouldOptimizeForNetworkUse = true
            
            // 🌟 修复关键点：使用我们在上一步创建的安全包装器
            let safeSession = PTSendableExportSession(session: session)

            // 启动异步导出
            session.exportAsynchronously {
                DispatchQueue.main.async {
                    // 🌟 在跨线程的闭包内部，统一通过 safeSession 读取状态，避免直接捕获 session
                    switch safeSession.session.status {
                    case .completed:
                        PTNSLogConsole("✅ 导出成功: \(outputURL)")
                        completion(outputURL)
                    case .failed, .cancelled:
                        PTNSLogConsole("❌ 导出失败: \(safeSession.session.error?.localizedDescription ?? "未知错误")")
                        completion(nil)
                    default:
                        break
                    }
                }
            }
        }
    }

    func asyncImage() async -> UIImage? {
        await withCheckedContinuation { continuation in
            self.fetchImage { image in
                continuation.resume(returning: image)
            }
        }
    }
}

public extension PTPOP where Base: PHAsset {
    var isInCloud: Bool {
        guard let resource = resource else { return false }
        return !(resource.value(forKey: "locallyAvailable") as? Bool ?? true)
    }

    var isGif: Bool {
        guard let filename = filename else { return false }
        return filename.hasSuffix("GIF")
    }
    
    var filename: String? {
        base.value(forKey: "filename") as? String
    }
    
    var resource: PHAssetResource? {
        PHAssetResource.assetResources(for: base).first
    }
    
    // MARK: - 判断是否为 LivePhoto
    func isLivePhoto() -> Bool {
        return base.mediaSubtypes.contains(.photoLive)
    }
        
    func convertPHAssetToPHLivePhoto(completion: @escaping @Sendable (PHLivePhoto?) -> Void) {
        guard base.pt.isLivePhoto() else {
            completion(nil)
            return
        }

        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestLivePhoto(for: base, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { livePhoto, info in
            if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, !isDegraded {
                completion(livePhoto)
            } else {
                completion(nil)
            }
        }
    }
    
    func convertPHAssetToPHLivePhotoAsync() async -> PHLivePhoto? {
        await withCheckedContinuation { continuation in
            convertPHAssetToPHLivePhoto { livePhoto in
                continuation.resume(returning: livePhoto)
            }
        }
    }
}
