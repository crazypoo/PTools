//
//  UIMenuElement+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIMenuElement {
    func insideDivider() -> UIMenuElement {
        UIMenu(
            title: String(),
            options: .displayInline,
            children: [self]
        )
    }

    var safeSubtitle: String? {
        get {
            return subtitle
        }
        set {
            subtitle = newValue
        }
    }
}

extension Array where Element: UIMenuElement {
    func insideDivider() -> [UIMenuElement] {
        [UIMenu(
            title: String(),
            options: .displayInline,
            children: self
        )]
    }
}
