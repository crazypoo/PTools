//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ElementInspectorViewModelProtocol: AnyObject {
    var isFullHeightPresentation: Bool { get set }

    var element: ViewHierarchyElementReference { get }

    var catalog: ViewHierarchyElementCatalog { get }

    var availablePanels: [ElementInspectorPanel] { get }

    var currentPanel: ElementInspectorPanel { get }

    var currentPanelIndex: Int { get }

    var title: String { get }
}

final class ElementInspectorViewModel: ElementInspectorViewModelProtocol {
    let element: ViewHierarchyElementReference

    let catalog: ViewHierarchyElementCatalog

    let availablePanels: [ElementInspectorPanel]

    var currentPanel: ElementInspectorPanel

    var isCollapsed: Bool = false

    var isFullHeightPresentation: Bool = true

    var title: String { element.displayName }

    var currentPanelIndex: Int {
        guard let index = availablePanels.firstIndex(of: currentPanel) else {
            return UISegmentedControl.noSegment
        }
        return index
    }

    init(
        catalog: ViewHierarchyElementCatalog,
        element: ViewHierarchyElementReference,
        preferredPanel: ElementInspectorPanel?,
        availablePanels: [ElementInspectorPanel]
    ) {
        self.catalog = catalog
        self.element = element
        self.availablePanels = availablePanels

        currentPanel = {
            guard
                let preferredPanel = preferredPanel,
                availablePanels.contains(preferredPanel)
            else {
                return availablePanels.first ?? .default
            }
            return preferredPanel
        }()
    }

    var summaryInfo: ViewHierarchyElementSummary {
        ViewHierarchyElementSummary(
            iconImage: element.iconImage,
            isContainer: false,
            subtitle: element.elementDescription,
            title: element.displayName
        )
    }
}
