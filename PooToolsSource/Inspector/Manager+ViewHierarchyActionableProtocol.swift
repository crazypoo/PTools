//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension Manager: ViewHierarchyActionableProtocol {
    func perform(action: ViewHierarchyElementAction, with element: ViewHierarchyElementReference, from sourceView: UIView) {
        guard canPerform(action: action) else {
            assertionFailure("Should not happen")
            return
        }

        switch action {
        case .layer:
            viewHierarchyCoordinator.perform(action: action, with: element, from: sourceView)

        case let .inspect(preferredPanel: preferredPanel):
            startElementInspectorCoordinator(for: element, panel: preferredPanel, from: sourceView, animated: true)

        case .copy(.className):
            UIPasteboard.general.string = element.className

        case .copy(.description):
            UIPasteboard.general.string = element.elementDescription

        case .copy(.report):
            UIPasteboard.general.string = element.viewHierarchyDescription
        }
    }

    func canPerform(action: ViewHierarchyElementAction) -> Bool {
        true
    }
}
