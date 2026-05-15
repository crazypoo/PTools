//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum ViewHierarchyLayerAction: Swift.CaseIterable, @preconcurrency MenuContentProtocol {
    case hideHighlight, showHighlight

    @MainActor
    static func allCases(for element: ViewHierarchyElementReference) -> [ViewHierarchyLayerAction] {
        allCases.filter { layerAction in
            switch layerAction {
            case .showHighlight:
                return !element.containsVisibleHighlightViews

            case .hideHighlight:
                return element.containsVisibleHighlightViews
            }
        }
    }

    var title: String {
        switch self {
        case .showHighlight:
            return Texts.highlight("Views")
        case .hideHighlight:
            return Texts.highlighting("Views")
        }
    }

    var image: UIImage? {
        .layerAction
    }
}
