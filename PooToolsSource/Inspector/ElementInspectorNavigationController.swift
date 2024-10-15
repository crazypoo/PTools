//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ElementInspectorNavigationControllerDismissDelegate: AnyObject {
    func elementInspectorNavigationControllerDidFinish(_ navigationController: ElementInspectorNavigationController)
}

class ElementInspectorNavigationController: UINavigationController, InternalViewProtocol, ElementInspectorAppearanceProviding {
    weak var dismissDelegate: ElementInspectorNavigationControllerDismissDelegate?

    var shouldAdaptModalPresentation: Bool = true {
        didSet {
            if shouldAdaptModalPresentation {
                if popoverPresentationController?.delegate === self {
                    popoverPresentationController?.delegate = nil
                }
                return
            }

            popoverPresentationController?.delegate = self
        }
    }

    override func loadView() {
        super.loadView()
        let container = BaseView()
        container.installView(view)
        container.frame = view.frame
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.tintColor = colorStyle.textColor

        view.installView(blurView, position: .behind)

        navigationBar.barTintColor = colorStyle.highlightBackgroundColor

        navigationBar.tintColor = view.tintColor

        navigationBar.directionalLayoutMargins.update(
            leading: elementInspectorAppearance.horizontalMargins,
            trailing: elementInspectorAppearance.horizontalMargins
        )

        navigationBar.largeTitleTextAttributes = [
            .font: elementInspectorAppearance.titleFont(forRelativeDepth: .zero),
            .foregroundColor: colorStyle.textColor
        ]

        addKeyCommand(dismissModalKeyCommand(action: #selector(finish)))

        becomeFirstResponder()
    }

    private(set) lazy var blurView = UIVisualEffectView(
        effect: UIBlurEffect(style: colorStyle.blurStyle)
    )

    override var canBecomeFirstResponder: Bool { true }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        // Async here is preventing weird popover behavior.
        PTGCDManager.gcdMain {
            self.preferredContentSize = container.preferredContentSize
        }
    }

    @objc private func finish() {
        dismissDelegate?.elementInspectorNavigationControllerDidFinish(self)
    }
}
