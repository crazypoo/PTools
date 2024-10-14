//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import SwiftUI

final class InspectorUI: UIViewControllerRepresentable, InspectorSwiftUIHost {
    // MARK: - InspectorSwiftUIHostable

    let viewHierarchyLayers: [Inspector.ViewHierarchyLayer]?

    let elementColorProvider: Inspector.ElementColorProvider?

    let commandGroups: [Inspector.CommandsGroup]?

    let elementLibraries: [Inspector.ElementPanelType: [InspectorElementLibraryProtocol]]?

    let elementIconProvider: Inspector.ElementIconProvider?

    var didFinish: (() -> Void)?

    // MARK: - Initializer

    private init(
        layers: [Inspector.ViewHierarchyLayer]?,
        colorScheme: Inspector.ElementColorProvider?,
        commandGroups: [Inspector.CommandsGroup]?,
        elementLibraries: [Inspector.ElementPanelType: [InspectorElementLibraryProtocol]]?,
        elementIconProvider: Inspector.ElementIconProvider?,
        didFinish: (() -> Void)?
    ) {
        viewHierarchyLayers = layers
        elementColorProvider = colorScheme
        self.commandGroups = commandGroups
        self.elementLibraries = elementLibraries
        self.elementIconProvider = elementIconProvider
        self.didFinish = didFinish
    }

    private(set) static var sharedInstance: InspectorUI?

    static func shared(
        layers: [Inspector.ViewHierarchyLayer]?,
        colorScheme: Inspector.ElementColorProvider?,
        commandGroups: [Inspector.CommandsGroup]?,
        elementLibraries: [Inspector.ElementPanelType: [InspectorElementLibraryProtocol]]?,
        elementIconProvider: Inspector.ElementIconProvider?,
        didFinish: (() -> Void)?
    ) -> InspectorUI {
        if let sharedInstance = sharedInstance {
            return sharedInstance
        }
        let instance = self.init(
            layers: layers,
            colorScheme: colorScheme,
            commandGroups: commandGroups,
            elementLibraries: elementLibraries,
            elementIconProvider: elementIconProvider,
            didFinish: didFinish
        )
        sharedInstance = instance
        return instance
    }

    func insectorViewWillFinishPresentation() {
        didFinish?()
    }

    func alertController(
        title: String?,
        message: String? = nil,
        preferredStyle: UIAlertController.Style = .alert
    ) -> UIAlertController {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: preferredStyle
        )

        alertController.addAction(
            UIAlertAction(
                title: "Dismiss",
                style: .cancel,
                handler: { _ in
                    self.didFinish?()
                }
            )
        )

        return alertController
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let inspector = Inspector.sharedInstance

        if inspector.state == .idle {
            inspector.customization = self
            inspector.start(swiftUI: self)
        }

        guard
            let presenter = ViewHierarchy.shared.topPresentableViewController,
            let coordinator = inspector.manager?.makeInspectorViewCoordinator(presentedBy: presenter)
        else {
            return alertController(title: "Couldn't present inspector")
        }

        inspector.manager?.addChild(coordinator)
        return coordinator.start()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
