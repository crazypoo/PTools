//
//  PTMediaEditManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Photos

public enum PTMediaEditorAction {
    case draw(PTDrawPath)
    case eraser([PTDrawPath])
    case clip(oldStatus: PTClipStatus, newStatus: PTClipStatus)
    case sticker(oldState: PTBaseStickertState?, newState: PTBaseStickertState?)
    case mosaic(PTMosaicPath)
    case filter(oldFilter: PTHarBethFilter?, newFilter: PTHarBethFilter?)
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
    
    /// Save image to album.
    public class func saveImageToAlbum(image: UIImage, completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        var placeholderAsset: PHObjectPlaceholder?
        let completionHandler: (Bool, Error?) -> Void = { suc, _ in
            if suc {
                let asset = getAsset(from: placeholderAsset?.localIdentifier)
                completion?(suc, asset)
            } else {
                completion?(false, nil)
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
    
    class func getAsset(from localIdentifier: String?) -> PHAsset? {
        guard let id = localIdentifier else {
            return nil
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        return result.firstObject
    }
}

