//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ViewHierarchyLayerConstructorProtocol {
    var isShowingLayers: Bool { get }

    var isShowingAllPopulatedLayers: Bool { get }

    var activeLayers: [ViewHierarchyLayer] { get }

    var availableLayers: [ViewHierarchyLayer] { get }

    var populatedLayers: [ViewHierarchyLayer] { get }

    // MARK: - Layer Methods

    func isShowingLayer(_ layer: ViewHierarchyLayer) -> Bool

    func installLayer(_ layer: Inspector.ViewHierarchyLayer)

    func removeLayer(_ layer: Inspector.ViewHierarchyLayer)

    func installAllLayers()

    func removeAllLayers()

    // MARK: - LayerView Methods

    func updateLayerViews(to newValue: [ViewHierarchyElementKey: LayerView],
                          from oldValue: [ViewHierarchyElementKey: LayerView])

    // MARK: - Element Reference Methods

    func removeReferences(for removedLayers: Set<ViewHierarchyLayer>,
                          in oldValue: [ViewHierarchyLayer: [ViewHierarchyElementKey]])

    func addReferences(for newLayers: Set<ViewHierarchyLayer>,
                       with colorScheme: ViewHierarchyColorScheme)
}

class ViewHierarchyElementKey: Hashable {
    private(set) weak var reference: ViewHierarchyElementReference?
    private let viewIdentifier: ObjectIdentifier

    init?(reference: ViewHierarchyElementReference) {
        guard let viewIdentifier = reference.underlyingView?.objectIdentifier else {
            return nil
        }

        self.reference = reference
        self.viewIdentifier = viewIdentifier
    }

    static func == (lhs: ViewHierarchyElementKey, rhs: ViewHierarchyElementKey) -> Bool {
        lhs.viewIdentifier == rhs.viewIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(viewIdentifier)
    }
}
