//
//  PT.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit
import SwifterSwift

open class PTAppWindowsDelegate: PTAppDelegate {
    open var window: UIWindow?
#if POOTOOLS_DEBUG
#endif
    open func makeKeyAndVisible(createViewControllerHandler: () -> UIViewController, tint: UIColor) {
#if POOTOOLS_DEBUG
        if UIApplication.shared.inferredEnvironment != .appStore && UIApplication.shared.inferredEnvironment != .testFlight {
            window = TouchInspectorWindow(frame: UIScreen.main.bounds)
            (window as! TouchInspectorWindow).showTouches = PTCoreUserDefultsWrapper.AppTouchInspectShow
            (window as! TouchInspectorWindow).showHitTesting = PTCoreUserDefultsWrapper.AppTouchInspectShowHits
            window?.tintColor = tint
        } else {
            window = UIWindow.init(frame: UIScreen.main.bounds)
        }
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
    
#if POOTOOLS_DEBUG
    open func createDevFunction(flex:PTActionTask? = nil,inApp:PTActionTask? = nil,Hyperion:PTActionTask? = nil,FoxNet:PTActionTask? = nil) {
        if UIApplication.shared.inferredEnvironment != .appStore && UIApplication.shared.inferredEnvironment != .testFlight {
            let devFunction = PTDevFunction.share
            devFunction.createLabBtn()
            devFunction.flex = {
                if flex != nil {
                    flex!()
                }
            }
            devFunction.inApp = {
                if inApp != nil {
                    inApp!()
                }
            }
            devFunction.HyperioniOS = {
                if Hyperion != nil {
                    Hyperion!()
                }
            }
            devFunction.TestHitShow = { show in
                if self.window is TouchInspectorWindow {
                    (self.window as! TouchInspectorWindow).showHitTesting = show
                }
            }
            devFunction.TestHitTouchesShow = { show in
                if self.window is TouchInspectorWindow {
                    (self.window as! TouchInspectorWindow).showTouches = show
                }
            }
            devFunction.FoxNet = {
                if FoxNet != nil {
                    FoxNet!()
                }
            }
            devFunction.goToAppDevVC = {
                let vc = PTDebugViewController()
                let nav = PTBaseNavControl(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                PTUtils.getCurrentVC().present(nav, animated: true)
            }
        }
    }
#endif
}

extension PTAppWindowsDelegate {
    
    public override class func appDelegate() -> PTAppWindowsDelegate? {
        UIApplication.shared.delegate as? PTAppWindowsDelegate
    }
}
#endif
