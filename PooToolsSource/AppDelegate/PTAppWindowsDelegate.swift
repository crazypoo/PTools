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
    
    open func makeKeyAndVisible(createViewControllerHandler: () -> UIViewController, tint: UIColor) {
        let frame = UIScreen.main.bounds
        window = UIWindow(frame: frame)
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

#endif
