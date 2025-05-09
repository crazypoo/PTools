//
//  PTVideoEditorToolsModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SafeSFSymbols

public enum PTVideoEditorVideoToolsType: CaseIterable {
    case speed
    case trim
    case crop
    case rotate
    case mute
    case presets
    case filter
    case rewrite
}

final public class PTVideoEditorToolsModel {
    let videoControl: PTVideoEditorVideoToolsType
    
    var title: String {
        switch videoControl {
        case .speed:
            return PTVideoEditorConfig.share.speedTitle
        case .trim:
            return PTVideoEditorConfig.share.trimTitle
        case .crop:
            return PTVideoEditorConfig.share.cropTitle
        case .rotate:
            return PTVideoEditorConfig.share.rotateTitle
        case .mute:
            return PTVideoEditorConfig.share.muteTitle
        case .presets:
            return PTVideoEditorConfig.share.presetsTitle
        case .filter:
            return PTVideoEditorConfig.share.filterTitle
        case .rewrite:
            return PTVideoEditorConfig.share.rewriteTitle
        }
    }

    var titleImage: UIImage {
        switch videoControl {
        case .speed:
            return PTVideoEditorConfig.share.speedImage
        case .trim:
            return PTVideoEditorConfig.share.trimImage
        case .crop:
            return PTVideoEditorConfig.share.cropImage
        case .rotate:
            return PTVideoEditorConfig.share.rotateImage
        case .mute:
            return PTVideoEditorConfig.share.muteImage
        case .presets:
            return PTVideoEditorConfig.share.presetsImage
        case .filter:
            return PTVideoEditorConfig.share.filterImage
        case .rewrite:
            return PTVideoEditorConfig.share.rewriteImage
        }
    }

    init(videoControl: PTVideoEditorVideoToolsType) {
        self.videoControl = videoControl
    }
}
