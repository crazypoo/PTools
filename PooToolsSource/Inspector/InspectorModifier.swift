//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14.0, *)
public extension View {
    func inspect(
        isPresented: Binding<Bool>,
        layers: [Inspector.ViewHierarchyLayer]? = nil,
        colorScheme: Inspector.ElementColorProvider? = nil,
        commandGroups: [Inspector.CommandsGroup]? = nil,
        elementLibraries: [Inspector.ElementPanelType: [InspectorElementLibraryProtocol]]? = nil,
        elementIconProvider: Inspector.ElementIconProvider? = nil
    ) -> some View {
        modifier(
            InspectorModifier(
                isPresented: isPresented,
                viewHierarchyLayers: layers,
                elementColorProvider: colorScheme,
                commandGroups: commandGroups,
                elementLibraries: elementLibraries,
                inspectorIconProvider: elementIconProvider
            )
        )
    }
}

@available(iOS 14.0, *)
struct InspectorModifier: ViewModifier {
    @Binding var isPresented: Bool

    var viewHierarchyLayers: [Inspector.ViewHierarchyLayer]?

    var elementColorProvider: Inspector.ElementColorProvider?

    var commandGroups: [Inspector.CommandsGroup]?

    var elementLibraries: [Inspector.ElementPanelType: [InspectorElementLibraryProtocol]]?

    var inspectorIconProvider: Inspector.ElementIconProvider?

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                InspectorUI.shared(
                    layers: viewHierarchyLayers,
                    colorScheme: elementColorProvider,
                    commandGroups: commandGroups,
                    elementLibraries: elementLibraries,
                    elementIconProvider: inspectorIconProvider,
                    didFinish: {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
            }
        }
    }
}
#endif
