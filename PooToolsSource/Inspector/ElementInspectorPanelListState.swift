//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum ElementInspectorPanelListState: Swift.CaseIterable, MenuContentProtocol {
    case allCollapsed, firstExpanded, mixed, allExpanded

    func next() -> Self? {
        switch self {
        case .allCollapsed:
            return .firstExpanded
        case .mixed, .firstExpanded:
            return .allExpanded
        case .allExpanded:
            return .none
        }
    }

    func previous() -> Self? {
        switch self {
        case .allCollapsed:
            return .none
        case .firstExpanded:
            return .allCollapsed
        case .mixed:
            return .allCollapsed
        case .allExpanded:
            return .firstExpanded
        }
    }

    // MARK: - MenuContentProtocol

    static func allCases(for element: ViewHierarchyElementReference) -> [ElementInspectorPanelListState] { [] }

    var title: String {
        switch self {
        case .allCollapsed:
            return "Collapse All"
        case .firstExpanded:
            return "Expand First"
        case .mixed:
            return "Mixed selection"
        case .allExpanded:
            return "Expand All"
        }
    }

    var image: UIImage? {
        switch self {
        case .allCollapsed:
            return .collapseMirroredSymbol
        case .firstExpanded:
            return .expandSymbol
        case .mixed:
            return nil
        case .allExpanded:
            return .expandSymbol
        }
    }
}
