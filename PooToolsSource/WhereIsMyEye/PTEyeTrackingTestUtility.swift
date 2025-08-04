//
//  PTEyeTrackingTestUtility.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

class PTEyeTrackingTestUtility {
    
    internal var trackingState: PTEyeTrackingState = .notTracked
    internal var semaphore: Bool = false
    internal var screenSize = kSCREEN_BOUNDS
    
    private var portraitScreenSize: CGRect?
    
    private var cursorView: UIView?
    private var statusLabel: UILabel?
    private var upperAreaView: UIView?
    private var bottomAreaView: UIView?
    
    internal init(){
        // 指定纵向设备屏幕大小
        if CGFloat.kSCREEN_WIDTH < CGFloat.kSCREEN_HEIGHT {
            portraitScreenSize = kSCREEN_BOUNDS
        } else {
            portraitScreenSize = CGRect(x: 0, y: 0, width: CGFloat.kSCREEN_HEIGHT, height: CGFloat.kSCREEN_WIDTH)
        }
    }
    
    internal func showStatusView(parent: UIView) {
        if statusLabel == nil {
            let label = UILabel(frame: CGRect(x: 50,
                                              y: kSCREEN_BOUNDS.height / 2 - 15,
                                              width: kSCREEN_BOUNDS.width - 50,
                                              height: 30))
            
            label.textAlignment = NSTextAlignment.left
            label.text = ""
            parent.addSubview(label)
            
            statusLabel = label
        }
        
        statusLabel?.isHidden = false
    }
    
    internal func showCursorView(parent: UIView) {
        if cursorView == nil {
            let size = CGFloat(12)
            let view = UIView(frame: CGRect(x: kSCREEN_BOUNDS.width / 2 - size / 2,
                                            y: kSCREEN_BOUNDS.height / 2 - size / 2,
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
    internal func hideStatusView() {
        statusLabel?.isHidden = true
    }
    
    /**
     隐藏当前EyeTracking状态的CursorView。
     */
    internal func hideCursorView() {
        cursorView?.isHidden = true
    }
    
    internal func updateTestViews(with lookAtPoint: CGPoint) {
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
    
    internal func updateCursorView(with lookAtPoint: CGPoint) {
        guard let cursorView = cursorView else { return }
        
        var x = max(-kSCREEN_BOUNDS.width / 2, min(lookAtPoint.x, kSCREEN_BOUNDS.width / 2))
        var y = max(-kSCREEN_BOUNDS.height / 2, min(lookAtPoint.y, kSCREEN_BOUNDS.height / 2))
        
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.landscapeLeft:
            let tmp = x
            x = y
            y = -tmp
            
        case UIDeviceOrientation.landscapeRight:
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
    
    
    internal func rotated(){
        // 存在在屏幕旋转时无法准确定位光标的错误
        let size: CGFloat = 12
        cursorView?.frame.origin.x = (kSCREEN_BOUNDS.width / 2) - (size / 2)
        cursorView?.frame.origin.y = (kSCREEN_BOUNDS.height / 2) - (size / 2)
        
        
        statusLabel?.frame = CGRect(x: kSCREEN_BOUNDS.width / 2,
                                         y: kSCREEN_BOUNDS.height / 2,
                                         width: kSCREEN_BOUNDS.width - 50,
                                         height: 30)
    }
}
