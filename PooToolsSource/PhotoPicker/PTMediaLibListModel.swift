//
//  PTMediaLibListModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Photos

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
#endif

@MainActor
public class PTMediaLibListModel: NSObject {
    public let title: String
    
    public var count: Int {
        result.count
    }
    
    public var result: PHFetchResult<PHAsset>
    
    public let collection: PHAssetCollection
    
    public let option: PHFetchOptions
    
    public let isCameraRoll: Bool

    // English: Store the picker behavior with the album so refetches never read mutable global settings.
    // Español: Guarda el comportamiento del selector con el álbum para que las recargas nunca lean ajustes globales mutables.
    // 中文：将选择器行为和相册一起保存，重新获取时不再读取可变的全局配置。
    public let selectionOptions: PTMediaLibSelectionOptions
    
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
                isCameraRoll: Bool,
                selectionOptions: PTMediaLibSelectionOptions? = nil) {
        self.title = title
        self.result = result
        self.collection = collection
        self.option = option
        self.isCameraRoll = isCameraRoll
        self.selectionOptions = selectionOptions ?? .current()
    }
    
    @MainActor
    public func refetchPhotos() {
        let models = PTMediaLibManager.fetchPhoto(
            in: result,
            ascending: selectionOptions.sortAscending,
            selectionOptions: selectionOptions
        )
        self.models.removeAll()
        self.models.append(contentsOf: models)
    }
    
    @MainActor
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
// PhotoKit/UIKit state is UI-owned and must stay on MainActor.
@MainActor
public final class PTMediaModel: NSObject {
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
    
    public var avEditorOutputItem:AVPlayerItem?
    
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
        guard asset.pixelWidth > 0, asset.pixelHeight > 0 else {
            return 1
        }
        return CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
    }
    
    /// English: Resolves an image request size from the consuming view's local bounds.
    /// Español: Resuelve el tamaño de la solicitud desde los límites locales de la vista consumidora.
    /// 中文：根据实际使用 View 的局部 bounds 计算图片请求尺寸。
    @MainActor
    public func previewSize(in containerBounds: CGRect,
                            scale: CGFloat? = nil) -> CGSize {
        let localWidth = max(1, containerBounds.width.isFinite ? containerBounds.width : 0)
        let localHeight = max(1, containerBounds.height.isFinite ? containerBounds.height : 0)
        let resolvedScale = max(1, scale ?? PTSceneContext.activeWindow()?.screen.scale ?? 1)
        let referenceLength = min(whRatio > 1 ? localHeight : localWidth, PTMaxImageWidth)
        let baseLength = max(1, referenceLength) * resolvedScale

        if whRatio > 1 {
            return CGSize(width: baseLength * whRatio, height: baseLength)
        }
        return CGSize(width: baseLength, height: baseLength / whRatio)
    }

    /// English: Legacy request-size access remains available, using the active scene only as a fallback.
    /// Español: El acceso heredado sigue disponible y usa la escena activa únicamente como respaldo.
    /// 中文：保留旧的尺寸属性，仅在没有显式容器时使用活动场景作为兜底。
    @available(*, deprecated, message: "Use previewSize(in:scale:) with the consuming view bounds.")
    @MainActor public var previewSize: CGSize {
        let fallbackBounds = PTSceneContext.activeWindow()?.bounds ??
            CGRect(x: 0, y: 0, width: PTMaxImageWidth, height: PTMaxImageWidth)
        return previewSize(in: fallbackBounds,
                           scale: PTSceneContext.activeWindow()?.screen.scale)
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
    enum MediaType: Int, Sendable {
        case unknown = 0
        case image
        case gif
        case livePhoto
        case video
    }
}

//MARK: 结果输出Model
@MainActor
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

// English: The typed completion value keeps success ordering and failed indices together.
// Español: El resultado tipado conserva juntos el orden exitoso y los índices fallidos.
// 中文：类型化完成结果同时保留成功顺序和失败下标，避免两个回调数组失配。
@MainActor
public struct PTMediaPickerOutcome {
    public let items: [PTResultModel]
    public let isOriginal: Bool
    public let failedAssetIndices: [Int]

    public init(items: [PTResultModel],
                isOriginal: Bool,
                failedAssetIndices: [Int] = []) {
        self.items = items
        self.isOriginal = isOriginal
        self.failedAssetIndices = failedAssetIndices
    }
}

extension PTResultModel {
    static func ==(lhs: PTResultModel, rhs: PTResultModel) -> Bool {
        lhs.asset == rhs.asset
    }
}
