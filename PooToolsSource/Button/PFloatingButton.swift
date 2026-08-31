//
//  PButtonBlock.swift
//  SwiftBlockTest
//
//  Created by 邓杰豪 on 2016/9/1.
//  Copyright © 2016年 邓杰豪. All rights reserved.
//

import UIKit

public typealias PTFloatingButtonTask = (_ button: PFloatingButton) -> Void

@objcMembers
open class PFloatingButton: UIButton {
    
    // MARK: - 静态常量
    public static let RC_POINT_NULL = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: -CGFloat.greatestFiniteMagnitude)
    public static let RC_TRACES_NUMBER = 10
    public static let RC_TRACE_DISMISS_TIME_INTERVAL: TimeInterval = 0.5
    public static let RC_DEFAULT_ANIMATE_DURATION: TimeInterval = 0.2
    
    // MARK: - 回调闭包
    public var longPressBlock: PTFloatingButtonTask? {
        didSet {
            // Keep only the gesture recognizer owned by this button.
            // Conservamos únicamente el reconocedor de gestos propiedad de este botón.
            // 只移除当前按钮自己创建的手势，避免破坏调用方添加的长按手势。
            if let longPressGestureRecognizer {
                removeGestureRecognizer(longPressGestureRecognizer)
                self.longPressGestureRecognizer = nil
                isLongPressActive = false
            }

            guard longPressBlock != nil else { return }
            
            let longPressGestureRecognizer = UILongPressGestureRecognizer { [weak self] sender in
                guard let self = self, let gestureRecognizer = sender as? UILongPressGestureRecognizer else { return }
                
                switch gestureRecognizer.state {
                case .began:
                    guard !self.isLongPressActive else { return }
                    self.isLongPressActive = true
                    self.longPressBlock?(self)
                    self.skipTapEventOnce = true
                    if self.draggableAfterLongPress {
                        self.draggable = true
                    }
                case .cancelled, .ended, .failed:
                    guard self.isLongPressActive else { return }
                    self.isLongPressActive = false
                    self.longPressEndedBlock?(self)
                default: break
                }
            }
            longPressGestureRecognizer.cancelsTouchesInView = false
            longPressGestureRecognizer.allowableMovement = 0
            self.longPressGestureRecognizer = longPressGestureRecognizer
            addGestureRecognizer(longPressGestureRecognizer)
        }
    }
    
    open var longPressEndedBlock: PTFloatingButtonTask?
    open var tapBlock: PTFloatingButtonTask?
    open var doubleTapBlock: PTFloatingButtonTask?
    open var layerConfigBlock: PTFloatingButtonTask? // 注意：轨迹优化后，这个闭包可能需要调整用法
    open var draggingBlock: PTFloatingButtonTask?
    open var dragEndedBlock: PTFloatingButtonTask?
    open var autoDockEndedBlock: PTFloatingButtonTask?
    open var dragCancelledBlock: PTFloatingButtonTask?
    open var autoDockingBlock: PTFloatingButtonTask?
    open var willBeRemovedBlock: PTFloatingButtonTask?
    
    // MARK: - 配置属性
    open var draggable: Bool = true
    open var autoDocking: Bool = false
    open var dragOutOfBoundsEnabled: Bool = false
    open var dockPoint: CGPoint = PFloatingButton.RC_POINT_NULL
    open var limitedDistance: CGFloat = -1.0
    open var isTraceEnabled: Bool = false
    open var dragEnd: PTActionTask?

    // MARK: - 私有状态
    private var singleTapCanceled = false
    private var skipTapEventOnce = false
    private var isDragging = false
    private var touchBeginPoint: CGPoint?
    private var willBeRemoved = false
    private var draggableAfterLongPress = false
    private var isRecordingDraggingPathEnabled = false
    private var isLongPressActive = false
    private var lastTraceCenter: CGPoint?
    private var didInstallDefaultTarget = false
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?

    // Store only the lightweight trace views required for the visible trail.
    // Guardamos únicamente las vistas ligeras necesarias para la estela visible.
    // 只保留显示轨迹所需的轻量视图。
    private var traceViews = [UIView]()
    
    private lazy var draggingPath: UIBezierPath = {
        return UIBezierPath()
    }()
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        defaultSetting()
    }
    
    // 优化：将 Any 改为 UIView? 增加类型安全
    public init(inView superview: UIView?, frame: CGRect) {
        super.init(frame: frame)
        superview?.addSubview(self)
        defaultSetting()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        defaultSetting()
    }
    
    private func defaultSetting() {
        guard !didInstallDefaultTarget else { return }
        didInstallDefaultTarget = true
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    // MARK: - 触摸事件处理
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        skipTapEventOnce = false
        lastTraceCenter = nil
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        
        singleTapCanceled = touch.tapCount == 2
        if singleTapCanceled {
            doubleTapBlock?(self)
        }
        touchBeginPoint = touch.location(in: self)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard draggable, let touch = touches.first, let startPoint = touchBeginPoint else { return }
        isDragging = true
        
        let currentPoint = touch.location(in: self)
        let offsetX = currentPoint.x - startPoint.x
        let offsetY = currentPoint.y - startPoint.y

        resetCenter(center: CGPoint(x: center.x + offsetX, y: center.y + offsetY))
        
        if isTraceEnabled {
            addTraceView()
        }
        
        if isRecordingDraggingPathEnabled {
            draggingPath.addLine(to: center)
        }
        
        draggingBlock?(self)
        skipTapEventOnce = true
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        handleTouchEndOrCancel()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        handleTouchEndOrCancel()
        dragCancelledBlock?(self)
    }
    
    private func handleTouchEndOrCancel() {
        if isDragging {
            dragEndedBlock?(self)
            singleTapCanceled = true
            
            if autoDocking {
                if !isDockPointAvailable() {
                    dockingToBorder()
                } else {
                    dockingToPoint()
                }
            }
            if draggableAfterLongPress {
                draggable = false
            }
        }
        isDragging = false
        touchBeginPoint = nil
        lastTraceCenter = nil
        dragEnd?()
    }

    // MARK: - 边界与位置计算
    private func resetCenter(center: CGPoint) {
        self.center = center
        
        if isDockPointAvailable(), isLimitedDistanceAvailable() {
            _ = checkIfExceedingLimitedDistanceThenFixIt(fixIt: true)
        } else if !dragOutOfBoundsEnabled {
            _ = checkIfOutOfBoundsThenFixIt(fixIt: true)
        }
    }
    
    private func isLimitedDistanceAvailable() -> Bool {
        return limitedDistance > 0
    }
    
    private func checkIfExceedingLimitedDistanceThenFixIt(fixIt: Bool) -> Bool {
        let tmpPoint = CGPoint(x: center.x - dockPoint.x, y: center.y - dockPoint.y)
        let distance = distanceFromPoint(point: dockPoint)
        let willExceedingLimitedDistance = distance > limitedDistance
        if willExceedingLimitedDistance, fixIt {
            center = CGPoint(x: tmpPoint.x * limitedDistance / distance + dockPoint.x, y: tmpPoint.y * limitedDistance / distance + dockPoint.y)
        }
        return willExceedingLimitedDistance
    }
    
    private func checkIfOutOfBoundsThenFixIt(fixIt: Bool) -> Bool {
        guard let superview = superview else { return false }
        
        let superviewFrame = superview.bounds // 优化：使用 bounds 更准确
        let leftLimitX = bounds.size.width / 2
        let rightLimitX = superviewFrame.size.width - leftLimitX
        let topLimitY = bounds.size.height / 2
        let bottomLimitY = superviewFrame.size.height - topLimitY
        
        var fixedPoint = center
        fixedPoint.x = min(max(center.x, leftLimitX), rightLimitX)
        fixedPoint.y = min(max(center.y, topLimitY), bottomLimitY)
        
        let willOutOfBounds = (center != fixedPoint)
        if willOutOfBounds && fixIt {
            center = fixedPoint
        }
        return willOutOfBounds
    }
    
    private func distanceFromPoint(point: CGPoint) -> CGFloat {
        return hypot(center.x - point.x, center.y - point.y)
    }
    
    private func isDockPointAvailable() -> Bool {
        return dockPoint != PFloatingButton.RC_POINT_NULL
    }
    
    // MARK: - 动画与视觉效果
    private func dockingToBorder() {
        guard let superview = superview else { return }

        let superviewWidth = superview.bounds.size.width
        let middleX = superviewWidth / 2
        
        autoDockingBlock?(self) // 触发归边开始回调
        
        animateDocking(duration: PFloatingButton.RC_DEFAULT_ANIMATE_DURATION, animations: {
            if self.center.x >= middleX {
                self.center.x = superviewWidth - self.bounds.size.width / 2
            } else {
                self.center.x = self.bounds.size.width / 2
            }
            _ = self.checkIfOutOfBoundsThenFixIt(fixIt: true)
        }) { [weak self] in
            guard let self else { return }
            self.autoDockEndedBlock?(self)
        }
    }
    
    private func dockingToPoint() {
        guard isDockPointAvailable() else { return }
        
        autoDockingBlock?(self)
        
        animateDocking(duration: PFloatingButton.RC_DEFAULT_ANIMATE_DURATION, animations: {
            self.center = self.dockPoint
            _ = self.checkIfExceedingLimitedDistanceThenFixIt(fixIt: true)
            _ = self.checkIfOutOfBoundsThenFixIt(fixIt: true)
        }) { [weak self] in
            guard let self else { return }
            self.autoDockEndedBlock?(self)
        }
    }

    private func animateDocking(duration: TimeInterval, animations: @escaping () -> Void, completion: @escaping () -> Void) {
        let safeDuration = max(0, duration)
        if UIAccessibility.isReduceMotionEnabled || safeDuration == 0 {
            UIView.performWithoutAnimation(animations)
            completion()
            return
        }

        UIView.animate(withDuration: safeDuration,
                       delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                       animations: animations) { _ in
            completion()
        }
    }
    
    // 优化：使用 snapshot 替代复杂的 Archiver，极大提升性能
    private func addTraceView() {
        guard let superview = superview else { return }

        let minimumTraceDistance: CGFloat = 8
        if let lastTraceCenter, distance(from: lastTraceCenter, to: center) < minimumTraceDistance {
            return
        }
        lastTraceCenter = center
        
        if traceViews.count >= PFloatingButton.RC_TRACES_NUMBER {
            let oldTrace = traceViews.removeFirst()
            oldTrace.removeFromSuperview()
        }
        
        // 创建当前状态的快照作为轨迹，性能最好
        guard let traceView = self.snapshotView(afterScreenUpdates: false) else { return }
        traceView.frame = self.frame
        traceView.alpha = 0.5 // 设置轨迹透明度
        
        traceViews.append(traceView)
        superview.insertSubview(traceView, belowSubview: self)

        // Each trace owns its delayed fade, so rapid dragging does not replace one shared timer.
        // Cada traza posee su propio desvanecimiento retrasado, sin reemplazar un temporizador compartido.
        // 每条轨迹独立管理延迟淡出，快速拖动时不会互相覆盖计时器。
        UIView.animate(withDuration: 0.2,
                       delay: PFloatingButton.RC_TRACE_DISMISS_TIME_INTERVAL,
                       options: [.beginFromCurrentState, .allowUserInteraction]) {
            traceView.alpha = 0
        } completion: { [weak self, weak traceView] _ in
            guard let self, let traceView else { return }
            traceView.removeFromSuperview()
            self.traceViews.removeAll { $0 === traceView }
        }
    }
    
    // MARK: - 公共方法
    public func startRecordingDraggingPath() {
        isRecordingDraggingPathEnabled = true
        draggingPath.removeAllPoints()
        draggingPath.move(to: center)
    }
    
    public func endRecordingDraggingPath() -> UIBezierPath {
        isRecordingDraggingPathEnabled = false
        return draggingPath
    }
    
    public func removeTraces() {
        traceViews.forEach {
            $0.layer.removeAllAnimations()
            $0.removeFromSuperview()
        }
        traceViews.removeAll()
        lastTraceCenter = nil
    }
    
    public func setDraggableAfterLongPress(_ enabled: Bool) {
        draggableAfterLongPress = enabled
    }
    
    public func triggerWillBeRemoved() {
        notifyWillBeRemovedIfNeeded()
    }

    private func notifyWillBeRemovedIfNeeded() {
        guard !willBeRemoved else { return }
        willBeRemoved = true
        willBeRemovedBlock?(self)
    }
    
    @objc private func handleTap() {
        if !singleTapCanceled && tapBlock != nil && !isDragging && !skipTapEventOnce {
            tapBlock?(self)
        } else {
            skipTapEventOnce = false
        }
    }
    
    public override func removeFromSuperview() {
        // Notify once before removal and reset the state when the button is attached again.
        // Notificamos una sola vez antes de retirar la vista y reiniciamos el estado al volver a insertarla.
        // 移除前只通知一次，重新添加到层级后再重置状态。
        notifyWillBeRemovedIfNeeded()
        removeTraces()
        super.removeFromSuperview()
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            willBeRemoved = false
        }
    }

    private func distance(from firstPoint: CGPoint, to secondPoint: CGPoint) -> CGFloat {
        hypot(firstPoint.x - secondPoint.x, firstPoint.y - secondPoint.y)
    }
}

// MARK: - UIGestureRecognizerDelegate Extension
private extension UIGestureRecognizer {
    convenience init(actionHandler: @escaping (UIGestureRecognizer) -> Void) {
        self.init()
        addAction(actionHandler)
    }
    
    @MainActor
    private struct AssociatedKeys {
        static var actionKey:UInt8 = 0
    }
    
    private func addAction(_ action: @escaping (UIGestureRecognizer) -> Void) {
        let sleeve = ClosureSleeve(action)
        objc_setAssociatedObject(self, &AssociatedKeys.actionKey, sleeve, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke(_:)))
    }
}

private class ClosureSleeve {
    let closure: (UIGestureRecognizer) -> Void
    init(_ closure: @escaping (UIGestureRecognizer) -> Void) { self.closure = closure }
    @objc func invoke(_ sender: UIGestureRecognizer) { closure(sender) }
}
