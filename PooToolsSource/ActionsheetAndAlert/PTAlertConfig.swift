//
//  PTAlertConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

@objcMembers
public class PTAlertConfig: NSObject {
    public static let shared = PTAlertConfig()
    
    public enum PTUserInterfaceStyle: Int {
        case unspecified = 0
        case light = 1
        case dark = 2
    }

    public enum PTAlertPriority {
        case low
        case mediumLow
        case medium
        case mediumHigh
        case high
        case customValue(Int)
        var rawValue: Int {
            switch self {
            case .low:
                0
            case .mediumLow:
                250
            case .medium:
                500
            case .mediumHigh:
                750
            case .high:
                1000
            case let .customValue(value):
                value
            }
        }

        static func > (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue > rhs.rawValue
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        static func >= (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue >= rhs.rawValue
        }

        static func <= (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue <= rhs.rawValue
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue == rhs.rawValue
        }

        static func != (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue != rhs.rawValue
        }
    }

    public enum PTMode {
        /// 排队
        case queue
        /// 插队
        case interrupt
        /// 替换
        case replace
        /// 唯一
        case unique
    }

    /// 弹窗模式
    public var popoverMode: PTMode = .queue
    /// 弹窗优先级，只影响等待队列
    public var popoverPriority: PTAlertPriority = .medium
    /// 是否允许手势穿透
    public var allowsEventPenetration = false
    /// 手势穿透时是否自动隐藏
    public var autoHideWhenPenetrated = false
    /// 是否自动旋转屏幕
    public var shouldAutorotate = false
    /// 支持的界面方向
    public var supportedInterfaceOrientations = UIInterfaceOrientationMask.portrait
    /// 用户界面样式，包括夜间模式
    public var userInterfaceStyleOverride = PTUserInterfaceStyle.light
    /// 弹窗的唯一标识符，用于去重
    public var identifier: String?
    /// 弹框展示时间
    public var showALertDuration: TimeInterval = 0.35
    public var hideALertDuration: TimeInterval = 0.35
}
