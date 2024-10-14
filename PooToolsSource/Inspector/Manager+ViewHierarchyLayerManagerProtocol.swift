//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension Manager: ViewHierarchyLayerManagerProtocol {
    var isShowingLayers: Bool {
        viewHierarchyCoordinator.isShowingLayers == true
    }

    func isShowingLayer(_ layer: ViewHierarchyLayer) -> Bool {
        viewHierarchyCoordinator.isShowingLayer(layer) == true
    }

    func toggleLayer(_ layer: Inspector.ViewHierarchyLayer) {
        if viewHierarchyCoordinator.isShowingLayer(layer) == true {
            viewHierarchyCoordinator.removeLayer(layer)
        }
        else {
            viewHierarchyCoordinator.installLayer(layer)
        }
    }

    func removeLayer(_ layer: Inspector.ViewHierarchyLayer) {
        if viewHierarchyCoordinator.isShowingLayer(layer) == true {
            viewHierarchyCoordinator.removeLayer(layer)
        }
    }

    func toggleAllLayers() {
        if viewHierarchyCoordinator.isShowingLayers == true {
            viewHierarchyCoordinator.removeAllLayers()
        }
        else {
            viewHierarchyCoordinator.installAllLayers()
        }
    }

    func removeAllLayers() {
        viewHierarchyCoordinator.removeAllLayers()
    }
}
