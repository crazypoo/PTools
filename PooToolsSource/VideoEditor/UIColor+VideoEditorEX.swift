//
//  UIColor+VideoEditorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

extension UIColor {
    static let background = PTDarkModeOption.colorLightDark(lightColor: UIColor(hexString:"#eeeff4")!, darkColor: .black)
    static let foreground = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)
    static let border = #colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 0.9647058824, alpha: 1) // F2F4F6
    static let croppingPreset = #colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 0.9647058824, alpha: 1) // F2F4F6
    static let croppingPresetSelected = #colorLiteral(red: 0.7323174477, green: 0.7364212871, blue: 0.7465394735, alpha: 1) // F2F4F6
}
