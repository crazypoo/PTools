//
//  PTMediaLibListModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Photos

public class PTMediaLibListModel: NSObject {
    public let title: String
    
    public var count: Int {
        result.count
    }
    
    public var result: PHFetchResult<PHAsset>
    
    public let collection: PHAssetCollection
    
    public let option: PHFetchOptions
    
    public let isCameraRoll: Bool
    
    public var headImageAsset: PHAsset? {
        result.lastObject
    }
    
    public var models: [PTMediaModel] = []
    
    // 暂未用到
    private var selectedModels: [PTMediaModel] = []
    
    // 暂未用到
    private var selectedCount = 0
    
    public init(title: String,
                result: PHFetchResult<PHAsset>,
                collection: PHAssetCollection,
                option: PHFetchOptions,
                isCameraRoll: Bool) {
        self.title = title
        self.result = result
        self.collection = collection
        self.option = option
        self.isCameraRoll = isCameraRoll
    }
    
    public func refetchPhotos() {
        let models = PTMediaLibManager.fetchPhoto(
            in: result,
            ascending: PTMediaLibUIConfig.share.sortAscending,
            allowSelectImage: PTMediaLibConfig.share.allowSelectImage,
            allowSelectVideo: PTMediaLibConfig.share.allowSelectVideo
        )
        self.models.removeAll()
        self.models.append(contentsOf: models)
    }
    
    func refreshResult() {
        result = PHAsset.fetchAssets(in: collection, options: option)
    }
}

extension PTMediaLibListModel {
    static func ==(lhs: PTMediaLibListModel, rhs: PTMediaLibListModel) -> Bool {
        lhs.title == rhs.title &&
                lhs.count == rhs.count &&
                lhs.headImageAsset?.localIdentifier == rhs.headImageAsset?.localIdentifier
    }
}

//MARK: MediaModel
public class PTMediaModel:NSObject {
    public let ident: String
    
    public let asset: PHAsset

    public var type: PTMediaModel.MediaType = .unknown
    
    public var duration = ""
    
    open var isSelected = false
    
    private var pri_dataSize: PTMediaLibConfig.KBUnit?
    
    public var dataSize: PTMediaLibConfig.KBUnit? {
        if let pri_dataSize = pri_dataSize {
            return pri_dataSize
        }
        
        let size = PTMediaLibManager.fetchAssetSize(for: asset)
        pri_dataSize = size
        
        return size
    }
    
    open var avEditorOutputItem:AVPlayerItem?
    
    private var pri_editImage: UIImage?
    
    public var editImage: UIImage? {
        set {
            pri_editImage = newValue
        }
        get {
#if POOTOOLS_IMAGEEDITOR

            if let _ = editImageModel {
                return pri_editImage
            } else {
                return nil
            }
#else
            return nil
#endif
        }
    }
    
    public var second: Int {
        guard type == .video else {
            return 0
        }
        return Int(round(asset.duration))
    }
    
    public var whRatio: CGFloat {
        CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
    }
    
    public var previewSize: CGSize {
        let scale: CGFloat = UIScreen.main.scale
        if whRatio > 1 {
            let h = min(UIScreen.main.bounds.height, PTMaxImageWidth) * scale
            let w = h * whRatio
            return CGSize(width: w, height: h)
        } else {
            let w = min(UIScreen.main.bounds.width, PTMaxImageWidth) * scale
            let h = w / whRatio
            return CGSize(width: w, height: h)
        }
    }
    
#if POOTOOLS_IMAGEEDITOR
    // Content of the last edit.
    public var editImageModel: PTEditModel?
#endif
    
    public init(asset: PHAsset) {
        ident = asset.localIdentifier
        self.asset = asset
        super.init()
        
        type = transformAssetType(for: asset)
        if type == .video {
            duration = transformDuration(for: asset)
        }
    }
    
    public func transformAssetType(for asset: PHAsset) -> PTMediaModel.MediaType {
        switch asset.mediaType {
        case .video:
            return .video
        case .image:
            if asset.pt.isGif {
                return .gif
            }
            if asset.mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            }
            return .image
        default:
            return .unknown
        }
    }
    
    public func transformDuration(for asset: PHAsset) -> String {
        let dur = Int(round(asset.duration))
        
        switch dur {
        case 0..<60:
            return String(format: "00:%02d", dur)
        case 60..<3600:
            let m = dur / 60
            let s = dur % 60
            return String(format: "%02d:%02d", m, s)
        case 3600...:
            let h = dur / 3600
            let m = (dur % 3600) / 60
            let s = dur % 60
            return String(format: "%02d:%02d:%02d", h, m, s)
        default:
            return ""
        }
    }
}

public extension PTMediaModel {
    static func == (lhs: PTMediaModel, rhs: PTMediaModel) -> Bool {
        lhs.ident == rhs.ident
    }
}

public extension PTMediaModel {
    enum MediaType: Int {
        case unknown = 0
        case image
        case gif
        case livePhoto
        case video
    }
}

//MARK: 结果输出Model
public class PTResultModel: NSObject {
    @objc public let asset: PHAsset
    
    @objc public let image: UIImage
    
    /// Whether the picture has been edited. Always false when `saveNewImageAfterEdit = true`.
    @objc public let isEdited: Bool
    
#if POOTOOLS_IMAGEEDITOR
    /// Content of the last edit. Always nil when `saveNewImageAfterEdit = true`.
    @objc public let editModel: PTEditModel?
#endif
    
    /// The order in which the user selects the models in the album. This index is not necessarily equal to the order of the model's index in the array, as some PHAssets requests may fail.
    @objc public let index: Int
    
    @objc public let avEditorOutputItem:AVPlayerItem?
    
#if POOTOOLS_IMAGEEDITOR
    @objc public init(asset: PHAsset, image: UIImage, isEdited: Bool, editModel: PTEditModel? = nil,avEditorOutputItem: AVPlayerItem? = nil, index: Int) {
        self.asset = asset
        self.image = image
        self.isEdited = isEdited
        self.editModel = editModel
        self.index = index
        self.avEditorOutputItem = avEditorOutputItem
        super.init()
    }
#else
    @objc public init(asset: PHAsset, image: UIImage, isEdited: Bool,avEditorOutputItem: AVPlayerItem? = nil, index: Int) {
        self.asset = asset
        self.image = image
        self.isEdited = isEdited
        self.index = index
        self.avEditorOutputItem = avEditorOutputItem
        super.init()
    }
#endif
}

extension PTResultModel {
    static func ==(lhs: PTResultModel, rhs: PTResultModel) -> Bool {
        lhs.asset == rhs.asset
    }
}
