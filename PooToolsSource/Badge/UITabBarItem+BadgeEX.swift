//
//  UITabBarItem+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UITabBarItem: @MainActor PTBadgeProtocol {

    private var ptBadgeState: PTBadgeState {
        PTBadgeItemBridge.state(for: self)
    }

    private var actualBadgeSuperView: UIView? {
        PTBadgeHostResolver.hostView(for: self)
    }

    public var badge: UILabel? {
        get { actualBadgeSuperView?.badge ?? ptBadgeState.label }
        set {
            let state = ptBadgeState
            state.label = newValue
            if newValue == nil {
                state.hasContent = false
                state.isVisible = false
                state.operationID &+= 1
            }
            guard let host = actualBadgeSuperView else { return }
            host.badgeConfig = state.configuration
            host.badge = newValue
            PTBadgeItemBridge.updateRemoveCallback(state, on: host)
            if newValue == nil {
                state.hasContent = false
                state.isVisible = false
                badgeValue = nil
                host.clearBadge()
            }
        }
    }

    public var badgeConfig: PTBadgeConfiguration {
        get { ptBadgeState.configuration }
        set {
            let state = ptBadgeState
            state.configuration = newValue
            PTBadgeItemBridge.apply(state, to: actualBadgeSuperView)
        }
    }

    public var badgeRemoveCallback: (() -> Void)? {
        get { ptBadgeState.removeCallback }
        set {
            let state = ptBadgeState
            state.removeCallback = newValue
            PTBadgeItemBridge.updateRemoveCallback(state, on: actualBadgeSuperView)
        }
    }

    public func showBadge() {
        showBadge(.redDot, animation: .none)
    }

    public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) {
        showBadge(PTBadgeContentResolver.content(style: style, value: value), animation: aniType)
    }

    public func showBadge(_ content: PTBadgeContent, animation: PTBadgeAnimType = .none) {
        let state = ptBadgeState
        state.content = content
        state.hasContent = true
        state.isVisible = PTBadgeMetrics.size(for: content, configuration: state.configuration) != .zero
        state.didNotifyRemoval = false
        state.configuration.animType = animation

        if let host = actualBadgeSuperView {
            badgeValue = nil
            PTBadgeItemBridge.apply(state, to: host)
        } else {
            badgeValue = PTBadgeItemBridge.nativeBadgeValue(for: content, configuration: state.configuration)
        }
    }

    public func clearBadge() {
        let state = ptBadgeState
        state.isVisible = false
        state.operationID &+= 1
        badgeValue = nil
        actualBadgeSuperView?.clearBadge()
    }

    public func resumeBadge() {
        let state = ptBadgeState
        guard state.hasContent,
              PTBadgeMetrics.size(for: state.content, configuration: state.configuration) != .zero else {
            return
        }

        state.isVisible = true
        if let host = actualBadgeSuperView {
            badgeValue = nil
            PTBadgeItemBridge.apply(state, to: host)
        } else {
            badgeValue = PTBadgeItemBridge.nativeBadgeValue(for: state.content, configuration: state.configuration)
        }
    }

    /// 在 TabBar 完成布局或系统内部 View 重建后重新挂载角标。
    public func refreshBadge() {
        if let host = actualBadgeSuperView {
            badgeValue = nil
            PTBadgeItemBridge.apply(ptBadgeState, to: host)
        } else if ptBadgeState.hasContent, ptBadgeState.isVisible {
            badgeValue = PTBadgeItemBridge.nativeBadgeValue(for: ptBadgeState.content, configuration: ptBadgeState.configuration)
        }
    }
}
