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
        
        swizzling(self)
        
        isSwizzed = true
    }
    
    class func swizzItWithTag(tag: String?) {
        if (tag == nil) {
            return
        }
        
        logTag = tag!
        self.swizzIt()
    }
    
    class func undoSwizz() {
        if (!isSwizzed) {
            return
        }
        
        undoSwizzling(self)
        
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
        self.printPath()
        self.swizzled_viewDidAppear(animated: animated)
    }
    
    private func logWithLevel(level: UInt) {
        var paddingItems = "";
        for _ in 0...level {
            paddingItems = paddingItems.appendingFormat("--")
        }
        print("🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳🤳\(logTag)\(paddingItems)-> \(type(of: self))")
    }
    
    
    private func printPath() {
        // no parent
        if self.parent == nil {
            self.logWithLevel(level: 0)
            return
        }
        
        // tabbar
        if (self.parent!.isKind(of: UITabBarController.classForCoder())) {
            self.logWithLevel(level: 1)
            return
        }
         
        // nav
        if (self.parent!.isKind(of: UINavigationController.classForCoder())) {
            let nav: UINavigationController = self.parent as! UINavigationController
            let integer = nav.viewControllers.firstIndex(of: self)
            self.logWithLevel(level: UInt(integer!))
        }
    }
    
}

// MARK: - Runtime
private let swizzling: (UIViewController.Type) -> () = { viewController in
    
    let originalSelector = #selector(viewController.viewDidAppear(_:))
    let swizzledSelector = #selector(viewController.swizzled_viewDidAppear(animated:))
    
    let originalMethod = class_getInstanceMethod(viewController, originalSelector)
    let swizzledMethod = class_getInstanceMethod(viewController, swizzledSelector)
    
    method_exchangeImplementations(originalMethod!, swizzledMethod!)
}

private let undoSwizzling: (UIViewController.Type) -> () = { viewController in
    
    let originalSelector = #selector(viewController.swizzled_viewDidAppear(animated:))
    let swizzledSelector = #selector(viewController.viewDidAppear(_:))
    
    let originalMethod = class_getInstanceMethod(viewController, originalSelector)
    let swizzledMethod = class_getInstanceMethod(viewController, swizzledSelector)
    
    method_exchangeImplementations(originalMethod!, swizzledMethod!)
}
