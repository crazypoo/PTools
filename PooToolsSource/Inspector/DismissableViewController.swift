//
//  DismissableViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
#if SWIFT_PACKAGE
import ptools
#endif

open class DismissableViewController: UIViewController, @MainActor Dismissable {
    open var dismissHandler: ((DismissableViewController) -> Void)?

    override open func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        guard isViewLoaded, parent == .none else { return }
        dismissHandler?(self)
    }

}
