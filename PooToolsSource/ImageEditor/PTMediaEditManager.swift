//
//  PTMediaEditManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

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
}

