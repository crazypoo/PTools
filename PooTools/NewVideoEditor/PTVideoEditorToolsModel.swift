//
//  PTVideoEditorToolsModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

enum PTVideoEditorVideoToolsType: CaseIterable {
    case speed
    case trim
    case crop
    case rotate
    case mute
    case presets
}

final class PTVideoEditorToolsModel {
    let videoControl: PTVideoEditorVideoToolsType
    
    var title: String {
        switch videoControl {
        case .speed:
            return "PT Video editor function speed".localized()
        case .trim:
            return "PT Video editor function trim".localized()
        case .crop:
            return "PT Video editor function crop".localized()
        case .rotate:
            return "PT Video editor function rotate".localized()
        case .mute:
            return "PT Video editor function mute".localized()
        case .presets:
            return "PT Video editor function export preset".localized()
        }
    }

    var titleImageName: String {
        switch videoControl {
        case .speed:
            return "Speed"
        case .trim:
            return "Trim"
        case .crop:
            return "Crop"
        case .rotate:
            return "Rotate"
        case .mute:
            return "Rotate"
        case .presets:
            return "Rotate"
        }
    }

    init(videoControl: PTVideoEditorVideoToolsType) {
        self.videoControl = videoControl
    }
}
