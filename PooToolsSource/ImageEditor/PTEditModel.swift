//
//  PTEditModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

//MARK: 编辑Model
public class PTEditModel:NSObject {
    public let drawPaths: [PTDrawPath]
    
    public let mosaicPaths: [PTMosaicPath]
    
    public let clipStatus: PTClipStatus
    
    public let adjustStatus: PTAdjustStatus
    
    public let selectFilter: PTHarBethFilter?
    
    public let stickers: [PTBaseStickertState]
    
    public let actions: [PTMediaEditorAction]
    
    public init(drawPaths: [PTDrawPath],
                mosaicPaths: [PTMosaicPath],
                clipStatus: PTClipStatus,
                adjustStatus: PTAdjustStatus,
                selectFilter: PTHarBethFilter,
                stickers: [PTBaseStickertState],
                actions: [PTMediaEditorAction]) {
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

