//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol InspectorViewCoordinatorSwiftUIDelegate: AnyObject {
    func inspectorViewCoordinator(_ coordinator: InspectorViewCoordinator, willFinishWith command: InspectorCommand?)
}

protocol InspectorViewCoordinatorDelegate: AnyObject {
    func inspectorViewCoordinator(_ coordinator: InspectorViewCoordinator, execute command: InspectorCommand?)
}

typealias CommandGroupsProvider = () -> CommandsGroups?

struct InspectorViewDependencies {
    var snapshot: ViewHierarchySnapshot
    var shouldAnimateKeyboard: Bool
    var commandGroupsProvider: CommandGroupsProvider
}

final class InspectorViewCoordinator: Coordinator<InspectorViewDependencies, UIViewController, UIViewController>, DataReloadingProtocol {
    weak var swiftUIDelegate: InspectorViewCoordinatorSwiftUIDelegate?

    weak var delegate: InspectorViewCoordinatorDelegate?

    private lazy var inspectorViewController: InspectorViewController = {
        let viewModel = HierarchyInspectorViewModel(
            commandGroupsProvider: dependencies.commandGroupsProvider,
            snapshot: dependencies.snapshot,
            shouldAnimateKeyboard: dependencies.shouldAnimateKeyboard
        )

        return InspectorViewController(viewModel: viewModel).then {
            $0.modalPresentationStyle = .overCurrentContext
            $0.modalTransitionStyle = .crossDissolve
            $0.delegate = self
        }
    }()

    override func loadContent() -> UIViewController? {
        inspectorViewController
    }

    func reloadData() {
        inspectorViewController.reloadData()
    }

    func finish(command: InspectorCommand?) {
        removeFromParent()

        if let swiftUIDelegate = swiftUIDelegate {
            swiftUIDelegate.inspectorViewCoordinator(self, willFinishWith: command)
            return
        }

        delegate?.inspectorViewCoordinator(self, execute: command)
    }
}

// MARK: - InspectorViewControllerDelegate

extension InspectorViewCoordinator: InspectorViewControllerDelegate {
    func inspectorViewController(_ viewController: InspectorViewController, didSelect command: InspectorCommand?) {
        finish(command: command)
    }

    func inspectorViewControllerDidFinish(_ viewController: InspectorViewController) {
        finish(command: .none)
    }
}
