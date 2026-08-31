//
//  PTMediaLibManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import Photos
import UIKit

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
#endif

private struct PTSafeMediaBox<T>: @unchecked Sendable {
    let mediaItem: T
}

/// Compatibility container for callers that still need the raw PhotoKit info dictionary.
/// New code should use the typed image request result instead of moving this dictionary
/// between concurrency domains.
@available(*, deprecated, message: "Use typed image request results instead of moving raw PhotoKit info dictionaries")
public struct PTSendableDictionaryBox: @unchecked Sendable {
    public let info: [AnyHashable: Any]?
    
    public init(_ info: [AnyHashable: Any]?) {
        self.info = info
    }
}

private enum PTImageInfoValue: Sendable {
    case bool(Bool)
    case integer(Int)
    case double(Double)
    case string(String)
}

private struct PTImageInfoSnapshot: Sendable {
    private let values: [String: PTImageInfoValue]

    init(_ info: [AnyHashable: Any]?) {
        var values: [String: PTImageInfoValue] = [:]
        for (key, value) in info ?? [:] {
            let name = String(describing: key)
            switch value {
            case let value as Bool:
                values[name] = .bool(value)
            case let value as Int:
                values[name] = .integer(value)
            case let value as Double:
                values[name] = .double(value)
            case let value as String:
                values[name] = .string(value)
            default:
                continue
            }
        }
        self.values = values
    }

    @MainActor
    func dictionary() -> [AnyHashable: Any] {
        values.reduce(into: [AnyHashable: Any]()) { result, item in
            switch item.value {
            case .bool(let value): result[item.key] = value
            case .integer(let value): result[item.key] = value
            case .double(let value): result[item.key] = value
            case .string(let value): result[item.key] = value
            }
        }
    }
}

public enum PTMediaImageRequestError: Error, LocalizedError, Sendable {
    case cancelled
    case failed(String)

    public var errorDescription: String? {
        switch self {
        case .cancelled: return "图片请求已取消"
        case .failed(let message): return message
        }
    }
}

@MainActor
public struct PTMediaImageRequestResult {
    public let image: UIImage?
    public let isDegraded: Bool
    public let isCancelled: Bool
    public let error: PTMediaImageRequestError?

    public init(image: UIImage?,
                isDegraded: Bool,
                isCancelled: Bool,
                error: PTMediaImageRequestError?) {
        self.image = image
        self.isDegraded = isDegraded
        self.isCancelled = isCancelled
        self.error = error
    }
}

@MainActor
public struct PTMediaImageDataRequestResult {
    public let data: Data?
    public let info: [AnyHashable: Any]?
    public let isDegraded: Bool
    public let isCancelled: Bool
    public let error: PTMediaImageRequestError?

    public init(data: Data?,
                info: [AnyHashable: Any]?,
                isDegraded: Bool,
                isCancelled: Bool,
                error: PTMediaImageRequestError?) {
        self.data = data
        self.info = info
        self.isDegraded = isDegraded
        self.isCancelled = isCancelled
        self.error = error
    }
}

/// Typed video request result. The legacy dictionary is retained only for the
/// compatibility wrapper and is rebuilt on MainActor from a value snapshot.
@MainActor
public struct PTMediaVideoRequestResult {
    public let playerItem: AVPlayerItem?
    public let info: [AnyHashable: Any]?
    public let isDegraded: Bool
    public let isCancelled: Bool
    public let error: PTMediaImageRequestError?

    public init(playerItem: AVPlayerItem?,
                info: [AnyHashable: Any]?,
                isDegraded: Bool,
                isCancelled: Bool,
                error: PTMediaImageRequestError?) {
        self.playerItem = playerItem
        self.info = info
        self.isDegraded = isDegraded
        self.isCancelled = isCancelled
        self.error = error
    }
}

@MainActor
func markSelected(source: inout [PTMediaModel], selected: inout [PTMediaModel]) {
    guard !selected.isEmpty else {
        return
    }
    
    // 💡 优化：使用 Set 提升查找性能
    var selIds = Set<String>()
    var selEditImage: [String: UIImage] = [:]
#if POOTOOLS_IMAGEEDITOR
    var selEditModel: [String: PTEditModel] = [:]
#endif
    var selIdAndIndex: [String: Int] = [:]
    
    for (index, m) in selected.enumerated() {
        selIds.insert(m.ident)
        if let editImage = m.editImage {
            selEditImage[m.ident] = editImage
        }
#if POOTOOLS_IMAGEEDITOR
        if let editModel = m.editImageModel {
            selEditModel[m.ident] = editModel
        }
#endif
        selIdAndIndex[m.ident] = index
    }
    
    source.forEach { m in
        if selIds.contains(m.ident) {
            m.isSelected = true
            m.editImage = selEditImage[m.ident]
#if POOTOOLS_IMAGEEDITOR
            m.editImageModel = selEditModel[m.ident]
#endif
            // 💡 修复：安全防御，防止越界崩溃
            if let targetIndex = selIdAndIndex[m.ident], targetIndex < selected.count {
                selected[targetIndex] = m
            }
        } else {
            m.isSelected = false
        }
    }
}

@MainActor
func canAddModel(_ model: PTMediaModel, currentSelectCount: Int, sender: UIViewController?, showAlert: Bool = true) -> Bool {
    guard PTMediaLibConfig.share.canSelectAsset?(model.asset) ?? true else {
        return false
    }
        
    if currentSelectCount >= PTMediaLibConfig.share.maxSelectCount {
        if showAlert {
            PTAlertTipsViewController.tipsAlertShow(title: PTMediaLibUIConfig.share.alertTitle,subtitle: String(format: PTMediaLibUIConfig.share.mediaCoutError, "\(PTMediaLibConfig.share.maxSelectCount)"), icon: .Error)
        }
        return false
    }
    
    if currentSelectCount > 0,
       !PTMediaLibConfig.share.allowMixSelect,
       model.type == .video {
        return false
    }
    
    guard model.type == .video else {
        return true
    }
    
    if model.second > PTMediaLibConfig.share.maxSelectVideoDuration {
        if showAlert {
            PTAlertTipsViewController.tipsAlertShow(title: PTMediaLibUIConfig.share.alertTitle,subtitle: String(format: PTMediaLibUIConfig.share.videoTimeMoreError, "\(PTMediaLibConfig.share.maxSelectVideoDuration)"), icon: .Error)
        }
        return false
    }
    
    if model.second < PTMediaLibConfig.share.minSelectVideoDuration {
        if showAlert {
            PTAlertTipsViewController.tipsAlertShow(title: PTMediaLibUIConfig.share.alertTitle,subtitle: String(format: PTMediaLibUIConfig.share.videoTimeLessError, "\(PTMediaLibConfig.share.minSelectVideoDuration)"), icon: .Error)
        }
        return false
    }
    
    guard PTMediaLibConfig.share.minSelectVideoDataSize > 0 || PTMediaLibConfig.share.maxSelectVideoDataSize != .greatestFiniteMagnitude,
          let size = model.dataSize else {
        return true
    }
    
    if size > PTMediaLibConfig.share.maxSelectVideoDataSize {
        if showAlert {
            let value = Int(round(PTMediaLibConfig.share.maxSelectVideoDataSize / 1024))
            PTAlertTipsViewController.tipsAlertShow(title: PTMediaLibUIConfig.share.alertTitle,subtitle: String(format: PTMediaLibUIConfig.share.videoSizeMoreError, "\(String(value))"), icon: .Error)
        }
        return false
    }
    
    if size < PTMediaLibConfig.share.minSelectVideoDataSize {
        if showAlert {
            let value = Int(round(PTMediaLibConfig.share.minSelectVideoDataSize / 1024))
            PTAlertTipsViewController.tipsAlertShow(title: PTMediaLibUIConfig.share.alertTitle,subtitle: String(format: PTMediaLibUIConfig.share.videoSizeLessError, "\(String(value))"), icon: .Error)
        }
        return false
    }
    
    return true
}

@MainActor func downloadAssetIfNeed(alertTitle: String? = nil, subTitle: String? = nil, model: PTMediaModel, sender: UIViewController?, completion: @escaping PTActionTask) {
    
    let alertTitle_new = alertTitle ?? PTMediaLibUIConfig.share.alertTitle
    let subTitle_new = subTitle ?? PTMediaLibUIConfig.share.downloadTimeOutError

    let config = PTMediaLibConfig.share
    guard model.type == .video,
          model.asset.pt.isInCloud,
          config.downloadVideoBeforeSelecting else {
        completion()
        return
    }
    
    // 💡 Swift 6 优化：将其声明为绑定在 MainActor 的 final class
    // 因为受主线程保护，Swift 6 会自动赋予它隐式的 @Sendable 能力，再也不会报错了
    @MainActor final class RequestContainer {
        var id: PHImageRequestID?
    }
    let container = RequestContainer()
    
    // 💡 Swift 6 优化：废弃 Timer，使用现代的 Task 机制处理超时
    let timeoutTask = Task { @MainActor in
        // 将超时时间转换为纳秒 (nanoseconds)
        let nanoseconds = UInt64(Network.share.config.netRequsetTime * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
        
        // 醒来后检查任务是否已经被取消，如果取消了说明网络请求已经成功，直接退出
        guard !Task.isCancelled else { return }
        
        // 执行超时逻辑
        PTAlertTipsViewController.tipsAlertShow(title: alertTitle_new,subtitle: subTitle_new, icon: .Error)

        if let requestAssetID = container.id {
            PHImageManager.default().cancelImageRequest(requestAssetID)
        }
    }
    
    // 给容器内的属性赋值
    container.id = PTMediaLibManager.requestVideo(for: model.asset, completion: { result in
        // 网络请求一回来，马上取消超时任务
        timeoutTask.cancel()
        if !result.isDegraded, result.error == nil {
            completion()
        }
    })
}

public class PTMediaLibManager: NSObject {
    /// Save video to album.
    @available(*, deprecated, message: "Use PTMediaSaveService.save(videoURL:completion:) instead")
    public class func saveVideoToAlbum(url: URL, completion: (@Sendable (Bool, PHAsset?) -> Void)?) {
        Task { @MainActor in
            PTMediaSaveService.save(videoURL: url) { result in
                switch result {
                case .success(let asset):
                    completion?(true, asset)
                case .failure:
                    completion?(false, nil)
                }
            }
        }
    }

    @discardableResult
    @available(*, deprecated, message: "Use requestImage(for:targetSize:completion:) instead")
    public class func fetchImage(for asset: PHAsset, size: CGSize, progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping @Sendable (UIImage?, Bool) -> Void) -> PHImageRequestID {
        fetchImage(for: asset, size: size, resizeMode: .fast, progress: progress, completion: completion)
    }

    /// Unified PhotoKit image request boundary. The result is delivered on
    /// MainActor and carries cancellation/degraded/error state in one value.
    @discardableResult
    public class func requestImage(for asset: PHAsset,
                                   targetSize: CGSize,
                                   contentMode: PHImageContentMode = .aspectFill,
                                   resizeMode: PHImageRequestOptionsResizeMode = .fast,
                                   deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic,
                                   version: PHImageRequestOptionsVersion = .current,
                                   supportIcloud: Bool = true,
                                   progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil,
                                   completion: @escaping @MainActor @Sendable (PTMediaImageRequestResult) -> Void) -> PHImageRequestID {
        guard !asset.localIdentifier.isEmpty else {
            Task { @MainActor in
                completion(PTMediaImageRequestResult(image: nil,
                                                      isDegraded: false,
                                                      isCancelled: false,
                                                      error: .failed("媒体资源标识无效")))
            }
            return PHInvalidImageRequestID
        }

        let options = PHImageRequestOptions()
        options.version = version
        options.resizeMode = resizeMode
        options.deliveryMode = deliveryMode
        options.isNetworkAccessAllowed = supportIcloud
        options.progressHandler = { progressValue, error, stop, info in
            progress?(CGFloat(progressValue), error, stop, info)
        }

        return PHImageManager.default().requestImage(for: asset,
                                                      targetSize: targetSize,
                                                      contentMode: contentMode,
                                                      options: options) { image, info in
            let isCancelled = info?[PHImageCancelledKey] as? Bool ?? false
            let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            let error = (info?[PHImageErrorKey] as? Error).map {
                PTMediaImageRequestError.failed($0.localizedDescription)
            }
            let imageBox = image.map { PTSafeMediaBox(mediaItem: $0) }
            Task { @MainActor in
                let result = PTMediaImageRequestResult(image: imageBox?.mediaItem,
                                                       isDegraded: isDegraded,
                                                       isCancelled: isCancelled,
                                                       error: isCancelled ? .cancelled : error)
                completion(result)
            }
        }
    }
    
    /// Fetch image for asset.
    private class func fetchImage(for asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping @Sendable (UIImage?, Bool) -> Void) -> PHImageRequestID {
        requestImage(for: asset, targetSize: size, resizeMode: resizeMode, supportIcloud: true, progress: progress) { result in
            // 取消和失败也必须结束旧回调，否则依赖 completion 的
            // Operation/批量加载会永久等待。
            completion(result.isCancelled || result.error != nil ? nil : result.image,
                       result.isDegraded)
        }
    }
    
    @discardableResult
    @available(*, deprecated, message: "Use requestImage(for:targetSize:completion:) instead")
    public class func fetchOriginalImage(for asset: PHAsset, progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping @Sendable (UIImage?, Bool) -> Void) -> PHImageRequestID {
        fetchImage(for: asset, size: PHImageManagerMaximumSize, resizeMode: .fast, progress: progress, completion: completion)
    }

    /// Fetch asset data.
    @discardableResult
    @available(*, deprecated, message: "Use requestImageData(for:completion:) instead")
    public class func fetchOriginalImageData(for asset: PHAsset, progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping @MainActor @Sendable (Data, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        requestImageData(for: asset, progress: progress) { result in
            guard !result.isCancelled, let data = result.data else { return }
            completion(data, result.info, result.isDegraded)
        }
    }

    /// Unified typed image-data request boundary.
    @discardableResult
    public class func requestImageData(for asset: PHAsset,
                                      progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil,
                                      completion: @escaping @MainActor @Sendable (PTMediaImageDataRequestResult) -> Void) -> PHImageRequestID {
        guard !asset.localIdentifier.isEmpty else {
            Task { @MainActor in
                completion(PTMediaImageDataRequestResult(data: nil,
                                                         info: nil,
                                                         isDegraded: false,
                                                         isCancelled: false,
                                                         error: .failed("媒体资源标识无效")))
            }
            return PHInvalidImageRequestID
        }

        let option = PHImageRequestOptions()
        if asset.pt.isGif {
            option.version = .original
        }
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        option.deliveryMode = .highQualityFormat
        option.progressHandler = { pro, error, stop, info in
            progress?(CGFloat(pro), error, stop, info)
        }
                
        return PHImageManager.default().requestImageDataAndOrientation(for: asset, options: option) { data, _, _, info in
            let cancel = info?[PHImageCancelledKey] as? Bool ?? false
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            // PhotoKit 的 info 不是 Sendable；先复制可传输的基础值，再跨到 MainActor。
            let infoSnapshot = PTImageInfoSnapshot(info)
            let error = (info?[PHImageErrorKey] as? Error).map { PTMediaImageRequestError.failed($0.localizedDescription) }
            Task { @MainActor in
                completion(PTMediaImageDataRequestResult(data: data,
                                                          info: infoSnapshot.dictionary(),
                                                          isDegraded: isDegraded,
                                                          isCancelled: cancel,
                                                          error: cancel ? .cancelled : error))
            }
        }
    }
    
    /// Fetch photos from result.
    @MainActor
    public class func fetchPhoto(in result: PHFetchResult<PHAsset>, ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, limitCount: Int = .max) -> [PTMediaModel] {
        var models: [PTMediaModel] = []
        let option: NSEnumerationOptions = ascending ? .init(rawValue: 0) : .reverse
        var count = 1
        
        result.enumerateObjects(options: option) { asset, _, stop in
            // 💡 优化：包裹 autoreleasepool，控制遍历时的内存峰值
            autoreleasepool {
                let m = PTMediaModel(asset: asset)
                
                var shouldAdd = true
                if m.type == .image && !allowSelectImage {
                    shouldAdd = false
                }
                if m.type == .video && !allowSelectVideo {
                    shouldAdd = false
                }
                
                if shouldAdd {
                    models.append(m)
                    if count == limitCount {
                        stop.pointee = true
                    }
                    count += 1
                }
            }
        }
        
        return models
    }
    
    // 💡 修复：补齐被注释掉的仅选择普通照片功能
    class func predicatesGet(allowSelectImage: Bool, allowSelectVideo: Bool, allowSelectLivePhotoOnly: Bool, allowSelectRegularImageOnly: Bool = false) -> [NSPredicate] {
        var predicates: [NSPredicate] = []
        
        // 如果允许选择视频
        if allowSelectVideo {
            predicates.append(NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue))
        }
        
        if allowSelectImage {
            // 如果允许选择图片，不排除 Live Photo
            predicates.append(NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue))
        } else {
            if allowSelectLivePhotoOnly {
                // 如果只允许选择 Live Photo
                predicates.append(NSPredicate(format: "mediaType == %ld AND (mediaSubtypes & %ld) != 0", PHAssetMediaType.image.rawValue, PHAssetMediaSubtype.photoLive.rawValue))
            } else if allowSelectRegularImageOnly {
                // 如果只允许选择普通图片，不包括 Live Photo
                let imagePredicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
                let nonLivePhotoPredicate = NSPredicate(format: "(mediaSubtypes & %ld) == 0", PHAssetMediaSubtype.photoLive.rawValue)
                let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [imagePredicate, nonLivePhotoPredicate])
                predicates.append(compoundPredicate)
            }
        }
        return predicates
    }
    
    @MainActor
    public class func getCameraRollAlbum(allowSelectImage: Bool, allowSelectVideo: Bool, allowSelectLivePhotoOnly: Bool, allowSelectRegularImageOnly: Bool = false, handler: @escaping @MainActor @Sendable (PTMediaLibListModel) -> Void) {
        // PHFetchOptions is mutable and PhotoKit does not make it Sendable.
        // Create, configure, consume, and retain it on the same actor so the
        // model never captures an option that was mutated on a background queue.
        let option = PHFetchOptions()
        let predicates: [NSPredicate] = PTMediaLibManager.predicatesGet(allowSelectImage: allowSelectImage, allowSelectVideo: allowSelectVideo, allowSelectLivePhotoOnly: allowSelectLivePhotoOnly, allowSelectRegularImageOnly: allowSelectRegularImageOnly)

        if !predicates.isEmpty {
            option.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }

        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        for index in 0..<smartAlbums.count {
            let collection = smartAlbums.object(at: index)
            guard collection.assetCollectionSubtype == .smartAlbumUserLibrary else { continue }
            let result = PHAsset.fetchAssets(in: collection, options: option)
            let albumModel = PTMediaLibListModel(title: getCollectionTitle(collection), result: result, collection: collection, option: option, isCameraRoll: true)
            handler(albumModel)
            break
        }
    }
    
    /// Fetch all album list.
    @MainActor
    public class func getPhotoAlbumList(ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, allowSelectLivePhotoOnly: Bool, allowSelectRegularImageOnly: Bool = false, completion: @escaping @MainActor @Sendable ([PTMediaLibListModel]) -> Void) {
        let option = PHFetchOptions()
        let predicates: [NSPredicate] = PTMediaLibManager.predicatesGet(allowSelectImage: allowSelectImage, allowSelectVideo: allowSelectVideo, allowSelectLivePhotoOnly: allowSelectLivePhotoOnly, allowSelectRegularImageOnly: allowSelectRegularImageOnly)

        // 组合多个条件（如果有）
        if !predicates.isEmpty {
            option.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }
        
        // 💡 修复：使用条件转换，避免非法类型导致崩溃。
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil) as? PHFetchResult<PHCollection>
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil) as? PHFetchResult<PHCollection>
        let streamAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil) as? PHFetchResult<PHCollection>
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil) as? PHFetchResult<PHCollection>
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil) as? PHFetchResult<PHCollection>
        
        let arr: [PHFetchResult<PHCollection>] = [smartAlbums, albums, streamAlbums, syncedAlbums, sharedAlbums].compactMap { $0 }
        
        var albumList: [PTMediaLibListModel] = []
        arr.forEach { album in
            album.enumerateObjects { collection, _, _ in
                guard let collection = collection as? PHAssetCollection else { return }
                if collection.assetCollectionSubtype == .smartAlbumAllHidden {
                    return
                }
                if collection.assetCollectionSubtype.rawValue > PHAssetCollectionSubtype.smartAlbumLongExposures.rawValue {
                    return
                }
                let result = PHAsset.fetchAssets(in: collection, options: option)
                if result.count == 0 {
                    return
                }
                let title = getCollectionTitle(collection)
                
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    // Album of all photos.
                    let m = PTMediaLibListModel(title: title, result: result, collection: collection, option: option, isCameraRoll: true)
                    albumList.insert(m, at: 0)
                } else {
                    let m = PTMediaLibListModel(title: title, result: result, collection: collection, option: option, isCameraRoll: false)
                    albumList.append(m)
                }
            }
        }
        
        completion(albumList)
    }

    public class func fetchAssetSize(for asset: PHAsset) -> PTMediaLibConfig.KBUnit? {
        guard let resource = PHAssetResource.assetResources(for: asset).first,
              let size = resource.value(forKey: "fileSize") as? CGFloat else {
            return nil
        }
        
        return size / 1024
    }
    
    public class func fetchAVAsset(forVideo asset: PHAsset, completion: @escaping @MainActor @Sendable (AVAsset?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        if asset.pt.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetHighestQuality) { session, info in
                let infoSnapshot = PTImageInfoSnapshot(info)
                let assetBox = session.map { PTSafeMediaBox(mediaItem: $0.asset) }
                Task { @MainActor in
                    completion(assetBox?.mediaItem, infoSnapshot.dictionary())
                }
            }
        } else {
            return PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                let infoSnapshot = PTImageInfoSnapshot(info)
                let assetBox = avAsset.map { PTSafeMediaBox(mediaItem: $0) }
                Task { @MainActor in
                    completion(assetBox?.mediaItem, infoSnapshot.dictionary())
                }
            }
        }
    }

    /// Unified typed video request boundary. Legacy `fetchVideo` remains as a
    /// compatibility wrapper below.
    @discardableResult
    public class func requestVideo(for asset: PHAsset,
                                  progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil,
                                  completion: @escaping @MainActor @Sendable (PTMediaVideoRequestResult) -> Void) -> PHImageRequestID {
        guard !asset.localIdentifier.isEmpty else {
            Task { @MainActor in
                completion(PTMediaVideoRequestResult(playerItem: nil,
                                                     info: nil,
                                                     isDegraded: false,
                                                     isCancelled: false,
                                                     error: .failed("媒体资源标识无效")))
            }
            return PHInvalidImageRequestID
        }

        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { pro, error, stop, info in
            progress?(CGFloat(pro), error, stop, info)
        }

        let finish: @MainActor @Sendable (PTSafeMediaBox<AVPlayerItem>?, [AnyHashable: Any]?, Bool, PTMediaImageRequestError?) -> Void = { itemBox, info, degraded, error in
            let isCancelled: Bool
            if let error, case .cancelled = error {
                isCancelled = true
            } else {
                isCancelled = false
            }
            completion(PTMediaVideoRequestResult(playerItem: itemBox?.mediaItem,
                                                 info: info,
                                                 isDegraded: degraded,
                                                 isCancelled: isCancelled,
                                                 error: error))
        }

        if asset.pt.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset,
                                                                  options: option,
                                                                  exportPreset: AVAssetExportPresetHighestQuality) { session, info in
                let infoSnapshot = PTImageInfoSnapshot(info)
                let assetBox = session.map { PTSafeMediaBox(mediaItem: $0.asset) }
                let degraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                let cancelled = info?[PHImageCancelledKey] as? Bool ?? false
                let error = (info?[PHImageErrorKey] as? Error).map { PTMediaImageRequestError.failed($0.localizedDescription) }
                Task { @MainActor in
                    let itemBox = assetBox.map { PTSafeMediaBox(mediaItem: AVPlayerItem(asset: $0.mediaItem)) }
                    finish(itemBox, infoSnapshot.dictionary(), degraded, cancelled ? .cancelled : error)
                }
            }
        }

        return PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { item, info in
            let infoSnapshot = PTImageInfoSnapshot(info)
            let itemBox = item.map { PTSafeMediaBox(mediaItem: $0) }
            let degraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
            let cancelled = info?[PHImageCancelledKey] as? Bool ?? false
            let error = (info?[PHImageErrorKey] as? Error).map { PTMediaImageRequestError.failed($0.localizedDescription) }
            Task { @MainActor in
                finish(itemBox, infoSnapshot.dictionary(), degraded, cancelled ? .cancelled : error)
            }
        }
    }

    @available(*, deprecated, message: "Use requestVideo(for:completion:) instead")
    public class func fetchVideo(for asset: PHAsset,
                                 progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil,
                                 completion: @escaping @Sendable (AVPlayerItem?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        requestVideo(for: asset, progress: progress) { result in
            completion(result.playerItem, result.info, result.isDegraded)
        }
    }

    private class func getCollectionTitle(_ collection: PHAssetCollection) -> String {
        if collection.assetCollectionType == .album {
            // Albums created by user.
            let title: String = collection.localizedTitle ?? ""
            return title
        }
        
        let title: String = collection.localizedTitle ?? ""
        
        return title
    }
}
