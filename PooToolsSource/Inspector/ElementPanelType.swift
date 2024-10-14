//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

public extension Inspector {
    enum ElementPanelType: Swift.CaseIterable {
        case attributes, size

        var rawValue: ElementInspectorPanel {
            switch self {
            case .attributes:
                return .attributes
            case .size:
                return .size
            }
        }
    }
}
