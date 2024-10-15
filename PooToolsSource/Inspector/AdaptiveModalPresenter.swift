//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class AdaptiveModalPresenter: NSObject {
    enum Detent {
        case medium, large
    }

    private let presentationStyleProvider: (UIPresentationController, UITraitCollection) -> UIModalPresentationStyle
    private let onChangeSelectedDetentHandler: (Detent?) -> Void
    private let onDismissHandler: (UIPresentationController) -> Void

    init(presentationStyle: @escaping (UIPresentationController, UITraitCollection) -> UIModalPresentationStyle, onChangeSelectedDetent: @escaping (Detent?) -> Void, onDismiss: @escaping ((UIPresentationController) -> Void)) {
        onChangeSelectedDetentHandler = onChangeSelectedDetent
        presentationStyleProvider = presentationStyle
        onDismissHandler = onDismiss
    }
}

extension AdaptiveModalPresenter: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        presentationStyleProvider(controller, traitCollection)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismissHandler(presentationController)
    }
}

extension AdaptiveModalPresenter: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        onDismissHandler(popoverPresentationController)
    }
}

#if swift(>=5.5)
@available(iOS 15.0, *)
extension AdaptiveModalPresenter: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        onChangeSelectedDetentHandler(
            sheetPresentationController.selectedDetentIdentifier == .medium ? .medium : .large
        )
    }
}
#endif
