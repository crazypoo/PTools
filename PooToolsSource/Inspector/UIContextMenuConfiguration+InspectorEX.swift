//
//  UIContextMenuConfiguration+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIContextMenuConfiguration {
    convenience init(actionProvider: UIContextMenuActionProvider?) {
        self.init(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
    }

    static func contextMenuConfiguration(
        initialMenus: [UIMenuElement] = [],
        with element: ViewHierarchyElementReference,
        includeActions: Bool = true,
        handler: @escaping ViewHierarchyActionHandler
    ) -> UIContextMenuConfiguration? {
        var menus = initialMenus

        if let menu = UIMenu(
            with: element,
            includeActions: includeActions,
            options: .displayInline,
            handler: handler
        ) {
            menus.append(menu)
        }

        guard menus.isEmpty == false else { return nil }

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: {
                ViewHierarchyPreviewController(with: element)
            },
            actionProvider: { _ in
                UIMenu(
                    options: .displayInline,
                    children: menus
                )
            }
        )
    }
}
