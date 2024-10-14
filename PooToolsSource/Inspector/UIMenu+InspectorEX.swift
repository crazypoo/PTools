//
//  UIMenu+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

typealias ViewHierarchyActionHandler = (ViewHierarchyElementReference, ViewHierarchyElementAction) -> Void

extension UIMenu {
    private static var iconProvider: ViewHierarchyElementIconProvider? {
        Inspector.sharedInstance.manager?.catalog.iconProvider
    }

    convenience init?(
        with element: ViewHierarchyElementReference,
        initialMenus: [UIMenuElement] = [],
        includeActions: Bool = true,
        options: UIMenu.Options = .displayInline,
        handler: @escaping (ViewHierarchyElementReference, ViewHierarchyElementAction) -> Void
    ) {
        self.init(
            title: options == .displayInline ? "" : element.displayName,
            image: Self.iconProvider?.value(for: element.underlyingObject)?.resized(.init(24)),
            options: options,
            children: {
                var menus: [UIMenuElement] = initialMenus

                if includeActions {
                    let actionMenus = UIMenu.actionMenus(
                        element: element,
                        options: .displayInline,
                        handler: handler
                    )
                    menus.append(contentsOf: actionMenus)
                }

                if let childrenMenu = Self.childrenMenu(
                    element: element,
                    handler: handler
                ) {
                    menus.append(childrenMenu)
                }

                return menus
            }()
        )
    }

    private static func childrenMenu(element: ViewHierarchyElementReference,
                                     options: UIMenu.Options = .init(),
                                     handler: @escaping ViewHierarchyActionHandler) -> UIMenu?
    {
        guard element.isContainer else { return nil }

        return UIMenu(
            title: Texts.children.appending(" (\(element.children.count))"),
            image: .elementChildrenPanel,
            options: options,
            children: [UIDeferredMenuElement { completion in
                completion(
                    element.children.compactMap {
                        UIMenu(with: $0, options: .init(), handler: handler)
                    }
                )
            }]
        )
    }

    private static func actionMenus(element: ViewHierarchyElementReference,
                                    options: UIMenu.Options = .init(),
                                    handler: @escaping ViewHierarchyActionHandler) -> [UIMenu]
    {
        ViewHierarchyElementAction
            .actionGroups(for: element)
            .map { group in
                UIMenu(
                    title: group.title,
                    image: group.image,
                    options: group.inline ? .displayInline : .init(),
                    children: group.actions.map { action in
                        UIAction(
                            title: action.title,
                            image: action.image,
                            state: action.isOn ? .on : .off
                        ) { _ in
                            handler(element, action)
                        }
                    }
                )
            }
    }
}
