//
//  PTFaceEye.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@MainActor
@objcMembers
public class PTFaceEye: NSObject {
    ///初始化单例
    public static let share = PTFaceEye()
    
    ///EyeTracking在屏幕展示的位置回调
    public var eyeLookAt:((_ point:CGPoint)->Void)?
    ///EyeTracking的当前使用状态
    public var trackingEyeState:((_ state:PTEyeTrackingState)->Void)?

    @MainActor private lazy var manager:PTEyeTrackingManager = {
        let manager = PTEyeTrackingManager()
        manager.delegate = self
        return manager
    }()
    
    public override init() {
        super.init()
    }
    
    ///开启
    @MainActor public func createEye() {
        guard let window = PTSceneContext.activeWindow() else {
            PTNSLogConsole("没有可用的活动窗口", levelType: .error, loggerType: .debug)
            return
        }
        guard deviceInfo.isFaceIDCapable else {
            PTNSLogConsole("设备不能运行", levelType: .error,loggerType: .debug)
            return
        }
        manager.showCursorView(parent: window)
        manager.showStatusView(parent: window)
        manager.run()
    }
    
    ///关闭
    @MainActor public func dismissEye() {
        manager.hideCursorView()
        manager.hideStatusView()
        manager.pause()
    }
    
    ///隐藏焦点
    @MainActor public func hideCursorView() {
        manager.hideCursorView()
    }
    
    ///开启焦点
    @MainActor public func showCursorView() {
        guard let window = PTSceneContext.activeWindow() else { return }
        manager.showCursorView(parent: window)
    }
}

extension PTFaceEye:@preconcurrency PTEyeTrackingDelegate {
    public func didChange(eyeTrackingState: PTEyeTrackingState) {
        trackingEyeState?(eyeTrackingState)
    }
    
    public func didChange(lookAtPoint: CGPoint) {
        eyeLookAt?(lookAtPoint)
    }
}
