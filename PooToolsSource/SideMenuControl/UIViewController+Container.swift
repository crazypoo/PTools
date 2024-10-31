//
//  UIViewController+Container.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIViewController {

    var sideMenuController: PTSideMenuControl? {
        return findSideMenuController(from: self)
    }

    fileprivate func findSideMenuController(from viewController: UIViewController) -> PTSideMenuControl? {
        var sourceViewController: UIViewController? = viewController
        repeat {
            sourceViewController = sourceViewController?.parent
            if let sideMenuController = sourceViewController as? PTSideMenuControl {
                return sideMenuController
            }
        } while (sourceViewController != nil)
        return nil
    }
    
    func load(_ viewController: UIViewController?, on view: UIView) {
        guard let viewController = viewController else {
            return
        }

        addChild(viewController)

        viewController.view.frame = view.bounds
        viewController.view.translatesAutoresizingMaskIntoConstraints = true
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(viewController.view)

        viewController.didMove(toParent: self)
    }

    func unload(_ viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }

        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}
