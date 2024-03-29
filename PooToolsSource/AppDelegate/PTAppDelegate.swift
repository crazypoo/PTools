//
//  PTAppDelegate.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//
#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

open class PTAppDelegate: UIResponder,UIApplicationDelegate {
    open var window: UIWindow?
}

extension PTAppDelegate {
    @objc class open func appDelegate() -> PTAppDelegate? {
        UIApplication.shared.delegate as? PTAppDelegate
    }
}

#endif
