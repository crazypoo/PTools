//
//  UIColor+VideoEditorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

extension UIColor {
    @MainActor static let background = PTVideoEditorConfig.share.sliderBackgroundColor
    @MainActor static let foreground = PTVideoEditorConfig.share.sliderFontColor
    @MainActor static let border = PTVideoEditorConfig.share.sliberBorder
    @MainActor static let croppingPreset = PTVideoEditorConfig.share.croppingPreset
    @MainActor static let croppingPresetSelected = PTVideoEditorConfig.share.croppingPresetSelected
}
