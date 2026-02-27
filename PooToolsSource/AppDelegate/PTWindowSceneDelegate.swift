//
//  PTWindowSceneDelegate.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && (os(iOS))
import UIKit

open class PTWindowSceneDelegate: UIResponder,UIWindowSceneDelegate {
    
    open var window: UIWindow?

    open func makeKeyAndVisible(in scene: UIWindowScene, createViewControllerHandler: () -> UIViewController, tint: UIColor) {
        let root = createViewControllerHandler()
        window = UIWindow(windowScene:scene)
        window!.tintColor = tint
        window!.rootViewController = root
        window!.makeKeyAndVisible()
    }

    open func makeKeyAndVisible(in scene: UIWindowScene, viewController: UIViewController, tint: UIColor) {
        makeKeyAndVisible(in: scene, createViewControllerHandler: {
            return viewController
        }, tint: tint)
    }
}

public extension PTWindowSceneDelegate {
    @objc class func sceneDelegate() -> PTWindowSceneDelegate? {
        return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState != .background }?
                .delegate as? PTWindowSceneDelegate
    }
}

#endif
