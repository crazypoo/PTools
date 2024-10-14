//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class ElementInspectorPanelViewController: UIViewController, ElementInspectorAppearanceProviding {
    // MARK: - Layout

    open var panelScrollView: UIScrollView? { nil }

    private var needsLayout = true

    var isFullHeightPresentation: Bool = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard needsLayout else { return }

        needsLayout = false

        updatePreferredContentSize()
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        updateVerticalPresentationState()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        updateVerticalPresentationState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateVerticalPresentationState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateVerticalPresentationState()
    }

    @objc
    private func updateVerticalPresentationState() {
        guard let parent = parent else { return }

        let newValue: Bool = {
            if let popover = parent.popoverPresentationController {
                #if swift(>=5.5)
                if #available(iOS 15.0, *) {
                    return popover.adaptiveSheetPresentationController.selectedDetentIdentifier == .large
                }
                #endif

                _ = popover

                return false
            }

            return true
        }()

        guard newValue != isFullHeightPresentation else { return }

        isFullHeightPresentation = newValue
    }

    @objc
    func updatePreferredContentSize() {
        preferredContentSize = calculatePreferredContentSize()
    }

    func calculatePreferredContentSize() -> CGSize {
        if isViewLoaded {
            return view.systemLayoutSizeFitting(
                Inspector.sharedInstance.configuration.elementInspectorConfiguration.panelPreferredCompressedSize,
                withHorizontalFittingPriority: .defaultHigh,
                verticalFittingPriority: .fittingSizeLevel
            )
        }
        else {
            return .zero
        }
    }
}
