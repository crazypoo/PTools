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
    case clip(oldStatus: PTClipStatus, newStatus: PTClipStatus)
    case sticker(oldState: PTBaseStickertState?, newState: PTBaseStickertState?)
    case mosaic(PTDrawPath)
    case filter(oldFilter: PTHarBethFilter?, newFilter: PTHarBethFilter?)
    case adjust(oldStatus: PTAdjustStatus, newStatus: PTAdjustStatus)
    case imageSticker(oldState: PTBaseStickertState?, newState: PTBaseStickertState?)
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
    
    public init(actions: [PTMediaEditorAction] = []) {
        self.actions = actions
        redoActions = actions
    }

    public func storeAction(_ action: PTMediaEditorAction) {
        actions.append(action)
        redoActions = actions
        
        deliverUpdate()
    }

    public func undoAction() {
        guard let preAction = actions.popLast() else { return }
        
        delegate?.editorManager(self, undoAction: preAction)
        deliverUpdate()
    }
    
    public func redoAction() {
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

