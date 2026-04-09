//
//  PTFetchImageOperation.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Photos
import Kingfisher

// 通过将 Operation 的执行逻辑约束在 @MainActor，
// 或者确保闭包捕获是 Sendable 的，来满足并发安全。
final class PTFetchImageOperation: Operation, @unchecked Sendable {
    private let model: PTMediaModel
    private let isOriginal: Bool
    private let progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)?
    private let completion: @Sendable (UIImage?, PHAsset?) -> Void

    // 💡 使用 Atomic 或 MainActor 保护 ID，防止 cancel 和 start 在不同线程竞争
    private var requestImageID: PHImageRequestID = PHInvalidImageRequestID
    private let idLock = NSLock()

    // MARK: - 状态管理
    // Operation 的状态属性必须是线程安全的。在 Swift 6 中，我们手动触发 KVO。
    private var _isExecuting: Bool = false
    override var isExecuting: Bool {
        get { _isExecuting }
        set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var _isFinished: Bool = false
    override var isFinished: Bool {
        get { _isFinished }
        set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    // MARK: - Init
    init(model: PTMediaModel,
         isOriginal: Bool,
         progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil,
         completion: @escaping @Sendable (UIImage?, PHAsset?) -> Void) {
        self.model = model
        self.isOriginal = isOriginal
        self.progress = progress
        self.completion = completion
        super.init()
    }

    // MARK: - Execution
    override func start() {
        // 1. 检查取消状态
        if isCancelled {
            fetchFinish()
            return
        }

        PTNSLogConsole("---- start fetch", levelType: PTLogMode, loggerType: .media)
        isExecuting = true

        // 2. 处理编辑过的图片
        // 💡 映射到 MainActor 以便安全访问 model 属性
        Task { @MainActor in
            if let editImage = model.editImage {
                if PTMediaLibConfig.share.saveNewImageAfterEdit {
                    PHPhotoLibrary.pt.saveImageToAlbum(image: editImage) { [weak self] _, asset in
                        self?.completion(editImage, asset)
                        self?.fetchFinish()
                    }
                } else {
                    self.completion(editImage, nil)
                    self.fetchFinish()
                }
                return
            }

            // 3. 处理 GIF
            if PTMediaLibConfig.share.allowSelectGif, model.type == .gif {
                let id = PTMediaLibManager.fetchOriginalImageData(for: model.asset) { [weak self] data, _, isDegraded in
                    if !isDegraded {
                        let image = UIImage.pt.animateGifImage(data: data)
                        self?.completion(image, nil)
                        self?.fetchFinish()
                    }
                }
                self.updateRequestID(id)
                return
            }

            // 4. 处理普通照片
            let size = model.previewSize
            let asset = model.asset
            
            let resultHandler: @Sendable (UIImage?, Bool) -> Void = { [weak self] image, isDegraded in
                guard let self = self, !isDegraded else { return }
                
                let fixedImage = image?.pt.fixOrientation()
                let finalImage = self.isOriginal ? fixedImage : self.scaleImage(fixedImage)
                
                PTNSLogConsole("加载完成, 原图: \(self.isOriginal)", levelType: PTLogMode, loggerType: .media)
                self.completion(finalImage, nil)
                self.fetchFinish()
            }

            let id: PHImageRequestID
            if isOriginal {
                id = PTMediaLibManager.fetchOriginalImage(for: asset, progress: progress, completion: resultHandler)
            } else {
                id = PTMediaLibManager.fetchImage(for: asset, size: size, progress: progress, completion: resultHandler)
            }
            self.updateRequestID(id)
        }
    }

    override func cancel() {
        super.cancel()
        
        idLock.lock()
        let idToCancel = requestImageID
        requestImageID = PHInvalidImageRequestID
        idLock.unlock()

        if idToCancel != PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(idToCancel)
        }

        if isExecuting {
            fetchFinish()
        }
    }

    // MARK: - Helpers
    private func updateRequestID(_ id: PHImageRequestID) {
        idLock.lock()
        requestImageID = id
        idLock.unlock()
    }

    private func fetchFinish() {
        // 确保状态变更连贯
        if isExecuting {
            isExecuting = false
        }
        if !isFinished {
            isFinished = true
        }
    }

    private func scaleImage(_ image: UIImage?) -> UIImage? {
        guard let i = image else { return nil }
        
        // 💡 优化性能：只有当图片确实很大时才进行 Data 转码
        guard let data = i.jpegData(compressionQuality: 1) else { return i }
        let mUnit = 1024.0 * 1024.0
        
        if CGFloat(data.count) < 0.2 * mUnit {
            return i
        }
        
        let scale: CGFloat = (CGFloat(data.count) > mUnit ? 0.6 : 0.8)
        guard let d = i.jpegData(compressionQuality: scale) else { return i }
        return UIImage(data: d)
    }
}
