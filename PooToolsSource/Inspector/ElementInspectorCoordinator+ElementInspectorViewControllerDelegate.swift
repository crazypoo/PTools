//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension ElementInspectorCoordinator: ElementInspectorViewControllerDelegate {
    func elementInspectorViewController(_ viewController: ElementInspectorViewController,
                                        didSelect element: ViewHierarchyElementReference,
                                        with action: ViewHierarchyElementAction,
                                        from fromElement: ViewHierarchyElementReference)
    {
        if
            element.objectIdentifier == fromElement.objectIdentifier,
            case let .inspect(preferredPanel: panel) = action
        {
            viewController.selectPanelIfAvailable(panel)
            return
        }
        guard let sourceView = fromElement.underlyingView else { return }

        guard canPerform(action: action) else {
            delegate?.perform(action: action, with: element, from: sourceView)
            return
        }

        perform(action: action, with: element, from: sourceView)
    }

    func elementInspectorViewController(viewControllerWith panel: ElementInspectorPanel,
                                        and element: ViewHierarchyElementReference) -> ElementInspectorPanelViewController
    {
        panelViewController(for: panel, with: element)
    }

    func elementInspectorViewControllerDidFinish(_ viewController: ElementInspectorViewController, with reason: ElementInspectorDismissReason) {
        finish(with: reason)
    }
}
