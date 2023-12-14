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
        case .filter:
            return "PT Video editor function filter".localized()
        case .rewrite:
            return "PT Video editor function rewrite".localized()
        }
    }

    var titleImage: UIImage {
        switch videoControl {
        case .speed:
            if #available(iOS 16.0, *) {
                return UIImage(systemName: "figure.walk.motion")!.withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
            } else {
                return UIImage(.bolt.horizontalCircle).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
            }
        case .trim:
            if #available(iOS 14.0, *) {
                return UIImage(.timeline.selection).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
            } else {
                return UIImage(.timer).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
            }
        case .crop:
            return UIImage(.crop).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        case .rotate:
            return UIImage(.rotate.right).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        case .mute:
            return UIImage(.speaker).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        case .presets:
            return UIImage(.tv).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        case .filter:
            if #available(iOS 14.0, *) {
                return UIImage(.camera.filters).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
            } else {
                return UIImage(systemName: "option")!.withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
            }
        case .rewrite:
            return UIImage(.repeat).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }

    init(videoControl: PTVideoEditorVideoToolsType) {
        self.videoControl = videoControl
    }
}
