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
        return result.count
    }
    
    public var result: PHFetchResult<PHAsset>
    
    public let collection: PHAssetCollection
    
    public let option: PHFetchOptions
    
    public let isCameraRoll: Bool
    
    public var headImageAsset: PHAsset? {
        return result.lastObject
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
        return lhs.title == rhs.title &&
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
    
    public var isSelected = false
    
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
            if let _ = editImageModel {
                return pri_editImage
            } else {
                return nil
            }
        }
    }
    
    public var second: PTMediaLibConfig.Second {
        guard type == .video else {
            return 0
        }
        return Int(round(asset.duration))
    }
    
    public var whRatio: CGFloat {
        return CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
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
    
    // Content of the last edit.
    public var editImageModel: PTEditModel?
    
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
        return lhs.ident == rhs.ident
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

//MARK: 编辑Model
public class PTEditModel:NSObject {
    public let drawPaths: [PTDrawPath]
    
    public let mosaicPaths: [PTMosaicPath]
    
    public let clipStatus: PTClipStatus
    
    public let adjustStatus: PTAdjustStatus
    
    public let selectFilter: PTHarBethFilter?
    
    public let stickers: [PTBaseStickertState]
    
    public let actions: [PTMediaEditorAction]
    
    public init(
        drawPaths: [PTDrawPath],
        mosaicPaths: [PTMosaicPath],
        clipStatus: PTClipStatus,
        adjustStatus: PTAdjustStatus,
        selectFilter: PTHarBethFilter,
        stickers: [PTBaseStickertState],
        actions: [PTMediaEditorAction]
    ) {
        self.drawPaths = drawPaths
        self.mosaicPaths = mosaicPaths
        self.clipStatus = clipStatus
        self.adjustStatus = adjustStatus
        self.selectFilter = selectFilter
        self.stickers = stickers
        self.actions = actions
        super.init()
    }
}

//MARK: 结果输出Model
public class PTResultModel: NSObject {
    @objc public let asset: PHAsset
    
    @objc public let image: UIImage
    
    /// Whether the picture has been edited. Always false when `saveNewImageAfterEdit = true`.
    @objc public let isEdited: Bool
    
    /// Content of the last edit. Always nil when `saveNewImageAfterEdit = true`.
    @objc public let editModel: PTEditModel?
    
    /// The order in which the user selects the models in the album. This index is not necessarily equal to the order of the model's index in the array, as some PHAssets requests may fail.
    @objc public let index: Int
    
    @objc public let avEditorOutputItem:AVPlayerItem?
    
    @objc public init(asset: PHAsset, image: UIImage, isEdited: Bool, editModel: PTEditModel? = nil,avEditorOutputItem: AVPlayerItem? = nil, index: Int) {
        self.asset = asset
        self.image = image
        self.isEdited = isEdited
        self.editModel = editModel
        self.index = index
        self.avEditorOutputItem = avEditorOutputItem
        super.init()
    }
}

extension PTResultModel {
    static func ==(lhs: PTResultModel, rhs: PTResultModel) -> Bool {
        return lhs.asset == rhs.asset
    }
}


public struct PTClipStatus {
    var angle: CGFloat = 0
    var editRect: CGRect
    var ratio: PTImageClipRatio?
}

public struct PTAdjustStatus {
    var brightness: Float = 1
    var contrast: Float = 0
    var saturation: Float = 0
    
    var allValueIsZero: Bool {
        brightness == 1 && contrast == 0 && saturation == 0
    }
}

// MARK: 裁剪比例
public class PTImageClipRatio: NSObject {
    @objc public var title: String
    
    @objc public let whRatio: CGFloat
    
    @objc public let isCircle: Bool
    
    @objc public init(title: String, whRatio: CGFloat, isCircle: Bool = false) {
        self.title = title
        self.whRatio = isCircle ? 1 : whRatio
        self.isCircle = isCircle
        super.init()
    }
}

extension PTImageClipRatio {
    static func == (lhs: PTImageClipRatio, rhs: PTImageClipRatio) -> Bool {
        return lhs.whRatio == rhs.whRatio && lhs.title == rhs.title
    }
}

public extension PTImageClipRatio {
    @objc static let custom = PTImageClipRatio(title: "custom", whRatio: 0)
    
    @objc static let circle = PTImageClipRatio(title: "circle", whRatio: 1, isCircle: true)
    
    @objc static let wh1x1 = PTImageClipRatio(title: "1 : 1", whRatio: 1)
    
    @objc static let wh3x4 = PTImageClipRatio(title: "3 : 4", whRatio: 3.0 / 4.0)
    
    @objc static let wh4x3 = PTImageClipRatio(title: "4 : 3", whRatio: 4.0 / 3.0)
    
    @objc static let wh2x3 = PTImageClipRatio(title: "2 : 3", whRatio: 2.0 / 3.0)
    
    @objc static let wh3x2 = PTImageClipRatio(title: "3 : 2", whRatio: 3.0 / 2.0)
    
    @objc static let wh9x16 = PTImageClipRatio(title: "9 : 16", whRatio: 9.0 / 16.0)
    
    @objc static let wh16x9 = PTImageClipRatio(title: "16 : 9", whRatio: 16.0 / 9.0)
}

public class PTBaseStickertState: NSObject {
    let id: String
    let image: UIImage
    let originScale: CGFloat
    let originAngle: CGFloat
    let originFrame: CGRect
    let gesScale: CGFloat
    let gesRotation: CGFloat
    let totalTranslationPoint: CGPoint
    
    init(
        id: String,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint
    ) {
        self.id = id
        self.image = image
        self.originScale = originScale
        self.originAngle = originAngle
        self.originFrame = originFrame
        self.gesScale = gesScale
        self.gesRotation = gesRotation
        self.totalTranslationPoint = totalTranslationPoint
        super.init()
    }
}

public class PTImageStickerState: PTBaseStickertState { }

public class PTTextStickerState: PTBaseStickertState {
    let text: String
    let textColor: UIColor
    let font: UIFont?
    let style: PTInputTextStyle
    
    init(
        id: String,
        text: String,
        textColor: UIColor,
        font: UIFont?,
        style: PTInputTextStyle,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint
    ) {
        self.text = text
        self.textColor = textColor
        self.font = font
        self.style = style
        super.init(
            id: id,
            image: image,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
}
