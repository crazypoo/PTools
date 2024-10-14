//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum Texts {
    static let `default` = "Default"
    static let actions = "Actions"
    static let allHighlights = "All Highlights"
    static let cancel = "Cancel"
    static let children = "Children"
    static let clearImage = "Clear image"
    static let collapse = "Collapse"
    static let copy = "Copy"
    static let dismissView = "Dismiss View"
    static let expand = "Expand"
    static let importImage = "Import image..."
    static let lostConnectionToView = "Lost connection to view"
    static let noElementInspector = "No Element Inspector"
    static let open = "Open"
    static let presentInspector = "Open Inspector..."
    static let preview = "Preview"
    static let searchViews = "Search Hierarchy"

    static func inspect(_ name: Any) -> String {
        "Inspect \(String(describing: name))..."
    }

    static func inspectableViews(_ viewCount: Int, in className: String) -> String {
        switch viewCount {
        case 1:
            return "\(viewCount) inspectable view in \(className)"

        default:
            return "\(viewCount) inspectable views in \(className)"
        }
    }

    static func allResults(count: Int, in elementName: String) -> String {
        switch count {
        case 1:
            return "\(count) Search result in \(elementName)"

        default:
            return "\(count) Search results in \(elementName)"
        }
    }

    static func emptyLayer(with description: String) -> String {
        description
    }

    static func highlight(_ something: String) -> String {
        "Highlight \(something)"
    }

    static func enable(_ something: String) -> String {
        "Enable \(something)"
    }

    static func select(_ something: String) -> String {
        "Select \(something)"
    }

    static func disable(_ something: String) -> String {
        "Disable \(something)"
    }

    static func hide(_ something: String) -> String {
        "Hide \(something)"
    }

    static func show(_ something: String) -> String {
        "Show \(something)"
    }

    static func highlighting(_ something: String) -> String {
        "Highlighting \(something)"
    }

    static func open(_ something: String) -> String {
        "Open \(something)"
    }

    static func copy(_ something: String) -> String {
        "Copy \(something)"
    }
}
