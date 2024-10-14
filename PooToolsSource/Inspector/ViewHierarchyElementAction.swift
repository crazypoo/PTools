//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum ViewHierarchyElementAction: MenuContentProtocol {
    case layer(action: ViewHierarchyLayerAction)
    case inspect(preferredPanel: ElementInspectorPanel)
    case copy(info: ViewHierarchyInformation)

    var title: String {
        switch self {
        case let .layer(action):
            return action.title

        case let .inspect(preferredPanel):
            return preferredPanel.title

        case let .copy(content):
            return content.title
        }
    }

    var isOn: Bool {
        switch self {
        case let .layer(action):
            switch action {
            case .hideHighlight: return true
            case .showHighlight: return false
            }
        case .inspect: return false
        case .copy: return false
        }
    }

    var image: UIImage? {
        switch self {
        case let .layer(action):
            return action.image
        case let .inspect(preferredPanel):
            return preferredPanel.image
        case let .copy(content):
            return content.image
        }
    }

    static func allCases(for element: ViewHierarchyElementReference) -> [ViewHierarchyElementAction] {
        var actions = [ViewHierarchyElementAction]()

        for action in ViewHierarchyLayerAction.allCases(for: element) {
            actions.append(.layer(action: action))
        }

        for panel in ElementInspectorPanel.allCases(for: element) {
            actions.append(.inspect(preferredPanel: panel))
        }

        for content in ViewHierarchyInformation.allCases(for: element) {
            actions.append(.copy(info: content))
        }

        return actions
    }

    struct ElementActionGroup {
        let title: String
        let image: UIImage?
        let inline: Bool
        let actions: [ViewHierarchyElementAction]
    }

    static func actionGroups(for element: ViewHierarchyElementReference) -> [ElementActionGroup] {
        [
            .init(
                title: "",
                image: .none,
                inline: true,
                actions: ElementInspectorPanel.allCases(for: element).map { .inspect(preferredPanel: $0) }
            ),
            .init(
                title: "",
                image: .layerAction,
                inline: true,
                actions: ViewHierarchyLayerAction.allCases(for: element).map { .layer(action: $0) }
            ),
            .init(
                title: "Copy",
                image: .copySymbol,
                inline: false,
                actions: ViewHierarchyInformation.allCases(for: element).map { .copy(info: $0) }
            )
        ]
        .filter { !$0.actions.isEmpty }
    }
}
