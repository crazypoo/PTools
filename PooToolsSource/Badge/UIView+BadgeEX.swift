//
//  UIView+BadgeEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import QuartzCore

@MainActor
private final class PTBadgeLabel: UILabel {
    var environmentChanged: (() -> Void)?
    private var traitChangeRegistration: (any UITraitChangeRegistration)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        registerEnvironmentObservers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerEnvironmentObservers()
    }

    private func registerEnvironmentObservers() {
        traitChangeRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: PTBadgeLabel, _: UITraitCollection) in
            self?.environmentChanged?()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusDidChange),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        environmentChanged?()
    }

    @objc private func reduceMotionStatusDidChange() {
        environmentChanged?()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension UIView: @MainActor PTBadgeProtocol {

    // MARK: - 状态

    private var ptBadgeState: PTBadgeState {
        if let state = objc_getAssociatedObject(self, &PTBadgeAssociatedKeys.viewState) as? PTBadgeState {
            return state
        }

        let state = PTBadgeState()
        objc_setAssociatedObject(self, &PTBadgeAssociatedKeys.viewState, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return state
    }

    public var badge: UILabel? {
        get { ptBadgeState.label }
        set {
            let state = ptBadgeState
            if state.label === newValue {
                if let newValue, newValue.superview !== self {
                    addSubview(newValue)
                    bringSubviewToFront(newValue)
                }
                return
            }

            state.label?.removeFromSuperview()
            state.interactionController?.invalidate()
            state.interactionController = nil
            state.label = newValue

            guard let newValue else {
                state.hasContent = false
                state.isVisible = false
                state.operationID &+= 1
                return
            }
            if newValue.superview !== self {
                self.addSubview(newValue)
            }
            self.bringSubviewToFront(newValue)
            updateBadgeAppearance()
            updateBadgeGesture()
            renderBadge()
        }
    }

    public var badgeConfig: PTBadgeConfiguration {
        get { ptBadgeState.configuration }
        set {
            let state = ptBadgeState
            state.configuration = newValue
            if state.hasContent {
                renderBadge()
            } else {
                updateBadgeAppearance()
                updateBadgeGesture()
            }
        }
    }

    public var badgeRemoveCallback: (() -> Void)? {
        get { ptBadgeState.removeCallback }
        set { ptBadgeState.removeCallback = newValue }
    }

    // MARK: - 展示

    private func badgeLabelInit() {
        guard ptBadgeState.label == nil else { return }

        let label = PTBadgeLabel()
        label.textAlignment = .center
        label.isHidden = true
        label.isAccessibilityElement = false
        label.environmentChanged = { [weak self] in
            self?.badgeEnvironmentChanged()
        }

        let state = ptBadgeState
        state.label = label
        addSubview(label)
        bringSubviewToFront(label)
        updateBadgeAppearance()
        updateBadgeGesture()
    }

    private func badgeEnvironmentChanged() {
        updateBadgeAppearance()
        guard ptBadgeState.isVisible else {
            removeBadgeAnimations()
            return
        }
        applyBadgeAnimation()
    }

    public func showBadge() {
        showBadge(.redDot, animation: .none)
    }

    public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) {
        showBadge(PTBadgeContentResolver.content(style: style, value: value), animation: aniType)
    }

    public func showBadge(_ content: PTBadgeContent, animation: PTBadgeAnimType = .none) {
        if ptBadgeState.label == nil {
            badgeLabelInit()
        }

        let state = ptBadgeState
        state.content = content
        state.hasContent = true
        state.isVisible = PTBadgeMetrics.size(for: content, configuration: state.configuration) != .zero
        state.operationID &+= 1
        state.configuration.animType = animation

        state.label?.alpha = 1
        state.label?.transform = .identity
        renderBadge()
    }

    public func clearBadge() {
        let state = ptBadgeState
        state.isVisible = false
        state.operationID &+= 1
        state.interactionController?.invalidate()
        state.label?.isHidden = true
        state.label?.alpha = 1
        state.label?.transform = .identity
        removeBadgeAnimations()
    }

    public func resumeBadge() {
        let state = ptBadgeState
        guard state.hasContent,
              PTBadgeMetrics.size(for: state.content, configuration: state.configuration) != .zero else {
            return
        }

        state.isVisible = true
        state.operationID &+= 1
        state.label?.alpha = 1
        state.label?.transform = .identity
        renderBadge()
    }

    /// 在宿主完成布局或系统控件重新创建内部 View 后重新挂载角标。
    public func refreshBadge() {
        guard ptBadgeState.hasContent else { return }
        renderBadge()
    }

    // MARK: - 外观和布局

    private func updateBadgeAppearance() {
        guard let label = ptBadgeState.label else { return }
        let configuration = ptBadgeState.configuration

        label.backgroundColor = configuration.bgColor
        label.textColor = configuration.textColor
        label.font = configuration.font
        let borderWidth = configuration.borderWidth.isFinite ? max(0, configuration.borderWidth) : 0
        label.layer.borderWidth = borderWidth
        label.layer.borderColor = configuration.borderColor.cgColor
        if configuration.canDragToDelete {
            isUserInteractionEnabled = true
        }
    }

    private func renderBadge() {
        let state = ptBadgeState
        guard let label = state.label, state.hasContent else { return }

        if label.superview !== self {
            addSubview(label)
        }
        bringSubviewToFront(label)

        let configuration = state.configuration
        let size = PTBadgeMetrics.size(for: state.content, configuration: configuration)
        guard size.width > 0, size.height > 0 else {
            state.isVisible = false
            label.isHidden = true
            removeBadgeAnimations()
            return
        }

        label.text = PTBadgeMetrics.displayText(for: state.content, configuration: configuration)
        label.tag = badgeStyle(for: state.content).rawValue
        label.numberOfLines = 1
        label.isAccessibilityElement = label.text?.isEmpty == false
        label.accessibilityLabel = label.text

        if hasValidBadgeFrame(configuration.frame) {
            label.frame = configuration.frame
        } else {
            label.bounds.size = size
            label.center = safeBadgeCenter(configuration.centerOffset)
        }

        label.layer.cornerRadius = PTBadgeMetrics.cornerRadius(for: label.bounds.size,
                                                               configuration: configuration)
        label.layer.masksToBounds = true

        label.isHidden = !state.isVisible
        updateBadgeAppearance()
        updateBadgeGesture()
        if state.isVisible {
            applyBadgeAnimation()
        } else {
            removeBadgeAnimations()
        }
    }

    private func badgeStyle(for content: PTBadgeContent) -> PTBadgeStyle {
        switch content {
        case .redDot: return .redDot
        case .number: return .number
        case .text: return .new
        }
    }

    private func hasValidBadgeFrame(_ frame: CGRect) -> Bool {
        frame.origin.x.isFinite && frame.origin.y.isFinite && frame.width > 0 && frame.height > 0 && frame.width.isFinite && frame.height.isFinite
    }

    private func safeBadgeCenter(_ center: CGPoint) -> CGPoint {
        guard center.x.isFinite, center.y.isFinite else { return .zero }
        return center
    }

    // MARK: - 长按拖拽

    private func updateBadgeGesture() {
        let state = ptBadgeState
        guard let label = state.label else { return }
        label.isUserInteractionEnabled = state.configuration.canDragToDelete
        if state.interactionController == nil {
            state.interactionController = PTBadgeInteractionController(hostView: self,
                                                                        draggableView: label,
                                                                        removesViewOnDelete: true)
        }
        state.interactionController?.onRemove = { [weak self, weak state, weak label] in
            guard let self, let state, let label, state.label === label else { return }
            state.isVisible = false
            state.hasContent = false
            state.label = nil
            state.interactionController = nil
            state.removeCallback?()
            self.applyBadgeAnimation()
        }
        state.interactionController?.update(hostView: self,
                                            isEnabled: state.configuration.canDragToDelete && state.isVisible,
                                            longPressTime: state.configuration.longPressTime)
    }

    // MARK: - 动画

    private func removeBadgeAnimations() {
        PTBadgeAnimationDriver.remove(from: ptBadgeState.label?.layer)
    }

    private func applyBadgeAnimation() {
        let state = ptBadgeState
        PTBadgeAnimationDriver.apply(to: state.label?.layer,
                                     animation: state.configuration.animType,
                                     isVisible: state.isVisible && state.label?.isHidden == false,
                                     isAttachedToWindow: state.label?.window != nil)
    }
}
