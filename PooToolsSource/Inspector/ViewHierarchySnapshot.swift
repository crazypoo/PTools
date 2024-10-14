//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

struct ViewHierarchySnapshot: ExpirableProtocol {
    let expirationDate = Date().addingTimeInterval(Inspector.sharedInstance.configuration.snapshotExpirationTimeInterval)

    let availableLayers: [ViewHierarchyLayer: Int]

    var populatedLayers: [ViewHierarchyLayer: Int] {
        availableLayers
            .filter { $0.value > .zero }
    }

    let root: ViewHierarchyRoot

    init(layers: [ViewHierarchyLayer], root: ViewHierarchyRoot) {
        self.root = root
        availableLayers = layers
            .uniqueValues()
            .reduce(into: [:]) { availableLayers, layer in
                let matches = layer.filter(viewHierarchy: root.viewHierarchy)
                availableLayers[layer] = matches.count
            }
    }

    func containsReference(for object: NSObject?) -> ViewHierarchyElementReference? {
        root.viewHierarchy.first { $0.underlyingObject === object }
    }
}
