//
//  PT.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

open class PTAppWindowsDelegate: PTAppDelegate {
    open var window: UIWindow?
#if POOTOOLS_DEBUG
    #if DEBUG
        open var devFunction:PTDevFunction = PTDevFunction()
    #endif
#endif
    open func makeKeyAndVisible(createViewControllerHandler: () -> UIViewController, tint: UIColor) {
#if POOTOOLS_DEBUG
    #if DEBUG
        window = TouchInspectorWindow(frame: UIScreen.main.bounds)
        (window as! TouchInspectorWindow).showTouches = devFunction.touchesType
        (window as! TouchInspectorWindow).showHitTesting = devFunction.touchesTestHit
        window?.tintColor = tint
    #else
        window = UIWindow.init(frame: UIScreen.main.bounds)
    #endif
#else
        window = UIWindow.init(frame: UIScreen.main.bounds)
#endif
        window?.tintColor = tint
        window?.rootViewController = createViewControllerHandler()
        window?.makeKeyAndVisible()
    }

    open func makeKeyAndVisible(viewController: UIViewController, tint: UIColor) {
        makeKeyAndVisible(createViewControllerHandler: {
            return viewController
        }, tint: tint)
    }
}

extension PTAppWindowsDelegate {
    
    public override class func appDelegate() -> PTAppWindowsDelegate? {
        UIApplication.shared.delegate as? PTAppWindowsDelegate
    }
}
#endif
