//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

struct ManagerDependencies {
    var configuration: InspectorConfiguration
    var coordinatorFactory: ViewHierarchyCoordinatorFactoryProtocol.Type
    var customization: InspectorCustomizationProviding?
    var viewHierarchy: ViewHierarchyRepresentable
    var swiftUIhost: InspectorSwiftUIHost?
}

final class Manager: Coordinator<ManagerDependencies, OperationQueue, Void> {
    var snapshot: ViewHierarchySnapshot { viewHierarchyCoordinator.latestSnapshot() }
    var keyWindow: UIWindow? { dependencies.viewHierarchy.keyWindow }
    var catalog: ViewHierarchyElementCatalog { viewHierarchyCoordinator.dependencies.catalog }

    lazy var keyCommandsStore = ExpirableStore<[UIKeyCommand]>(lifespan: dependencies.configuration.snapshotExpirationTimeInterval)

    @MainActor func dismissInspectorViewIfNeeded(_ closure: @escaping PTActionTask) {
        let coordinators = children.compactMap { $0 as? InspectorViewCoordinator }

        if coordinators.isEmpty { return closure() }

        for coordinator in coordinators {
            coordinator.removeFromParent()
            coordinator.start().dismiss(animated: false)
        }

        DispatchQueue.main.async(execute: closure)
    }

    private(set) lazy var viewHierarchyCoordinator: ViewHierarchyCoordinator = {
        let coordinator = dependencies.coordinatorFactory.makeCoordinator(
            with: dependencies.viewHierarchy.windows,
            operationQueue: operationQueue,
            customization: dependencies.customization,
            defaultLayers: dependencies.configuration.defaultLayers.sorted(by: <)
        )
        coordinator.delegate = self
        return coordinator
    }()

    // MARK: - Init

    override init(
        _ dependencies: ManagerDependencies,
        presentedBy presenter: OperationQueue,
        parent: CoordinatorProtocol? = nil,
        children: [CoordinatorProtocol] = []
    ) {
        super.init(
            dependencies,
            presentedBy: presenter,
            parent: parent,
            children: children
        )

        if dependencies.configuration.enableLayoutSubviewsSwizzling {
            UIView.startSwizzling()
        }
    }

    deinit {
        operationQueue.cancelAllOperations()

        viewHierarchyCoordinator.removeAllLayers()

        children.forEach { child in
            (child as? DismissablePresentationProtocol)?.dismissPresentation(animated: true)
            child.removeFromParent()
        }
    }

    override func loadContent() -> Void? {
        viewHierarchyCoordinator.start()
    }
}

// MARK: - AsyncOperationProtocol

extension Manager: AsyncOperationProtocol {
    func asyncOperation(name: String = #function, execute closure: @escaping Closure) {
        operationQueue.addOperation(
            MainThreadAsyncOperation(name: name, closure: closure)
        )
    }
}
