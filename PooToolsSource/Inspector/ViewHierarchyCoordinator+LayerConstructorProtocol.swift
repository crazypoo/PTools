//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension ViewHierarchyCoordinator: ViewHierarchyLayerConstructorProtocol {
    var isShowingLayers: Bool {
        visibleReferences.keys.isEmpty == false
    }

    var isShowingAllPopulatedLayers: Bool {
        let populatedLayers = populatedLayers

        for layer in populatedLayers where isShowingLayer(layer) == false {
            return false
        }

        return true
    }

    var activeLayers: [ViewHierarchyLayer] {
        visibleReferences.compactMap { dict -> ViewHierarchyLayer? in
            guard dict.value.isEmpty == false else {
                return nil
            }

            return dict.key
        }
    }

    var availableLayers: [ViewHierarchyLayer] {
        latestSnapshot().availableLayers
            .keys
            .sorted(by: <)
    }

    var populatedLayers: [ViewHierarchyLayer] {
        latestSnapshot().populatedLayers
            .keys
            .sorted(by: <)
    }

    // MARK: - Layer Methods

    func isShowingLayer(_ layer: ViewHierarchyLayer) -> Bool {
        activeLayers.contains(layer)
    }

    // MARK: Install

    func installLayer(_ layer: Inspector.ViewHierarchyLayer) {
        asyncOperation(name: layer.title) {
            let snapshot = self.latestSnapshot()
            self.make(layer: layer, for: snapshot)
        }
    }

    func installAllLayers() {
        asyncOperation(name: Texts.enable(Texts.allHighlights)) {
            let snapshot = self.latestSnapshot()
            for layer in self.populatedLayers {
                self.make(layer: layer, for: snapshot)
            }
        }
    }

    // MARK: Remove

    func removeAllLayers() {
        guard isShowingLayers else {
            return
        }

        asyncOperation(name: Texts.disable(Texts.allHighlights)) {
            self.destroyAllLayers()
        }
    }

    func removeLayer(_ layer: ViewHierarchyLayer) {
        guard isShowingLayers else { return }

        asyncOperation(name: layer.title) {
            self.destroy(layer: layer)
        }
    }

    // MARK: - Make

    @discardableResult
    private func make(layer: ViewHierarchyLayer, for snapshot: ViewHierarchySnapshot) -> Bool {
        guard visibleReferences[layer] == nil else {
            return false
        }

        let elementKeys = layer.makeKeysForInspectableElements(in: snapshot)

        visibleReferences.updateValue(elementKeys, forKey: layer)

        return true
    }

    // MARK: - Destroy

    @discardableResult
    private func destroyAllLayers() -> Bool {
        visibleReferences.removeAll()

        return true
    }

    @discardableResult
    private func destroy(layer: ViewHierarchyLayer) -> Bool {
        visibleReferences.removeValue(forKey: layer)

        return true
    }

    // MARK: - LayerView Methods

    func updateLayerViews(to newValue: [ViewHierarchyElementKey: LayerView],
                          from oldValue: [ViewHierarchyElementKey: LayerView])
    {
        let viewReferences = Set(newValue.keys)

        let oldViewReferences = Set(oldValue.keys)

        let removedKeys = oldViewReferences.subtracting(viewReferences)

        let newKeys = viewReferences.subtracting(oldViewReferences)

        removedKeys.forEach { oldKey in
            guard let layerView = oldValue[oldKey] else {
                return
            }

            if let highlightView = layerView as? InspectorHighlightView {
                highlightView.perform(.dismiss) { _ in
                    highlightView.removeFromSuperview()
                }
            }
            else {
                layerView.removeFromSuperview()
            }
        }

        newKeys.forEach { newKey in
            guard
                let reference = newKey.reference,
                let layerView = newValue[newKey],
                let underlyingView = reference.underlyingView
            else {
                return
            }

            underlyingView.installView(
                layerView,
                .autoResizingMask,
                position: reference.canPresentOnTop && layerView.shouldPresentOnTop ? .inFront : .behind
            )
        }
    }

    // MARK: - Reference Management

    func removeReferences(for removedLayers: Set<ViewHierarchyLayer>,
                          in oldValue: [ViewHierarchyLayer: [ViewHierarchyElementKey]])
    {
        var removedReferences = [ViewHierarchyElementKey]()

        removedLayers.forEach { layer in
            oldValue[layer]?.forEach {
                removedReferences.append($0)
            }
        }

        for (layer, elements) in visibleReferences where layer != .wireframes {
            elements.forEach {
                if let index = removedReferences.firstIndex(of: $0) {
                    removedReferences.remove(at: index)
                }
            }
        }

        removedReferences.forEach { removedReference in
            highlightViews.removeValue(forKey: removedReference)
        }

        if removedLayers.contains(.wireframes) {
            wireframeViews.removeAll()
        }
    }

    func removeWireframeView(for key: ViewHierarchyElementKey) {
        wireframeViews[key]?.removeFromSuperview()
        wireframeViews.removeValue(forKey: key)
    }

    func removeHighlightView(for key: ViewHierarchyElementKey) {
        highlightViews[key]?.removeFromSuperview()
        highlightViews.removeValue(forKey: key)
    }

    func addHighlightView(for key: ViewHierarchyElementKey, with colorScheme: ViewHierarchyColorScheme) {
        guard
            highlightViews[key] == nil,
            let reference = key.reference,
            let rootView = reference.underlyingView
        else {
            return
        }

        let highlightView = InspectorHighlightView(
            frame: rootView.bounds,
            name: rootView.elementName,
            colorScheme: colorScheme,
            element: reference
        ).then {
            $0.delegate = self
        }

        highlightViews[key] = highlightView
    }

    func addWireframeView(for key: ViewHierarchyElementKey, with colorScheme: ViewHierarchyColorScheme) {
        guard
            highlightViews[key] == nil,
            let reference = key.reference,
            let rootView = reference.underlyingView
        else {
            return
        }

        let wireframeView = WireframeView(
            frame: rootView.bounds,
            element: reference
        ).then {
            $0.delegate = self
        }

        wireframeViews[key] = wireframeView
    }

    func addReferences(for newLayers: Set<ViewHierarchyLayer>, with colorScheme: ViewHierarchyColorScheme) {
        for newLayer in newLayers {
            guard let elements = visibleReferences[newLayer] else { continue }

            if newLayer.showLabels {
                elements.forEach { addHighlightView(for: $0, with: colorScheme) }
            }
            else {
                elements.forEach { addWireframeView(for: $0, with: colorScheme) }
            }
        }
    }
}
