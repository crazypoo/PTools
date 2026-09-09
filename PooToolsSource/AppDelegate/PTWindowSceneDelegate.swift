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
        let newWindow = UIWindow(windowScene: scene)
        newWindow.tintColor = tint
        newWindow.rootViewController = root
        newWindow.makeKeyAndVisible()
        window = newWindow
    }

    open func makeKeyAndVisible(in scene: UIWindowScene, viewController: UIViewController, tint: UIColor) {
        makeKeyAndVisible(in: scene, createViewControllerHandler: {
            return viewController
        }, tint: tint)
    }
}

public extension PTWindowSceneDelegate {
    @MainActor
    @objc class func sceneDelegate() -> PTWindowSceneDelegate? {
        sceneDelegate(in: PTSceneContext.activeWindow()?.windowScene)
    }

    // English: Resolve the delegate from an explicit scene when the caller already has scene context.
    // Español: Resuelve el delegado desde una escena explícita cuando el llamador ya dispone del contexto.
    // 中文：调用方已有场景上下文时，直接从指定场景解析代理对象。
    @MainActor
    class func sceneDelegate(in scene: UIWindowScene?) -> PTWindowSceneDelegate? {
        scene?.delegate as? PTWindowSceneDelegate
    }
}

#endif
