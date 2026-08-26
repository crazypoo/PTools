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
            state.gesture = nil
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
            updateBadgeAppearance()
            updateBadgeGesture()
            if state.hasContent {
                renderBadge()
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
        state.didNotifyRemoval = false
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
        label.layer.borderWidth = max(0, configuration.borderWidth)
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
        let renderedSize = hasValidBadgeFrame(configuration.frame) ? configuration.frame.size : size
        label.layer.cornerRadius = min(max(0, configuration.radius), min(renderedSize.width, renderedSize.height) / 2)
        label.layer.masksToBounds = true
        label.isAccessibilityElement = label.text?.isEmpty == false
        label.accessibilityLabel = label.text

        if hasValidBadgeFrame(configuration.frame) {
            label.frame = configuration.frame
        } else {
            label.bounds.size = size
            label.center = configuration.centerOffset
        }

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

    private func resetBadgePosition() {
        guard let label = ptBadgeState.label else { return }
        let configuration = ptBadgeState.configuration
        if hasValidBadgeFrame(configuration.frame) {
            label.frame = configuration.frame
        } else {
            label.center = configuration.centerOffset
        }
    }

    // MARK: - 长按拖拽

    private func updateBadgeGesture() {
        let state = ptBadgeState
        guard let label = state.label else { return }

        if let oldGesture = state.gesture {
            label.removeGestureRecognizer(oldGesture)
            state.gesture = nil
        }

        label.isUserInteractionEnabled = state.configuration.canDragToDelete
        guard state.configuration.canDragToDelete else { return }

        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleBadgeLongPress(_:)))
        let duration = state.configuration.longPressTime.isFinite ? state.configuration.longPressTime : 0.5
        gesture.minimumPressDuration = min(max(0.1, duration), 10)
        gesture.cancelsTouchesInView = false
        label.addGestureRecognizer(gesture)
        state.gesture = gesture
    }

    @objc private func handleBadgeLongPress(_ gesture: UILongPressGestureRecognizer) {
        let state = ptBadgeState
        guard let label = state.label, state.isVisible else { return }

        switch gesture.state {
        case .began:
            state.dragOriginCenter = label.center
            state.dragOriginTouch = gesture.location(in: self)
            removeBadgeAnimations()
        case .changed:
            let location = gesture.location(in: self)
            let delta = CGPoint(x: location.x - state.dragOriginTouch.x, y: location.y - state.dragOriginTouch.y)
            label.center = CGPoint(x: state.dragOriginCenter.x + delta.x, y: state.dragOriginCenter.y + delta.y)
        case .ended:
            let badgeFrame = label.convert(label.bounds, to: self)
            if bounds.intersects(badgeFrame) {
                restoreBadgeAfterDrag()
            } else {
                deleteBadgeAfterDrag()
            }
        case .cancelled, .failed:
            restoreBadgeAfterDrag()
        default:
            break
        }
    }

    private func restoreBadgeAfterDrag() {
        let state = ptBadgeState
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5) {
            self.resetBadgePosition()
        } completion: { _ in
            guard state.isVisible else { return }
            self.applyBadgeAnimation()
        }
    }

    private func deleteBadgeAfterDrag() {
        let state = ptBadgeState
        guard let label = state.label, !state.didNotifyRemoval else { return }

        state.didNotifyRemoval = true
        state.isVisible = false
        state.operationID &+= 1
        let operationID = state.operationID
        UIView.animate(withDuration: 0.2, animations: {
            label.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            label.alpha = 0
        }) { _ in
            guard state.operationID == operationID, state.label === label else { return }
            label.removeFromSuperview()
            state.label = nil
            state.gesture = nil
            state.hasContent = false
            state.removeCallback?()
        }
    }

    // MARK: - 动画

    private func removeBadgeAnimations() {
        guard let layer = ptBadgeState.label?.layer else { return }
        for animationType in [PTBadgeAnimType.scale, .shake, .bounce, .breathe] {
            layer.removeAnimation(forKey: animationType.animationKey)
        }
    }

    private func applyBadgeAnimation() {
        let state = ptBadgeState
        guard let layer = state.label?.layer, state.isVisible else {
            removeBadgeAnimations()
            return
        }

        removeBadgeAnimations()
        guard state.label?.isHidden == false,
              state.label?.window != nil,
              !UIAccessibility.isReduceMotionEnabled else {
            return
        }

        let animationType = state.configuration.animType
        guard animationType != .none else { return }
        let key = animationType.animationKey

        switch animationType {
        case .none:
            break
        case .scale:
            layer.add(CAAnimation.scale(fromScale: 1.4, toScale: 0.6, duration: 1, repeatCount: .infinity), forKey: key)
        case .shake:
            layer.add(CAAnimation.shakeAnimation(repeatTimes: .infinity, duration: 1, offset: 5), forKey: key)
        case .bounce:
            layer.add(CAAnimation.bounceAnimation(repeatTimes: .infinity, duration: 1, offset: 5), forKey: key)
        case .breathe:
            layer.add(CAAnimation.opacityForeverAnimation(time: 1), forKey: key)
        }
    }
}
