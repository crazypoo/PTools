//
//  UIAction+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIAction {
    static func collapseAction(_ isCollapsed: Bool,
                               expandTitle: String = Texts.expand,
                               collapseTitle: String = Texts.collapse,
                               handler: @escaping UIActionHandler) -> UIAction
    {
        UIAction(
            title: isCollapsed ? expandTitle : collapseTitle,
            image: isCollapsed ? .expandSymbol : .collapseSymbol,
            handler: handler
        )
    }
}

