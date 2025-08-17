//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension ViewHierarchyCoordinator: AsyncOperationProtocol {
    func asyncOperation(name: String, execute closure: @escaping Closure) {
        let mainTask = MainThreadOperation(name: name, closure: closure)

        guard let keyWindow = AppWindows else {
            return operationQueue.addOperation(mainTask)
        }

        let loaderView = loaderView(title: name)

        let hideLoaderTask = hideLoaderTask(loaderView)

        let showLoaderTask = showLoaderTask(loaderView, in: keyWindow) { [weak self] _ in
            guard let self = self else { return }

            self.operationQueue.addOperation(mainTask)
            self.operationQueue.addOperation(hideLoaderTask)
        }

        operationQueue.addOperation(showLoaderTask)
    }

    private func showLoaderTask(_ loaderView: LoaderView, in window: UIWindow, completion: @escaping PTBoolTask) -> MainThreadOperation {
        MainThreadOperation(name: "show loader") {
            window.addSubview(loaderView)
            window.installView(loaderView, .centerXY)

            UIView.animate(
                withDuration: .short,
                animations: {
                    loaderView.transform = .identity
                },
                completion: completion
            )
        }
    }

    private func hideLoaderTask(_ loaderView: LoaderView) -> MainThreadOperation {
        MainThreadOperation(name: "hide loader") {
            loaderView.done()

            UIView.animate(
                withDuration: .long,
                delay: .long,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: {
                    loaderView.alpha = .zero
                },
                completion: { _ in
                    loaderView.removeFromSuperview()
                }
            )
        }
    }

    private func loaderView(title: String) -> LoaderView {
        LoaderView(colorScheme: dependencies.colorScheme).then {
            $0.accessibilityIdentifier = title
            $0.transform = .init(scaleX: .zero, y: .zero)
        }
    }
}
