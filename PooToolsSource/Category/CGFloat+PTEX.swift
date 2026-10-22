//
//  CGFloat+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation

extension CGFloat: PTProtocolCompatible {}
//MARK: 溫度單位
@objc public enum TemperatureUnit: Int {
    ///華氏
    case Fahrenheit
    ///攝氏
    case CentigradeDegree
}


public extension CGFloat {
    //MARK: 屏幕分辨率
    /// 屏幕分辨率
    @MainActor static let kScreenScale: CGFloat = UIScreen.main.scale

    //MARK: 獲取屏幕寬度
    ///獲取屏幕寬度
    @MainActor static let kSCREEN_WIDTH = kSCREEN_SIZE.width
    
    //MARK: 獲取屏幕高度
    ///獲取屏幕高度
    @MainActor static let kSCREEN_HEIGHT = kSCREEN_SIZE.height
    
    //MARK: 等比例调整
    ///等比例调整
    /// - Returns: CGFloat
    @MainActor static func ScaleW(w:CGFloat)->CGFloat {
        let width:CGFloat = w * kSCREEN_WIDTH/375
        return width
    }

    // English: Legacy estimate kept for source compatibility; live navigation bars must be measured from their host.
    // Español: Estimación heredada conservada por compatibilidad; las barras reales deben medirse desde su host.
    // 中文：保留旧估算值以兼容现有代码；实时导航栏必须从所属宿主测量。
    //MARK: 獲取導航欄Bar高度
    ///獲取導航欄Bar高度
    @MainActor static let kNavBarHeight: CGFloat = UINavigationController().navigationBar.frame.height
    @MainActor static let kNavBarWidth: CGFloat = UINavigationController().navigationBar.frame.width

    //MARK: Picker height
    static let kPickerHeight: CGFloat = 216
    
    
    // MARK: - Status Bar Resolution
    /// 验证 UIKit 返回的高度是否有效
    @MainActor
    private static func ptValidHeight(_ value: CGFloat?) -> CGFloat? {

        guard let value, value.isFinite, value > 0 else {
            return nil
        }

        return value
    }

    /// 优先从当前 UIWindow / UIWindowScene 获取状态栏高度
    @MainActor
    private static func ptResolvedStatusBarHeight(in window: UIWindow?) -> CGFloat? {

        // 1. 当前 Window 所属 Scene
        if let height = ptValidHeight(window?.windowScene?.statusBarManager?.statusBarFrame.height) {
            return height
        }

        // 2. 当前 Window 安全区域
        if let height = ptValidHeight(window?.safeAreaInsets.top) {
            return height
        }

        // 3. 如果只有一个前台 Scene，尝试直接读取
        // 不在多个 Scene 中随意猜测
        let scenes = PTSceneContext.connectedWindowScenes().filter {
                $0.activationState == .foregroundActive ||
                $0.activationState == .foregroundInactive
            }

        guard scenes.count == 1, let scene = scenes.first else {
            return nil
        }

        return ptValidHeight(
            scene.statusBarManager?.statusBarFrame.height
        )
    }

    //MARK: 獲取StatusBar的高度
    ///獲取StatusBar的高度
    /// - Returns: CGFloat
    @MainActor static func statusBarHeight() -> CGFloat {
        if let height = ptResolvedStatusBarHeight(in: PTSceneContext.activeWindow()) {
            return height
        }

        // 最终兼容估算值，不代表设备真实状态栏高度
        return deviceInfo.isFaceIDCapable ? 44 : 20

    }
    

    // MARK: - Navigation Bar Total Height

    /// 获取导航栏总高度。
    ///
    /// 优先返回 UIWindow 坐标系中的真实导航栏底部。
    /// 尚未完成布局时返回兼容估算值。
    ///
    /// 注意：
    /// 这是兼容 API，不应作为不可更新的初始化布局常量。
    @MainActor
    static var kNavBarHeight_Total: CGFloat {

        let manager = PTNavigationBarManager.shared
        let window = PTSceneContext.activeWindow()

        // 第一阶段：读取当前实际状态栏高度
        let statusHeight = ptResolvedStatusBarHeight(in: window) ?? statusBarHeight()

        // 第二阶段：尝试获取当前真实导航栏
        if let window {
            let nav = manager.navigationControllerForTotalHeight(in: window)
            if let nav {
                // iPhone Duo 等系统垂直导航栏模式
                // 不应将侧边栏底部作为顶部偏移
                if manager.isSystemVerticalBarOwned(by: nav) {
                    return Swift.max(0, window.safeAreaInsets.top)
                }

                // 导航栏隐藏时只保留状态栏区域
                if nav.isNavigationBarHidden || nav.navigationBar.isHidden {
                    return Swift.max(0, statusHeight)
                }

                // 优先返回真实导航栏底部
                if let geometry = manager.navigationGeometry(
                    in: nav
                ) {
                    return geometry.navigationBottomInWindow
                }

                // 第三阶段：
                // 有当前导航栈，但导航栏暂时无法完成真实测量
                // 使用状态栏高度 + 当前导航栏已有 bounds 高度估算
                if nav.viewIfLoaded?.window === window,
                   let barHeight = ptValidHeight(nav.navigationBar.bounds.height) {
                    return statusHeight + barHeight
                }
            }
        }

        // 第四阶段：兼容历史估算
        let legacyHeight = ptValidHeight(CGFloat.kNavBarHeight) ?? 44

        return statusHeight + legacyHeight
    }

    //MARK: Tabbar安全高度
    ///Tabbar安全高度
    static let kTabbarSaveAreaHeight: CGFloat = isXModel ? 34 : 0
    //MARK: Tabbar高度
    ///Tabbar高度
    static let kTabbarHeight: CGFloat = 49
    //MARK: Tabbar總高度
    ///Tabbar總高度
    static let kTabbarHeight_Total = CGFloat.kTabbarSaveAreaHeight + CGFloat.kTabbarHeight
    
    //MARK: 华氏摄氏度转普通摄氏度/普通摄氏度转华氏摄氏度
    ///华氏摄氏度转普通摄氏度/普通摄氏度转华氏摄氏度
    static func temperatureUnitExchangeValue(value:CGFloat,
                                             changeToType:TemperatureUnit) -> CGFloat {
        switch changeToType {
        case .Fahrenheit:
            let values = 32 + 1.8 * value
            return values
        case .CentigradeDegree:
            let values = (value - 32) / 1.8
            return values
        default:
            return 0
        }
    }
    
    @MainActor static let kLeftSafeAreaWidth = AppWindows?.safeAreaInsets.left ?? 0
    @MainActor static let kRightSafeAreaWidth = AppWindows?.safeAreaInsets.right ?? 0
}

public extension PTPOP where Base == CGFloat {
    //MARK: 一个数字四舍五入返回
    ///一个数字四舍五入返回
    /// - Parameters:
    ///   - value: 值
    ///   - scale: 保留小数的位数
    /// - Returns: 四舍五入返回结果
    func rounding(scale: Int16 = 1) -> CGFloat {
        let value = NSDecimalNumberHandler.pt.rounding(value: base,scale: scale)
        return "\(value.floatValue)".cgFloat
    }
    
    var toPi: CGFloat {
        base / 180 * .pi
    }
    
    // MARK: 角度转弧度
    /// 角度转弧度
    /// - Returns: 弧度
    func degreesToRadians() -> CGFloat {
        return (.pi * base) / 180.0
    }
    
    // MARK: 弧度转角度
    /// 角弧度转角度
    /// - Returns: 角度
    func radiansToDegrees() -> CGFloat {
        return (base * 180.0) / .pi
    }
}

extension CGFloat: PTNumberValueAdapterable {
    public typealias PTNumberValueAdapterType = CGFloat
    public var adapter: CGFloat {
        return self * PTNumberValueAdapter.share.currentScale
    }
}
