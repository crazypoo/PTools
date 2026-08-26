//
//  UIBarButtonItem+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIBarButtonItem: @MainActor PTBadgeProtocol {

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
        PTBadgeItemBridge.apply(state, to: actualBadgeSuperView)
    }

    public func clearBadge() {
        let state = ptBadgeState
        state.isVisible = false
        state.operationID &+= 1
        actualBadgeSuperView?.clearBadge()
    }

    public func resumeBadge() {
        let state = ptBadgeState
        guard state.hasContent,
              PTBadgeMetrics.size(for: state.content, configuration: state.configuration) != .zero else {
            return
        }
        state.isVisible = true
        actualBadgeSuperView?.resumeBadge()
    }

    /// 在导航栏完成布局后重新查找系统内部宿主并恢复角标。
    public func refreshBadge() {
        PTBadgeItemBridge.apply(ptBadgeState, to: actualBadgeSuperView)
    }
}
