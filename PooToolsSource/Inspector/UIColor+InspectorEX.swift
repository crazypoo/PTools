//
//  UIColor+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init?(cgColor: CGColor?) {
        guard let cgColor = cgColor else {
            return nil
        }

        self.init(cgColor: cgColor)
    }
    
    var contrasting: UIColor {
        let ciColor = CIColor(color: self)

        let compRed: CGFloat = ciColor.red * 0.299
        let compGreen: CGFloat = ciColor.green * 0.587
        let compBlue: CGFloat = ciColor.blue * 0.114

        // Counting the perceptive luminance - human eye favors green color...
        let luminance = (compRed + compGreen + compBlue)

        // bright colors - black font
        // dark colors - white font
        let col: CGFloat = luminance < 0.55 ? 0 : 1

        return UIColor(red: col, green: col, blue: col, alpha: ciColor.alpha)
    }
}
