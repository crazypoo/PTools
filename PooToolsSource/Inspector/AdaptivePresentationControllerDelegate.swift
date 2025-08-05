//
//  AdaptivePresentationControllerDelegate.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public final class AdaptivePresentationControllerDelegate: NSObject, UIAdaptivePresentationControllerDelegate, Dismissable {
    public typealias ModalPresentationStyleProvider = (UIPresentationController, UITraitCollection) -> UIModalPresentationStyle

    public typealias DismissDecisionProvider = (UIPresentationController) -> Bool

    public var dismissHandler: ((AdaptivePresentationControllerDelegate) -> Void)?

    public let adaptivePresentationStyleProvider: ModalPresentationStyleProvider?

    public let shouldDismissProvider: DismissDecisionProvider?

    public let dismissAttemptHandler: PTActionTask?

    public init(onDismiss dismissHandler: ((AdaptivePresentationControllerDelegate) -> Void)? = .none,
                adaptivePresentationStyle adaptivePresentationStyleProvider: ModalPresentationStyleProvider? = .none,
                shouldDismiss shouldDismissProvider: DismissDecisionProvider? = .none,
                onDismissAttempt dismissAttemptHandler: PTActionTask? = .none) {
        self.dismissHandler = dismissHandler
        self.adaptivePresentationStyleProvider = adaptivePresentationStyleProvider
        self.shouldDismissProvider = shouldDismissProvider
        self.dismissAttemptHandler = dismissAttemptHandler
    }

    public func presentationControllerDidDismiss(_: UIPresentationController) {
        dismissHandler?(self)
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController,
                                          traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return adaptivePresentationStyleProvider?(controller, traitCollection) ?? .automatic
    }

    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        shouldDismissProvider?(presentationController) ?? true
    }

    public func presentationControllerDidAttemptToDismiss(_: UIPresentationController) {
        dismissAttemptHandler?()
    }
}
