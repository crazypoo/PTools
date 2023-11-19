//
//  UINavigationController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit
import SwifterSwift

public extension UINavigationController {
    
    convenience init(rootViewController: UIViewController, prefersLargeTitles: Bool) {
        self.init(rootViewController: rootViewController)
        #if os(iOS)
        navigationBar.prefersLargeTitles = prefersLargeTitles
        #endif
    }    
    
//    func pt_pushViewController(_ vc:UIViewController,completion:(()->Void)? = nil) {
//        self.pushViewController(vc, completion: completion)
//#if POOTOOLS_DEBUG
//        let share = LocalConsole.shared
//        if share.isVisible {
//            SwizzleTool().swizzleDidAddSubview {
//                // Configure console window.
//                PTUtils.fetchWindow()?.bringSubviewToFront(share.consoleViewController.view)
//            }
//        }
////#else
////        if UIApplication.applicationEnvironment() != .appStore || UIApplication.applicationEnvironment() != .testFlight {
////            if PTCoreUserDefultsWrapper.AppDebugMode {
////                vc.modalPresentationStyle = .formSheet
////            }
////        }
//#endif
//    }
}
#endif
