//
//  PTMeidaLibManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import Photos

public class PTMeidaLibManager:NSObject {
    /// Save image to album.
    public class func saveImageToAlbum(image: UIImage, completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        var placeholderAsset: PHObjectPlaceholder?
        let completionHandler: ((Bool, Error?) -> Void) = { suc, _ in
            PTGCDManager.gcdMain {
                if suc {
                    let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                    completion?(suc, asset)
                } else {
                    completion?(false, nil)
                }
            }
        }

        if image.pt.hasAlphaChannel(), let data = image.pngData() {
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetCreationRequest.forAsset()
                newAssetRequest.addResource(with: .photo, data: data, options: nil)
                placeholderAsset = newAssetRequest.placeholderForCreatedAsset
            }, completionHandler: completionHandler)
        } else {
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeholderAsset = newAssetRequest.placeholderForCreatedAsset
            }, completionHandler: completionHandler)
        }
    }
    
    private class func getAsset(from localIdentifier: String?) -> PHAsset? {
        guard let id = localIdentifier else {
            return nil
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        return result.firstObject
    }


    @discardableResult
    public class func fetchImage(for asset: PHAsset, size: CGSize, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        return fetchImage(for: asset, size: size, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    /// Fetch image for asset.
    private class func fetchImage(for asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.resizeMode = resizeMode
        option.isNetworkAccessAllowed = true
        option.progressHandler = { pro, error, stop, info in
            PTGCDManager.gcdMain {
                progress?(CGFloat(pro), error, stop, info)
            }
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
        return fetchImage(for: asset, size: PHImageManagerMaximumSize, resizeMode: .fast, progress: progress, completion: completion)
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
            PTGCDManager.gcdGobal {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        return PHImageManager.default().requestImageData(for: asset, options: option) { data, _, _, info in
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
    
    class func getCameraRollAlbum(allowSelectImage: Bool, allowSelectVideo: Bool,handler:@escaping ((PTMediaLibListModel)->Void)) {
        PTGCDManager.gcdGobal {
            let option = PHFetchOptions()
            if !allowSelectImage {
                option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
            }
            
            if !allowSelectVideo {
                option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
            }
            
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
            smartAlbums.enumerateObjects { collection, _, stop in
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    stop.pointee = true
                    
                    let result = PHAsset.fetchAssets(in: collection, options: option)
                    let albumModel = PTMediaLibListModel(title: self.getCollectionTitle(collection), result: result, collection: collection, option: option, isCameraRoll: true)
                    PTGCDManager.gcdMain {
                        handler(albumModel)
                    }
                }
            }
        }
    }
    
    /// Fetch all album list.
    public class func getPhotoAlbumList(ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, completion: ([PTMediaLibListModel]) -> Void) {
        let option = PHFetchOptions()
        if !allowSelectImage {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        if !allowSelectVideo {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil) as! PHFetchResult<PHCollection>
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
                if #available(iOS 11.0, *), collection.assetCollectionSubtype.rawValue > PHAssetCollectionSubtype.smartAlbumLongExposures.rawValue {
                    return
                }
                let result = PHAsset.fetchAssets(in: collection, options: option)
                if result.count == 0 {
                    return
                }
                let title = self.getCollectionTitle(collection)
                
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
                PTGCDManager.gcdMain {
                    if let avAsset = session?.asset {
                        completion(avAsset, info)
                    } else {
                        completion(nil, info)
                    }
                }
            }
        } else {
            return PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                PTGCDManager.gcdMain {
                    completion(avAsset, info)
                }
            }
        }
    }

    
    public class func fetchVideo(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (AVPlayerItem?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { pro, error, stop, info in
            PTGCDManager.gcdMain {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        if asset.pt.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: option, exportPreset: AVAssetExportPresetHighestQuality, resultHandler: { session, info in
                // iOS11 and earlier, callback is not on the main thread.
                PTGCDManager.gcdMain {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    if let avAsset = session?.asset {
                        let item = AVPlayerItem(asset: avAsset)
                        completion(item, info, isDegraded)
                    } else {
                        completion(nil, nil, true)
                    }
                }
            })
        } else {
            return PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { item, info in
                // iOS11 and earlier, callback is not on the main thread.
                PTGCDManager.gcdMain {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    completion(item, info, isDegraded)
                }
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

public enum PTMediaEditorAction {
    case draw(PTDrawPath)
    case eraser([PTDrawPath])
    case clip(oldStatus: PTClipStatus, newStatus: PTClipStatus)
    case sticker(oldState: PTBaseStickertState?, newState: PTBaseStickertState?)
    case mosaic(PTMosaicPath)
    case filter(oldFilter: PTFilter?, newFilter: PTFilter?)
    case adjust(oldStatus: PTAdjustStatus, newStatus: PTAdjustStatus)
}

protocol PTMediaEditorManagerDelegate: AnyObject {
    func editorManager(_ manager: PTMediaEditManager, didUpdateActions actions: [PTMediaEditorAction], redoActions: [PTMediaEditorAction])
    
    func editorManager(_ manager: PTMediaEditManager, undoAction action: PTMediaEditorAction)
    
    func editorManager(_ manager: PTMediaEditManager, redoAction action: PTMediaEditorAction)
}

public class PTMediaEditManager:NSObject {
    
    private(set) var actions: [PTMediaEditorAction] = []
    private(set) var redoActions: [PTMediaEditorAction] = []
    
    weak var delegate: PTMediaEditorManagerDelegate?
    
    init(actions: [PTMediaEditorAction] = []) {
        self.actions = actions
        redoActions = actions
    }

    func storeAction(_ action: PTMediaEditorAction) {
        actions.append(action)
        redoActions = actions
        
        deliverUpdate()
    }

    func undoAction() {
        guard let preAction = actions.popLast() else { return }
        
        delegate?.editorManager(self, undoAction: preAction)
        deliverUpdate()
    }
    
    func redoAction() {
        guard actions.count < redoActions.count else { return }
        
        let action = redoActions[actions.count]
        actions.append(action)
        
        delegate?.editorManager(self, redoAction: action)
        deliverUpdate()
    }

    private func deliverUpdate() {
        delegate?.editorManager(self, didUpdateActions: actions, redoActions: redoActions)
    }
}
