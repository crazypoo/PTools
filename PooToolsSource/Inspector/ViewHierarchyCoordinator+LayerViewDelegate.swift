//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

// MARK: - LayerViewDelegate

extension ViewHierarchyCoordinator: LayerViewDelegate {
    func layerView(_ layerView: LayerViewProtocol, didSelect element: ViewHierarchyElementReference, withAction action: ViewHierarchyElementAction) {
        guard canPerform(action: action) else {
            delegate?.perform(action: action, with: element, from: layerView.sourceView)
            return
        }

        perform(action: action, with: element, from: layerView.sourceView)
    }
}
