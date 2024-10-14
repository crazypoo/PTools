//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ViewHierarchyLayerManagerProtocol {
    var isShowingLayers: Bool { get }

    func isShowingLayer(_ layer: ViewHierarchyLayer) -> Bool

    func toggleLayer(_ layer: Inspector.ViewHierarchyLayer)

    func removeLayer(_ layer: Inspector.ViewHierarchyLayer)

    func toggleAllLayers()

    func removeAllLayers()
}
