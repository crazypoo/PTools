//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum ViewHierarchyInterfaceStyle {
    case unspecified
    case light
    case dark
}

@available(iOS 12.0, *)
extension ViewHierarchyInterfaceStyle: RawRepresentable {
    typealias RawValue = UIUserInterfaceStyle

    init?(rawValue: UIUserInterfaceStyle) {
        switch rawValue {
        case .unspecified:
            self = .unspecified
        case .light:
            self = .light
        case .dark:
            self = .dark
        @unknown default:
            return nil
        }
    }

    var rawValue: UIUserInterfaceStyle {
        switch self {
        case .unspecified:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
