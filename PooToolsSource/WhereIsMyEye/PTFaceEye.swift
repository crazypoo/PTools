//
//  PTFaceEye.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@available(iOS 12.0,*)
@objcMembers
public class PTFaceEye: NSObject {
    ///初始化单例
    public static let share = PTFaceEye()
    
    ///EyeTracking在屏幕展示的位置回调
    public var eyeLookAt:((_ point:CGPoint)->Void)?
    ///EyeTracking的当前使用状态
    public var trackingEyeState:((_ state:PTEyeTrackingState)->Void)?

    private lazy var manager:PTEyeTrackingManager = {
        let manager = PTEyeTrackingManager()
        manager.delegate = self
        manager.showCursorView(parent: AppWindows!)
        manager.showStatusView(parent: AppWindows!)
        return manager
    }()
    
    public override init() {
        super.init()
    }
    
    ///开启
    public func createEye() {
        if Gobal_device_info.isFaceIDCapable {
            manager.run()
        } else {
            PTNSLogConsole("设备不能运行")
        }
    }
    
    ///关闭
    public func dismissEye() {
        manager.hideCursorView()
        manager.hideStatusView()
        manager.pause()
    }
    
    ///隐藏焦点
    public func hideCursorView() {
        manager.hideCursorView()
    }
    
    ///开启焦点
    public func showCursorView() {
        manager.showCursorView(parent: AppWindows!)
    }
}

@available(iOS 12.0,*)
extension PTFaceEye:PTEyeTrackingDelegate {
    public func didChange(eyeTrackingState: PTEyeTrackingState) {
        if trackingEyeState != nil {
            trackingEyeState!(eyeTrackingState)
        }
    }
    
    public func didChange(lookAtPoint: CGPoint) {
        if eyeLookAt != nil {
            eyeLookAt!(lookAtPoint)
        }
    }
}
