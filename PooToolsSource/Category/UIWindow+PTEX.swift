//
//  UIWindow+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/2/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIWindow {
    /// Overrides the user interface style adopted by the view and all of its subviews.
    /// - Parameter userInterfaceStyle: The user interface style adopted by the view and all of its subviews.
    func override(_ userInterfaceStyle: UIUserInterfaceStyle) {
        overrideUserInterfaceStyle = userInterfaceStyle
    }
}

public extension Array where Element: UIWindow {

    /// Overrides the user interface style adopted by all elements.
    /// - Parameter userInterfaceStyle: The user interface style adopted by all elements.
    func override(_ userInterfaceStyle: UIUserInterfaceStyle) {
        for window in self {
            window.override(userInterfaceStyle)
        }
    }
}
