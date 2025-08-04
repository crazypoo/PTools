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

func markSelected(source: inout [PTMediaModel], selected: inout [PTMediaModel]) {
    guard !selected.isEmpty else {
        return
    }
    
    var selIds: [String: Bool] = [:]
    var selEditImage: [String: UIImage] = [:]
#if POOTOOLS_IMAGEEDITOR
    var selEditModel: [String: PTEditModel] = [:]
#endif
    var selIdAndIndex: [String: Int] = [:]
    
    for (index, m) in selected.enumerated() {
        selIds[m.ident] = true
        selEditImage[m.ident] = m.editImage
#if POOTOOLS_IMAGEEDITOR
        selEditModel[m.ident] = m.editImageModel
#endif
        selIdAndIndex[m.ident] = index
    }
    
    source.forEach { m in
        if selIds[m.ident] == true {
            m.isSelected = true
            m.editImage = selEditImage[m.ident]
#if POOTOOLS_IMAGEEDITOR
            m.editImageModel = selEditModel[m.ident]
#endif
            selected[selIdAndIndex[m.ident]!] = m
        } else {
            m.isSelected = false
        }
    }
}

func canAddModel(_ model: PTMediaModel, currentSelectCount: Int, sender: UIViewController?, showAlert: Bool = true) -> Bool {
    let config = PTMediaLibConfig.share
    
    guard config.canSelectAsset?(model.asset) ?? true else {
        return false
    }
        
    if currentSelectCount >= config.maxSelectCount {
        if showAlert {
            PTAlertTipControl.present(title: config.alertTitle,subtitle:String(format: config.mediaCoutError, "\(config.maxSelectCount)"),icon:.Error,style:.Normal)
        }
        return false
    }
    
    if currentSelectCount > 0,
       !config.allowMixSelect,
       model.type == .video {
        return false
    }
    
    guard model.type == .video else {
        return true
    }
    
    if model.second > config.maxSelectVideoDuration {
        if showAlert {
            PTAlertTipControl.present(title: config.alertTitle,subtitle:String(format: config.videoTimeMoreError, "\(config.maxSelectVideoDuration)"),icon:.Error,style:.Normal)
        }
        return false
    }
    
    if model.second < config.minSelectVideoDuration {
        if showAlert {
            PTAlertTipControl.present(title: config.alertTitle,subtitle:String(format: config.videoTimeLessError, "\(config.minSelectVideoDuration)"),icon:.Error,style:.Normal)
        }
        return false
    }
    
    guard config.minSelectVideoDataSize > 0 || config.maxSelectVideoDataSize != .greatestFiniteMagnitude,
          let size = model.dataSize else {
        return true
    }
    
    if size > config.maxSelectVideoDataSize {
        if showAlert {
            let value = Int(round(config.maxSelectVideoDataSize / 1024))
            PTAlertTipControl.present(title: config.alertTitle,subtitle:String(format: config.videoSizeMoreError, "\(String(value))"),icon:.Error,style:.Normal)
        }
        return false
    }
    
    if size < config.minSelectVideoDataSize {
        if showAlert {
            let value = Int(round(config.minSelectVideoDataSize / 1024))
            PTAlertTipControl.present(title: config.alertTitle,subtitle:String(format: config.videoSizeLessError, "\(String(value))"),icon:.Error,style:.Normal)
        }
        return false
    }
    
    return true
}

@MainActor func downloadAssetIfNeed(alertTitle:String = PTMediaLibConfig.share.alertTitle,subTitle:String = PTMediaLibConfig.share.downloadTimeOutError,model: PTMediaModel, sender: UIViewController?, completion: @escaping PTActionTask) {
    let config = PTMediaLibConfig.share
    guard model.type == .video,
          model.asset.pt.isInCloud,
          config.downloadVideoBeforeSelecting else {
        completion()
        return
    }

    var requestAssetID: PHImageRequestID?
        
    let timer = Timer.scheduledTimer(timeInterval: Network.share.netRequsetTime, repeats: false) { timer in
        PTAlertTipControl.present(title: alertTitle,subtitle:subTitle,icon:.Error,style:.Normal)

        if let requestAssetID = requestAssetID {
            PHImageManager.default().cancelImageRequest(requestAssetID)
        }
        
        timer.invalidate()
    }
    
    requestAssetID = PTMediaLibManager.fetchVideo(for: model.asset, completion: { _, _, isDegraded in
        timer.invalidate()
        if !isDegraded {
            completion()
        }
    })
}

public class PTMediaLibManager:NSObject {    
    /// Save video to album.
    public class func saveVideoToAlbum(url: URL, completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        
        var placeholderAsset: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let newAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            placeholderAsset = newAssetRequest?.placeholderForCreatedAsset
        }) { suc, _ in
            if suc {
                let asset = PHPhotoLibrary.pt.getAsset(from: placeholderAsset?.localIdentifier)
                completion?(suc, asset)
            } else {
                completion?(false, nil)
            }
        }
    }

    @discardableResult
    public class func fetchImage(for asset: PHAsset, size: CGSize, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        fetchImage(for: asset, size: size, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    /// Fetch image for asset.
    private class func fetchImage(for asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.resizeMode = resizeMode
        option.isNetworkAccessAllowed = true
        option.progressHandler = { pro, error, stop, info in
            progress?(CGFloat(pro), error, stop, info)
        }
        
        return PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: option) { image, info in
            var downloadFinished = false
            if let info = info {
                downloadFinished = !(info[PHImageCancelledKey] as? Bool ?? false) && (info[PHImageErrorKey] == nil)
            }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if downloadFinished {
                PTGCDManager.gcdMain {
                    completion(image, isDegraded)
                }
            }
        }
    }
    
    @discardableResult
    public class func fetchOriginalImage(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        fetchImage(for: asset, size: PHImageManagerMaximumSize, resizeMode: .fast, progress: progress, completion: completion)
    }

    /// Fetch asset data.
    @discardableResult
    public class func fetchOriginalImageData(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (Data, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
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
            if !cancel, let data = data {
                completion(data, info, isDegraded)
            }
        }
    }
    
    /// Fetch photos from result.
    public class func fetchPhoto(in result: PHFetchResult<PHAsset>, ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, limitCount: Int = .max) -> [PTMediaModel] {
        var models: [PTMediaModel] = []
        let option: NSEnumerationOptions = ascending ? .init(rawValue: 0) : .reverse
        var count = 1
        
        result.enumerateObjects(options: option) { asset, _, stop in
            let m = PTMediaModel(asset: asset)
            
            if m.type == .image, !allowSelectImage {
                return
            }
            if m.type == .video, !allowSelectVideo {
                return
            }
            if count == limitCount {
                stop.pointee = true
            }
            
            models.append(m)
            count += 1
        }
        
        return models
    }
    
    class func predicatesGet(allowSelectImage: Bool, allowSelectVideo: Bool, allowSelectLivePhotoOnly: Bool/*, allowSelectRegularImageOnly: Bool*/) -> [NSPredicate] {
        var predicates : [NSPredicate] = []
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
            }
            
//            if allowSelectRegularImageOnly {
//                // 如果只允许选择普通图片，不包括 Live Photo
//                let imagePredicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
//                let nonLivePhotoPredicate = NSPredicate(format: "(mediaSubtypes & %ld) == 0", PHAssetMediaSubtype.photoLive.rawValue)
//                let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [imagePredicate, nonLivePhotoPredicate])
//                predicates.append(compoundPredicate)
//            }
        }
        return predicates
    }
    
    public class func getCameraRollAlbum(allowSelectImage: Bool, allowSelectVideo: Bool, allowSelectLivePhotoOnly: Bool/*, allowSelectRegularImageOnly: Bool*/,handler: @escaping (PTMediaLibListModel) -> Void) {
        PTGCDManager.gcdGobal {
            let option = PHFetchOptions()
            let predicates : [NSPredicate] = PTMediaLibManager.predicatesGet(allowSelectImage: allowSelectImage, allowSelectVideo: allowSelectVideo, allowSelectLivePhotoOnly: allowSelectLivePhotoOnly/*, allowSelectRegularImageOnly: allowSelectRegularImageOnly*/)

            // 组合多个条件（如果有）
            if !predicates.isEmpty {
                option.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            }

            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            smartAlbums.enumerateObjects { collection, _, stop in
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    stop.pointee = true
                    let result = PHAsset.fetchAssets(in: collection, options: option)
                    let albumModel = PTMediaLibListModel(title: getCollectionTitle(collection), result: result, collection: collection, option: option, isCameraRoll: true)
                    PTGCDManager.gcdMain {
                        handler(albumModel)
                    }
                }
            }
        }
    }
    
    /// Fetch all album list.
    public class func getPhotoAlbumList(ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, allowSelectLivePhotoOnly: Bool/*, allowSelectRegularImageOnly: Bool*/, completion: ([PTMediaLibListModel]) -> Void) {
        let option = PHFetchOptions()
        let predicates : [NSPredicate] = PTMediaLibManager.predicatesGet(allowSelectImage: allowSelectImage, allowSelectVideo: allowSelectVideo, allowSelectLivePhotoOnly: allowSelectLivePhotoOnly/*, allowSelectRegularImageOnly: allowSelectRegularImageOnly*/)

        // 组合多个条件（如果有）
        if !predicates.isEmpty {
            option.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil) as! PHFetchResult<PHCollection>
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil) as! PHFetchResult<PHCollection>
        let streamAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil) as! PHFetchResult<PHCollection>
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil) as! PHFetchResult<PHCollection>
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil) as! PHFetchResult<PHCollection>
        let arr = [smartAlbums, albums, streamAlbums, syncedAlbums, sharedAlbums]
        
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
    
    public class func fetchAVAsset(forVideo asset: PHAsset, completion: @escaping (AVAsset?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        if asset.pt.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetHighestQuality) { session, info in
                // iOS11 and earlier, callback is not on the main thread.
                if let avAsset = session?.asset {
                    completion(avAsset, info)
                } else {
                    completion(nil, info)
                }
            }
        } else {
            return PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                completion(avAsset, info)
            }
        }
    }
    
    public class func fetchVideo(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (AVPlayerItem?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { pro, error, stop, info in
            progress?(CGFloat(pro), error, stop, info)
        }
        
        if asset.pt.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: option, exportPreset: AVAssetExportPresetHighestQuality, resultHandler: { session, info in
                // iOS11 and earlier, callback is not on the main thread.
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                if let avAsset = session?.asset {
                    let item = AVPlayerItem(asset: avAsset)
                    completion(item, info, isDegraded)
                } else {
                    completion(nil, nil, true)
                }
            })
        } else {
            return PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { item, info in
                // iOS11 and earlier, callback is not on the main thread.
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                completion(item, info, isDegraded)
            }
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
