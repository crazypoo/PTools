//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension ViewHierarchyCoordinator: LayerCommandProtocol {
    private var keyCommandSettings: InspectorConfiguration.KeyCommandSettings {
        Inspector.sharedInstance.configuration.keyCommands
    }

    func availableLayerCommands(for snapshot: ViewHierarchySnapshot) -> [Command] {
        snapshot
            .populatedLayers
            .keys
            .sorted(by: <)
            .enumerated()
            .compactMap { index, layer in
                command(
                    for: layer,
                    at: layerToggleInputRange.lowerBound + index + 1,
                    count: snapshot.populatedLayers[layer]
                )
            }
            .sorted(by: <)
    }

    func command(for layer: ViewHierarchyLayer, at index: Int, count: Int? = .none) -> Command {
        let isSelected = isShowingLayer(layer)

        let icon: UIImage = {
            switch layer {
            case .wireframes:
                return .wireframeAction
            default:
                return .layerAction
            }
        }()

        let layerTitle: String = {
            switch layer {
            case .wireframes:
                let wireframes = "Wireframes"
                return isSelected ? Texts.hide(wireframes) : Texts.show(wireframes)
            default:
                return layer.title
            }
        }()

        let title: String = {
            guard let count = count, count > .zero else { return layerTitle }
            return "\(layerTitle) (\(count))"
        }()

        return Command(
            title: title,
            icon: icon,
            keyInput: String(index),
            modifierFlags: keyCommandSettings.layerToggleModifierFlags,
            isSelected: isSelected
        ) { [weak self] in
            guard let self = self else { return }
            isSelected ? self.removeLayer(layer) : self.installLayer(layer)
        }
    }

    func toggleAllLayersCommands(for snapshot: ViewHierarchySnapshot) -> [Command] {
        var array = [Command]()
        if activeLayers.count > .zero {
            array.append(
                .hideVisibleLayers { [weak self] in
                    guard let self = self else { return }
                    self.removeAllLayers()
                }
            )
        }
        if activeLayers.count < populatedLayers.count {
            array.append(
                .showAllLayers { [weak self] in
                    guard let self = self else { return }
                    self.installAllLayers()
                }
            )
        }
        return array
    }
}
