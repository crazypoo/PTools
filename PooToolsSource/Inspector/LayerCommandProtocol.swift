//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
import ptools
#endif

protocol LayerCommandProtocol {
    func availableLayerCommands(for snapshot: ViewHierarchySnapshot) -> [Command]

    func toggleAllLayersCommands(for snapshot: ViewHierarchySnapshot) -> [Command]

    func command(for layer: ViewHierarchyLayer, at index: Int, count: Int?) -> Command
}
