//
//  UIWindow+PTDebugEx.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import os.lock
import UIKit

extension UIWindow {
    // MARK: - Constants
    @MainActor
    private enum Constants {
        static let touchIndicatorViewMinAlpha: CGFloat = 0.6
        static var associatedTouchIndicators: UInt8 = 0
        static var associatedReusableTouchIndicators: UInt8 = 1
    }

    // English: Protect the debug-only touch snapshot instead of exposing an unsynchronized global variable.
    // Español: Protege la instantánea de toque de depuración en lugar de exponer una variable global sin sincronización.
    // 中文：保护仅用于调试的触摸快照，避免暴露未同步的全局可变变量。
    private static let lastTouchLock = OSAllocatedUnfairLock<CGPoint?>(initialState: nil)

    static var lastTouch: CGPoint? {
        get { lastTouchLock.withLock { $0 } }
        set { lastTouchLock.withLock { $0 = newValue } }
    }

    // MARK: - ReusableTouchIndicators property
    private var reusableTouchIndicators: NSMutableSet {
        get {
            if let reusableTouchIndicators = objc_getAssociatedObject( self, &Constants.associatedReusableTouchIndicators ) as? NSMutableSet {
                return reusableTouchIndicators
            } else {
                let reusableTouchIndicators = NSMutableSet()
                objc_setAssociatedObject( self, &Constants.associatedReusableTouchIndicators, reusableTouchIndicators, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return reusableTouchIndicators
            }
        }
        set {
            objc_setAssociatedObject( self, &Constants.associatedReusableTouchIndicators, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - Method swizzling
    @objc class func db_swizzleMethods() {
        DispatchQueue.once(token: "pootools.uiwindow.db_swizzleMethods") {
            Swizzle(UIWindow.self, owner: "debug.window") {
                #selector(UIWindow.sendEvent(_:)) <-> #selector(UIWindow.db_sendEvent(_:))
            }
        }
    }
    
    // MARK: - UIDebuggingInformationOverlay
    @objc func db_debuggingInformationOverlayInit() -> UIWindow {
        type(of: self).init()
    }

    @objc var state: UIGestureRecognizer.State {
        .ended
    }

    // MARK: - Swizzled Method

    @objc func db_sendEvent(_ event: UIEvent) {
        if event.type == .touches {
        }
        db_sendEvent(event)
    }

    static var keyWindow: UIWindow? {
        return AppWindows
    }

    var _snapshot: UIImage? {
        guard Thread.isMainThread else { return nil }
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, .zero)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    var _snapshotWithTouch: UIImage? {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, .zero)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Draw the original snapshot
        layer.render(in: context)

        if let circleCenter = Self.lastTouch {
            // Draw a circle in the center of the image
            let circleRadius: CGFloat = 20

            context.setLineWidth(2)
            context.setStrokeColor(UIColor.red.cgColor)
            context.addArc(center: circleCenter,radius: circleRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            context.strokePath()
        }

        // Get the modified image
        let imageWithCircle = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithCircle
    }
}

// MARK: - DispatchQueue extension for once
extension DispatchQueue {
    @MainActor private static var _onceTracker = [String]()

    @MainActor class func once(token: String, block: PTActionTask) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if _onceTracker.contains(token) {
            return
        }
        _onceTracker.append(token)
        block()
    }
}
