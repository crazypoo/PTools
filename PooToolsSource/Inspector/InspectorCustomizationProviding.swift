//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public protocol InspectorCustomizationProviding {
    /// Command groups act as sections on the Inspector interface. You can have as many groups, with as many actions as you would like.
    var commandGroups: [Inspector.CommandsGroup]? { get }

    /// Show your own icons for any of your classes or override any of the default ones.
    var elementIconProvider: Inspector.ElementIconProvider? { get }

    /// Element Libraries are entities that conform to `InspectorElementLibraryProtocol` and represent a section inside an element's inspector panel. You can have multiple sections for the same element type in different `ElementPanelTypes`.
    var elementLibraries: [Inspector.ElementPanelType: [InspectorElementLibraryProtocol]]? { get }

    /// Returns colors associated with view instances, types, or any other conditions you might think of.
    var elementColorProvider: Inspector.ElementColorProvider? { get }

    /// `ViewHierarchyLayer` are toggleable and shown in the `Highlight views` section on the Inspector interface, and also can be triggered with `Ctrl + Shift + 1 - 9`. Add your own custom inspector layers.
    var viewHierarchyLayers: [Inspector.ViewHierarchyLayer]? { get }
}

// MARK: - Swift UI

protocol InspectorSwiftUIHost: InspectorCustomizationProviding {
    func insectorViewWillFinishPresentation()
}
