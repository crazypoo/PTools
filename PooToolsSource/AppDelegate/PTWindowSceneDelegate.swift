//
//  PTWindowSceneDelegate.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && (os(iOS))
import UIKit

@available(iOS 13.0, *)
open class PTWindowSceneDelegate: UIResponder,UIWindowSceneDelegate {
    
    open var window: UIWindow?

    open func makeKeyAndVisible(in scene: UIWindowScene, createViewControllerHandler: () -> UIViewController, tint: UIColor) {
        window = UIWindow(frame: scene.coordinateSpace.bounds)
        window?.windowScene = scene
        window?.tintColor = tint
        window?.rootViewController = createViewControllerHandler()
        window?.makeKeyAndVisible()
    }

    open func makeKeyAndVisible(in scene: UIWindowScene, viewController: UIViewController, tint: UIColor) {
        makeKeyAndVisible(in: scene, createViewControllerHandler: {
            return viewController
        }, tint: tint)
    }
}

public extension PTWindowSceneDelegate {
    @objc class func sceneDelegate() -> PTWindowSceneDelegate? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let sceneDelegate = windowScene.delegate as? PTWindowSceneDelegate {
            return sceneDelegate
        } else {
            return nil
        }
    }
}

#endif
