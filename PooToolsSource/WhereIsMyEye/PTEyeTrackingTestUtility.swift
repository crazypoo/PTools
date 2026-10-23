//
//  PTEyeTrackingTestUtility.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

// English: Import the umbrella Core target explicitly for standalone SwiftPM builds.
// Español: Importa explícitamente el target Core para las compilaciones SwiftPM independientes.
// 中文：独立 SwiftPM 编译时，显式导入 Core 聚合 target。
#if SWIFT_PACKAGE
import ptools
#endif

class PTEyeTrackingTestUtility {
    
    internal var trackingState: PTEyeTrackingState = .notTracked
    internal var semaphore: Bool = false
    @MainActor internal private(set) var screenSize = CGRect.zero
    
    private var portraitScreenSize: CGRect?
    
    private var cursorView: UIView?
    private var statusLabel: UILabel?
    private var upperAreaView: UIView?
    private var bottomAreaView: UIView?
    
    @MainActor internal init() {}

    @MainActor internal func updateHostBounds(_ bounds: CGRect) {
        guard !bounds.isEmpty else { return }
        screenSize = bounds
        portraitScreenSize = bounds.width <= bounds.height
            ? bounds
            : CGRect(x: bounds.minX, y: bounds.minY, width: bounds.height, height: bounds.width)
    }
    
    @MainActor internal func showStatusView(parent: UIView) {
        updateHostBounds(parent.bounds)
        if statusLabel == nil {
            let label = UILabel(frame: CGRect(x: 50,
                                              y: screenSize.height / 2 - 15,
                                              width: max(0, screenSize.width - 50),
                                              height: 30))
            
            label.textAlignment = NSTextAlignment.left
            label.text = ""
            parent.addSubview(label)
            
            statusLabel = label
        }
        
        statusLabel?.isHidden = false
    }
    
    @MainActor internal func showCursorView(parent: UIView) {
        updateHostBounds(parent.bounds)
        if cursorView == nil {
            let size = CGFloat(12)
            let view = UIView(frame: CGRect(x: screenSize.width / 2 - size / 2,
                                            y: screenSize.height / 2 - size / 2,
                                            width: size,
                                            height: size))
            view.layer.cornerRadius = size / 2
            view.layer.masksToBounds = true
            view.backgroundColor = .red
            parent.addSubview(view)
            
            cursorView = view
        }
        
        cursorView?.isHidden = false
    }
    
    /**
     隐藏UILabel显示当前EyeTracking状态。
     */
    @MainActor internal func hideStatusView() {
        self.statusLabel?.isHidden = true
    }
    
    /**
     隐藏当前EyeTracking状态的CursorView。
     */
    @MainActor internal func hideCursorView() {
        self.cursorView?.isHidden = true
    }
    
    @MainActor internal func updateTestViews(with lookAtPoint: CGPoint) {
        //self.updateStatusLabel(with: lookAtPoint)
        updateCursorView(with: lookAtPoint)
    }
    
//    internal func updateStatusLabel(with lookAtPoint: CGPoint) {
//        guard let statusLabel = statusLabel else { return }
//        let x = max(-self.screenSize.width / 2, min(lookAtPoint.x, self.screenSize.width / 2))
//        let y = max(-self.screenSize.height / 2, min(lookAtPoint.y, self.screenSize.height / 2))
//        let point = CGPoint(x: self.screenSize.width / 2, y: self.screenSize.height / 2)
//        let transformedPoint = point.applying(CGAffineTransform(translationX: x, y: y))
//
//        statusLabel.text = "x : \(transformedPoint.x), y : \(transformedPoint.y)"
//    }
    
    @MainActor internal func updateCursorView(with lookAtPoint: CGPoint) {
        guard let cursorView = cursorView else { return }
        
        var x = max(-screenSize.width / 2, min(lookAtPoint.x, screenSize.width / 2))
        var y = max(-screenSize.height / 2, min(lookAtPoint.y, screenSize.height / 2))
        
        switch cursorView.window?.windowScene?.interfaceOrientation {
        case .landscapeLeft:
            let tmp = x
            x = y
            y = -tmp
        case .landscapeRight:
            let tmp = x
            x = y
            y = tmp
            
        default:
            break
        }
        
        if trackingState == .notTracked {
            cursorView.transform = CGAffineTransform(translationX: 0, y: 0)
            return
        }
        
        cursorView.transform = CGAffineTransform(translationX: x, y: y)
    }
    
    
    @MainActor internal func rotated(){
        // 存在在屏幕旋转时无法准确定位光标的错误
        let size: CGFloat = 12
        cursorView?.frame.origin.x = (screenSize.width / 2) - (size / 2)
        cursorView?.frame.origin.y = (screenSize.height / 2) - (size / 2)
        
        
        statusLabel?.frame = CGRect(x: screenSize.width / 2,
                                         y: screenSize.height / 2,
                                         width: max(0, screenSize.width - 50),
                                         height: 30)
    }
}
