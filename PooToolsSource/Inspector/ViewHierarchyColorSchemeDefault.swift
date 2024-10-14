//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension ViewHierarchyColorScheme {
    static let `default`: ViewHierarchyColorScheme = .init { view in
        if view._layerView?.element is ViewHierarchyElementController {
            return .systemOrange
        }

        if view.isSystemContainer { return .systemRed.darken() }

        switch view {
        case let control as UIControl:
            return .systemPurple

        case is UIImageView:
            return .darkGray

        case is UITableView,
             is UICollectionView:
            return .systemYellow

        case is UITableViewCell,
             is UICollectionViewCell:
            return .systemYellow.darken()

        case is UIStackView:
            return .systemBlue

        default:
            return .systemTeal
        }
    }
}
