//
//  PTBadgeProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

// MARK: - 类型

/// 角标样式。
public enum PTBadgeStyle: Int, Sendable {
    case redDot
    case number
    case new
}

/// 角标动画类型。
public enum PTBadgeAnimType: Sendable {
    case none
    case scale
    case shake
    case bounce
    case breathe

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

/// 角标要展示的内容。
public enum PTBadgeContent: Sendable, Equatable {
    case redDot
    case number(Int)
    case text(String)
}

// MARK: - 配置

/// 角标的统一配置。
@MainActor
public struct PTBadgeConfiguration {
    public var font: UIFont = PTAppBaseConfig.share.tabBadgeFont
    public var bgColor: UIColor = .red
    public var textColor: UIColor = .white
    public var frame: CGRect = .zero
    /// 兼容历史行为：这是宿主坐标系中的绝对中心点，而不是相对位移。
    public var centerOffset: CGPoint = .zero
    public var maximumNumber: Int = 99
    public var radius: CGFloat = 4.0
    public var borderColor: UIColor = PTAppBaseConfig.share.tabBadgeBorderColor
    public var borderWidth: CGFloat = PTAppBaseConfig.share.tabBadgeBorderHeight
    public var animType: PTBadgeAnimType = .none
    public var canDragToDelete: Bool = false
    public var longPressTime: TimeInterval = 0.5

    public init() {}
}

// MARK: - 内部状态

@MainActor
internal enum PTBadgeAssociatedKeys {
    static var viewState: UInt8 = 0
    static var itemState: UInt8 = 0
}

@MainActor
internal final class PTBadgeState {
    var configuration = PTBadgeConfiguration()
    var content: PTBadgeContent = .redDot
    var hasContent = false
    var isVisible = false
    var label: UILabel?
    var removeCallback: (() -> Void)?
    var gesture: UILongPressGestureRecognizer?
    var dragOriginCenter: CGPoint = .zero
    var dragOriginTouch: CGPoint = .zero
    var didNotifyRemoval = false
    weak var hostView: UIView?
    var operationID: Int = 0
}

// MARK: - 统一内容和尺寸

@MainActor
internal enum PTBadgeContentResolver {
    static func content(style: PTBadgeStyle, value: Any) -> PTBadgeContent {
        switch style {
        case .redDot:
            return .redDot
        case .number:
            if let number = value as? Int {
                return .number(number)
            }
            if let number = value as? NSNumber {
                return .number(number.intValue)
            }
            if let string = value as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                return .number(Int(trimmed) ?? 0)
            }
            return .number(0)
        case .new:
            return .text((value as? String) ?? "new")
        }
    }
}

@MainActor
internal enum PTBadgeMetrics {
    static func safeMaximum(_ value: Int) -> Int {
        max(1, value)
    }

    static func displayText(for content: PTBadgeContent, configuration: PTBadgeConfiguration) -> String? {
        switch content {
        case .redDot:
            return nil
        case .number(let value):
            guard value > 0 else { return nil }
            let maximum = safeMaximum(configuration.maximumNumber)
            return value > maximum ? "\(maximum)+" : "\(value)"
        case .text(let value):
            let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }
    }

    static func size(for content: PTBadgeContent, configuration: PTBadgeConfiguration) -> CGSize {
        switch content {
        case .redDot:
            let diameter = max(0, configuration.radius) * 2
            return CGSize(width: diameter, height: diameter)
        case .number, .text:
            guard let text = displayText(for: content, configuration: configuration) else {
                return .zero
            }
            let fontHeight = max(1, configuration.font.pointSize + 6)
            let textSize = (text as NSString).size(withAttributes: [.font: configuration.font])
            let width = max(textSize.width + 8, fontHeight)
            return CGSize(width: width, height: fontHeight)
        }
    }
}

// MARK: - 系统 Item 宿主解析

@MainActor
internal enum PTBadgeHostResolver {
    static func hostView(for item: UIBarButtonItem) -> UIView? {
        if let customView = item.customView {
            return customView
        }
        return privateView(for: item)
    }

    static func hostView(for item: UITabBarItem) -> UIView? {
        guard let bottomView = privateView(for: item) else {
            return nil
        }

        if let imageClass = NSClassFromString("UITabBarSwappableImageView") {
            return firstView(in: bottomView, matching: imageClass) ?? bottomView
        }
        return bottomView
    }

    private static func privateView(for object: NSObject) -> UIView? {
        let selector = NSSelectorFromString("_view")
        guard object.responds(to: selector) else {
            return nil
        }

        // 中文：私有宿主只作为兼容路径，并先确认 selector；Español: el host privado es solo compatibilidad y se valida antes.
        return object.perform(selector)?.takeUnretainedValue() as? UIView
    }

    private static func firstView(in root: UIView, matching targetClass: AnyClass) -> UIView? {
        var pending = root.subviews
        var nextIndex = 0
        while nextIndex < pending.count {
            let view = pending[nextIndex]
            nextIndex += 1
            if view.isKind(of: targetClass) {
                return view
            }
            pending.append(contentsOf: view.subviews)
        }
        return nil
    }
}

@MainActor
internal enum PTBadgeItemBridge {
    static func state(for item: NSObject) -> PTBadgeState {
        if let state = objc_getAssociatedObject(item, &PTBadgeAssociatedKeys.itemState) as? PTBadgeState {
            return state
        }

        let state = PTBadgeState()
        objc_setAssociatedObject(item, &PTBadgeAssociatedKeys.itemState, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return state
    }

    static func apply(_ state: PTBadgeState, to host: UIView?) {
        if let previousHost = state.hostView, previousHost !== host {
            previousHost.badgeRemoveCallback = nil
            previousHost.clearBadge()
        }

        state.hostView = host
        guard let host else { return }

        host.badgeConfig = state.configuration
        updateRemoveCallback(state, on: host)

        if let label = state.label {
            host.badge = label
        }

        guard state.hasContent else { return }
        host.showBadge(state.content, animation: state.configuration.animType)
        if !state.isVisible {
            host.clearBadge()
        }
    }

    static func updateRemoveCallback(_ state: PTBadgeState, on host: UIView?) {
        host?.badgeRemoveCallback = { [weak state] in
            guard let state else { return }
            state.label = nil
            state.hasContent = false
            state.isVisible = false
            state.removeCallback?()
        }
    }

    static func nativeBadgeValue(for content: PTBadgeContent, configuration: PTBadgeConfiguration) -> String? {
        PTBadgeMetrics.displayText(for: content, configuration: configuration) ?? {
            if case .redDot = content {
                return "•"
            }
            return nil
        }()
    }
}

// MARK: - 协议

@MainActor
public protocol PTBadgeProtocol {
    var badge: UILabel? { get set }
    var badgeConfig: PTBadgeConfiguration { get set }

    func showBadge()
    func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType)
    func clearBadge()
}

@MainActor
public extension PTBadgeProtocol {
    /// 类型安全的角标入口；旧动态入口继续由具体类型兼容实现。
    func showBadge(_ content: PTBadgeContent, animation: PTBadgeAnimType = .none) {
        switch content {
        case .redDot:
            showBadge(style: .redDot, value: 0, aniType: animation)
        case .number(let value):
            showBadge(style: .number, value: value, aniType: animation)
        case .text(let value):
            showBadge(style: .new, value: value, aniType: animation)
        }
    }
}
