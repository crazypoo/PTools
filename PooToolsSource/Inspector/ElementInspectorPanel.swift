//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum ElementInspectorPanel: Hashable, Swift.CaseIterable, MenuContentProtocol {
    case identity
    case attributes
    case size
    case children

    static var `default`: ElementInspectorPanel { Inspector.sharedInstance.configuration.elementInspectorConfiguration.defaultPanel }

    var title: String {
        switch self {
        case .identity:
            return Texts.inspect("Identity")
        case .attributes:
            return Texts.inspect("Attributes")
        case .children:
            return Texts.inspect("Children")
        case .size:
            return Texts.inspect("Size")
        }
    }

    var image: UIImage? {
        switch self {
        case .identity:
            return .elementIdentityPanel
        case .attributes:
            return .elementAttributesPanel
        case .children:
            return .elementChildrenPanel
        case .size:
            return .elementSizePanel
        }
    }

    var isDefault: Bool {
        self == .default
    }

    static func allCases(for element: ViewHierarchyElementReference) -> [ElementInspectorPanel] {
        allCases.filter { panel in
            switch panel {
            case .children:
                return element.isContainer

            case .size:
                return element.underlyingObject is UIView

            case .identity, .attributes:
                return true
            }
        }
    }
}
