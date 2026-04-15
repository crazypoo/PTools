//
//  UIViewController+Swizzled.swift
//  TestVCSwizzled_Swift
//
//  Created by yang on 2016/12/26.
//  Copyright © 2016年 yang. All rights reserved.
//

import UIKit

var isSwizzed: Bool = false
var logTag: String = ""

public extension UIViewController {
    
    // MARK: - Public Methods
    class func swizzIt() {
        if (isSwizzed) {
            return
        }
        
        Swizzle(UIViewController.self) {
            #selector(self.viewDidAppear(_:)) <-> #selector(self.swizzled_viewDidAppear(animated:))
        }

        isSwizzed = true
    }
    
    class func swizzItWithTag(tag: String?) {
        if (tag == nil) {
            return
        }
        
        logTag = tag!
        swizzIt()
    }
    
    class func undoSwizz() {
        if (!isSwizzed) {
            return
        }
        
        Swizzle(UIViewController.self) {
            #selector(self.swizzled_viewDidAppear(animated:)) <-> #selector(self.viewDidAppear(_:))
        }
        
        isSwizzed = false
    }
    
    // MARK: - Init
//    open override class func `init`() {
//        // make sure this isn't a subclass
//        guard self === UIViewController.self else { return }
//        
//        isSwizzed = false
//    }
    
    // MARK: - Util Methods
    @objc fileprivate func swizzled_viewDidAppear(animated: Bool) {
        printPath()
        swizzled_viewDidAppear(animated: animated)
    }
    
    private func logWithLevel(level: UInt) {
        var paddingItems = "";
        for _ in 0...level {
            paddingItems = paddingItems.appendingFormat("--")
        }
        PTNSLogConsole("🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳\(logTag)\(paddingItems)-> \(type(of: self))", levelType: PTLogMode,loggerType: .viewCycle)
    }
    
    
    private func printPath() {
        // no parent
        if parent == nil {
            logWithLevel(level: 0)
            return
        }
        
        // tabbar
        if (parent!.isKind(of: UITabBarController.classForCoder())) {
            logWithLevel(level: 1)
            return
        }
         
        // nav
        if (parent!.isKind(of: UINavigationController.classForCoder())) {
            let nav: UINavigationController = parent as! UINavigationController
            let integer = nav.viewControllers.firstIndex(of: self)
            logWithLevel(level: UInt(integer!))
        }
    }
}
