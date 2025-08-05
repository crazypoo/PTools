//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension Manager: InspectorViewCoordinatorDelegate {
    func inspectorViewCoordinator(_ coordinator: InspectorViewCoordinator, execute command: InspectorCommand?) {
        coordinator.start().dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.execute(command)
        }
    }
}

extension Manager: InspectorViewCoordinatorSwiftUIDelegate {
    func inspectorViewCoordinator(_ coordinator: InspectorViewCoordinator,
                                  willFinishWith command: InspectorCommand?)
    {
        dependencies.swiftUIhost?.insectorViewWillFinishPresentation()
        execute(command)
    }
}

extension Manager {
    private func execute(_ command: InspectorCommand?) {
        guard let command = command else { return }

        asyncOperation { [weak self] in
            switch command {
            case let .execute(closure):
                closure()

            case let .inspect(reference):
                guard
                    let self = self,
                    let sourceView = reference.underlyingView
                else { return }

                self.startElementInspectorCoordinator(
                    for: reference,
                    panel: .default,
                    from: sourceView,
                    animated: true
                )
            }
        }
    }

    @MainActor func presentInspector(animated: Bool) {
        guard let presenter = dependencies.viewHierarchy.topPresentableViewController else { return }
        return presentInspector(animated: animated, from: presenter)
    }

    @MainActor func presentInspector(animated: Bool, from presenter: UIViewController) {
        dismissInspectorViewIfNeeded { [weak self] in
            guard let self = self else { return }

            let coordinator = self.makeInspectorViewCoordinator(presentedBy: presenter)

            presenter.present(coordinator.start(), animated: animated) { [weak self] in
                self?.addChild(coordinator)
            }
        }
    }

    func makeInspectorViewCoordinator(presentedBy presenter: UIViewController) -> InspectorViewCoordinator {
        let coordinator = InspectorViewCoordinator(
            .init(
                snapshot: snapshot,
                shouldAnimateKeyboard: dependencies.swiftUIhost == nil,
                commandGroupsProvider: { [weak self] in
                    guard let self = self else { return .none }
                    return self.commandGroups
                }
            ),
            presentedBy: presenter
        )

        if dependencies.swiftUIhost != nil {
            coordinator.swiftUIDelegate = self
        }
        else {
            coordinator.delegate = self
        }

        return coordinator
    }
}
