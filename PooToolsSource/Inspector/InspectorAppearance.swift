//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

struct InspectorAppearance: Hashable {
    // MARK: - Wireframe Style

    var regularIconSize = CGSize(width: 20, height: 20)

    var actionIconSize = CGSize(width: 24, height: 24)

    var elementIconSize: CGSize {
        CGSize(
            width: elementInspector.verticalMargins * 3,
            height: elementInspector.verticalMargins * 3
        )
    }

    var elementInspector = ElementInspectorAppearance()

    var highlightLayerBorderWidth: CGFloat = 2 / UIScreen.main.scale

    var wireframeLayerBorderWidth: CGFloat = 1 / UIScreen.main.scale

    // MARK: - Empty Layer Style

    var emptyLayerBorderWidth: CGFloat = 0
}
