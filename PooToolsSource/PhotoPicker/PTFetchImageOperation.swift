//
//  PTFetchImageOperation.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import PooTools
import Photos
import Kingfisher

class PTFetchImageOperation: Operation {
    private let model: PTMediaModel
    
    private let isOriginal: Bool
    
    private let progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)?
    
    private let completion: (UIImage?, PHAsset?) -> Void
    
    private var pri_isExecuting = false {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
        }
        didSet {
            self.didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return pri_isExecuting
    }
    
    private var pri_isFinished = false {
        willSet {
            self.willChangeValue(forKey: "isFinished")
        }
        didSet {
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return pri_isFinished
    }
    
    private var pri_isCancelled = false {
        willSet {
            willChangeValue(forKey: "isCancelled")
        }
        didSet {
            didChangeValue(forKey: "isCancelled")
        }
    }
    
    private var requestImageID = PHInvalidImageRequestID
    
    override var isCancelled: Bool {
        return pri_isCancelled
    }
    
    init(
        model: PTMediaModel,
        isOriginal: Bool,
        progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil,
        completion: @escaping ((UIImage?, PHAsset?) -> Void)
    ) {
        self.model = model
        self.isOriginal = isOriginal
        self.progress = progress
        self.completion = completion
        super.init()
    }
    
    override func start() {
        if isCancelled {
            fetchFinish()
            return
        }
        PTNSLogConsole("---- start fetch")
        pri_isExecuting = true
        
        // 存在编辑的图片
        if let editImage = model.editImage {
            if PTMediaLibConfig.share.saveNewImageAfterEdit {
                PTMeidaLibManager.saveImageToAlbum(image: editImage) { [weak self] _, asset in
                    self?.completion(editImage, asset)
                    self?.fetchFinish()
                }
            } else {
                PTGCDManager.gcdMain {
                    self.completion(editImage, nil)
                    self.fetchFinish()
                }
            }
            return
        }
        
        if PTMediaLibConfig.share.allowSelectGif, model.type == .gif {
            requestImageID = PTMeidaLibManager.fetchOriginalImageData(for: model.asset) { [weak self] data, _, isDegraded in
                if !isDegraded {
                    let image = UIImage.pt.animateGifImage(data: data)
                    self?.completion(image, nil)
                    self?.fetchFinish()
                }
            }
            return
        }
        
        if isOriginal {
            requestImageID = PTMeidaLibManager.fetchOriginalImage(for: model.asset, progress: progress) { [weak self] image, isDegraded in
                if !isDegraded {
                    PTNSLogConsole("---- 原图加载完成 \(String(describing: self?.isCancelled))")
                    self?.completion(image?.pt.fixOrientation(), nil)
                    self?.fetchFinish()
                }
            }
        } else {
            requestImageID = PTMeidaLibManager.fetchImage(for: model.asset, size: model.previewSize, progress: progress) { [weak self] image, isDegraded in
                if !isDegraded {
                    PTNSLogConsole("---- 加载完成 isCancelled: \(String(describing: self?.isCancelled))")
                    self?.completion(self?.scaleImage(image?.pt.fixOrientation()), nil)
                    self?.fetchFinish()
                }
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        PTNSLogConsole("---- cancel \(isExecuting) \(requestImageID)")
        PHImageManager.default().cancelImageRequest(requestImageID)
        pri_isCancelled = true
        if isExecuting {
            fetchFinish()
        }
    }
    
    private func scaleImage(_ image: UIImage?) -> UIImage? {
        guard let i = image else {
            return nil
        }
        guard let data = i.jpegData(compressionQuality: 1) else {
            return i
        }
        let mUnit: CGFloat = 1024 * 1024
        
        if data.count < Int(0.2 * mUnit) {
            return i
        }
        let scale: CGFloat = (data.count > Int(mUnit) ? 0.6 : 0.8)
        
        guard let d = i.jpegData(compressionQuality: scale) else {
            return i
        }
        return UIImage(data: d)
    }
    
    private func fetchFinish() {
        pri_isExecuting = false
        pri_isFinished = true
    }
}
