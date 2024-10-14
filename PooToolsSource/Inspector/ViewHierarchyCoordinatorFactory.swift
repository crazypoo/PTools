//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ViewHierarchyCoordinatorFactoryProtocol {
    static func makeCoordinator(with windows: [UIWindow],
                                operationQueue: OperationQueue,
                                customization: InspectorCustomizationProviding?,
                                defaultLayers: [Inspector.ViewHierarchyLayer]) -> ViewHierarchyCoordinator
}

enum ViewHierarchyCoordinatorFactory: ViewHierarchyCoordinatorFactoryProtocol {
    static func makeCoordinator(with windows: [UIWindow],
                                operationQueue: OperationQueue,
                                customization: InspectorCustomizationProviding?,
                                defaultLayers: [Inspector.ViewHierarchyLayer]) -> ViewHierarchyCoordinator
    {
        var layers: [Inspector.ViewHierarchyLayer] {
            var layers = defaultLayers

            if let customLayers = customization?.viewHierarchyLayers {
                layers.append(contentsOf: customLayers)
            }

            return layers.uniqueValues()
        }

        var colorScheme: ViewHierarchyColorScheme {
            guard let colorScheme = customization?.elementColorProvider else {
                return .default
            }

            return ViewHierarchyColorScheme { view in
                guard let color = colorScheme.value(for: view) else {
                    return ViewHierarchyColorScheme.default.value(for: view)
                }

                return color
            }
        }

        var catalog: ViewHierarchyElementCatalog {
            .init(
                libraries: libraries,
                iconProvider: .init { object in
                    if
                        let elementIconProvider = customization?.elementIconProvider,
                        let view = object as? UIView,
                        let customIcon = elementIconProvider.value(for: view)
                    {
                        return customIcon
                    }
                    return ViewHierarchyElementIconProvider.default.value(for: object)
                }
            )
        }

        var libraries: [ElementInspectorPanel: [InspectorElementLibraryProtocol]] {
            var dictionary: [ElementInspectorPanel: [InspectorElementLibraryProtocol]] = [:]

            customization?.elementLibraries?.keys.forEach { customPanel in
                dictionary[customPanel.rawValue] = customization?.elementLibraries?[customPanel]
            }

            ElementInspectorPanel.allCases.forEach { panel in
                var libraries = dictionary[panel] ?? []
                libraries.append(contentsOf: panel.defaultLibraries)
                dictionary[panel] = libraries
            }

            return dictionary
        }

        let coordinator = ViewHierarchyCoordinator(
            .init(
                catalog: catalog,
                colorScheme: colorScheme,
                layers: layers
            ),
            presentedBy: operationQueue
        )

        return coordinator
    }
}

private extension ElementInspectorPanel {
    var defaultLibraries: [InspectorElementLibraryProtocol] {
        switch self {
        case .identity: return DefaultElementIdentityLibrary.allCases
        case .attributes: return DefaultElementAttributesLibrary.allCases
        case .size: return DefaultElementSizeLibrary.allCases
        case .children: return []
        }
    }
}
