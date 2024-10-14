//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension Manager: ElementInspectorCoordinatorDelegate {
    func elementInspectorCoordinator(_ coordinator: ElementInspectorCoordinator,
                                     didFinishInspecting element: ViewHierarchyElementReference,
                                     with reason: ElementInspectorDismissReason)
    {
        coordinator.removeFromParent()
        coordinator.dismissPresentation(animated: true)
    }
}

extension Manager {
    func startElementInspectorCoordinator(for view: UIView,
                                          panel: ElementInspectorPanel,
                                          from sourceView: UIView?,
                                          animated: Bool)
    {
        let reference = catalog.makeElement(from: view)
        startElementInspectorCoordinator(for: reference, panel: panel, from: sourceView, animated: animated)
    }

    func startElementInspectorCoordinator(for element: ViewHierarchyElementReference,
                                          panel: ElementInspectorPanel,
                                          from sourceView: UIView?,
                                          animated: Bool)
    {
        guard let keyWindow = keyWindow else { return }

        let coordinator = ElementInspectorCoordinator(
            .init(
                catalog: catalog,
                initialPanel: panel,
                rootElement: element,
                snapshot: snapshot,
                sourceView: sourceView ?? keyWindow
            ),
            presentedBy: keyWindow
        )
        coordinator.delegate = self

        keyWindow.topPresentedViewController?.present(coordinator.start(), animated: animated) { [weak self] in
            self?.addChild(coordinator)
        }
    }
}
