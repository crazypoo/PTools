//
//  PTBaseViewController+NavigationTypes.swift
//  PooTools
//
//  Shared navigation-bar value types and color interpolation helpers.
//

import UIKit

extension UIColor {
    func interpolate(to: UIColor, progress: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        guard self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else {
            return to
        }
        return UIColor(
            red: r1 + (r2 - r1) * progress,
            green: g1 + (g2 - g1) * progress,
            blue: b1 + (b2 - b1) * progress,
            alpha: a1 + (a2 - a1) * progress
        )
    }
}

// MARK: - 导航栏样式
public enum PTNavigationBarStyle: Equatable {
    case gradient(type: Imagegradien = .LeftToRight, colors: [DynamicColor])
    case solid(UIColor)
    case transparent

    public static var `default`: PTNavigationBarStyle {
        .gradient(type: .LeftToRight, colors: [UIColor.white, UIColor.white])
    }
}
