//
//  PTBadgeProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Constants & Enums

/// 角标样式
public enum PTBadgeStyle: Int {
    case redDot // 红点
    case number // 数字
    case new    // "new" 文本
}

/// 角标动画类型
public enum PTBadgeAnimType {
    case none
    case scale
    case shake
    case bounce
    case breathe
    
    // 将动画 Key 绑定在枚举内部，更加内聚
    var animationKey: String {
        switch self {
        case .none: return ""
        case .scale: return "PTBadgeScaleAnimation"
        case .shake: return "PTBadgeShakeAnimation"
        case .bounce: return "PTBadgeBounceAnimation"
        case .breathe: return "PTBadgeBreatheAnimation"
        }
    }
}

// MARK: - Configuration

/// 将分散的配置属性聚合到一个结构体中，避免污染 UIView 的命名空间
public struct PTBadgeConfiguration {
    public var font: UIFont = PTAppBaseConfig.share.tabBadgeFont
    public var bgColor: UIColor = .red
    public var textColor: UIColor = .white
    public var frame: CGRect = .zero
    public var centerOffset: CGPoint = .zero
    public var maximumNumber: Int = 99
    public var radius: CGFloat = 4.0
    public var borderColor: UIColor = PTAppBaseConfig.share.tabBadgeBorderColor
    public var borderWidth: CGFloat = PTAppBaseConfig.share.tabBadgeBorderHeight
    public var animType: PTBadgeAnimType = .none
    
    // 拖拽相关配置也可以放在这里
    public var canDragToDelete: Bool = false
    public var longPressTime: TimeInterval = 0.5
    
    public init() {}
}

// MARK: - Associated Keys

/// 使用 UInt8 并取地址，是 Swift 中关联对象最安全、标准的写法
internal struct PTBadgeAssociatedKeys {
    static var badgeLabel: UInt8 = 0
    static var badgeConfig: UInt8 = 0 // 用一个 Config 替代之前零散的几十个 Key
    static var badgeCenterChange: UInt8 = 0
    static var badgeDragCallback: UInt8 = 0
}

// MARK: - Protocol

public protocol PTBadgeProtocol {
    /// 核心的角标视图
    var badge: UILabel? { get set }
    
    /// 角标的全局配置（聚合了颜色、字体、偏移量等）
    var badgeConfig: PTBadgeConfiguration { get set }
    
    /// 仅展示红点
    func showBadge()
    
    /// 根据样式、值和动画展示角标
    /// - Parameters:
    ///   - style: 角标样式 (红点、数字、new)
    ///   - value: 要展示的值 (通常是 Int 或 String)
    ///   - aniType: 动画类型
    func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType)
    
    /// 清除角标
    func clearBadge()
}
