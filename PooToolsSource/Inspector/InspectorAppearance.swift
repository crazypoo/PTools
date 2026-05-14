//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

// 这样自动生成的 Hashable 实现也会隐式处于 @MainActor 下，消除所有并发冲突。
@MainActor
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

    // 整个结构体已经是 @MainActor，内部属性无需再单独标记
    var highlightLayerBorderWidth: CGFloat = 2 / UIScreen.main.scale

    var wireframeLayerBorderWidth: CGFloat = 1 / UIScreen.main.scale

    // MARK: - Empty Layer Style

    var emptyLayerBorderWidth: CGFloat = 0
}
