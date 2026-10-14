//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
import ptools
#endif

enum ElementChildrenPanelAction {
    case inserted([IndexPath])
    case deleted([IndexPath])

    var lastIndexPath: IndexPath? {
        switch self {
        case let .inserted(indexPaths),
             let .deleted(indexPaths):
            return indexPaths.last
        }
    }
}
