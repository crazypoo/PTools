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
            // 清理旧的长按手势
            gestureRecognizers?
                .filter { $0 is UILongPressGestureRecognizer }
                .forEach { removeGestureRecognizer($0) }
            
            guard longPressBlock != nil else { return }
            
            let longPressGestureRecognizer = UILongPressGestureRecognizer { [weak self] sender in
                guard let self = self, let gestureRecognizer = sender as? UILongPressGestureRecognizer else { return }
                
                switch gestureRecognizer.state {
                case .began:
                    self.longPressBlock?(self)
                    self.skipTapEventOnce = true
                    if self.draggableAfterLongPress {
                        self.draggable = true
                    }
                case .cancelled, .ended, .failed: // 增加对 ended 和 failed 的处理
                    self.longPressEndedBlock?(self)
                default: break
                }
            }
            longPressGestureRecognizer.cancelsTouchesInView = false
            longPressGestureRecognizer.allowableMovement = 0
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
    
    // 优化：使用 Swift 原生数组，并且存储 UIView（因为只做视觉展示）
    private var traceViews = [UIView]()
    private var autoAddTraceButtonTimer: Timer?
    
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
    
    deinit {
        autoAddTraceButtonTimer?.invalidate()
    }
    
    private func defaultSetting() {
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    // MARK: - 触摸事件处理
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
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
        
        UIView.animate(withDuration: PFloatingButton.RC_DEFAULT_ANIMATE_DURATION, delay: 0, options: .curveEaseOut, animations: {
            if self.center.x >= middleX {
                self.center.x = superviewWidth - self.bounds.size.width / 2
            } else {
                self.center.x = self.bounds.size.width / 2
            }
            _ = self.checkIfOutOfBoundsThenFixIt(fixIt: true)
        }) { _ in
            self.autoDockEndedBlock?(self)
        }
    }
    
    private func dockingToPoint() {
        guard isDockPointAvailable() else { return }
        
        autoDockingBlock?(self)
        
        UIView.animate(withDuration: PFloatingButton.RC_DEFAULT_ANIMATE_DURATION, delay: 0, options: .curveEaseOut, animations: {
            self.center = self.dockPoint
            _ = self.checkIfExceedingLimitedDistanceThenFixIt(fixIt: true)
            _ = self.checkIfOutOfBoundsThenFixIt(fixIt: true)
        }) { _ in
            self.autoDockEndedBlock?(self)
        }
    }
    
    // 优化：使用 snapshot 替代复杂的 Archiver，极大提升性能
    private func addTraceView() {
        guard let superview = superview else { return }
        
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
        
        autoAddTraceButtonTimer?.invalidate()
        autoAddTraceButtonTimer = Timer.scheduledTimer(withTimeInterval: PFloatingButton.RC_TRACE_DISMISS_TIME_INTERVAL, repeats: false) { [weak self, weak traceView] _ in
            guard let self = self, let viewToRemove = traceView else { return }
            UIView.animate(withDuration: 0.2, animations: {
                viewToRemove.alpha = 0
            }) { _ in
                viewToRemove.removeFromSuperview()
                self.traceViews.removeAll(where: { $0 == viewToRemove })
            }
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
        traceViews.forEach { $0.removeFromSuperview() }
        traceViews.removeAll()
    }
    
    public func setDraggableAfterLongPress(_ enabled: Bool) {
        draggableAfterLongPress = enabled
    }
    
    public func triggerWillBeRemoved() {
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
    
    public override func removeFromSuperview() { // 修正了拼写，复写系统的 removeFromSuperview
        willBeRemovedBlock?(self)
        removeTraces()
        autoAddTraceButtonTimer?.invalidate()
        super.removeFromSuperview()
    }
}

// MARK: - UIGestureRecognizerDelegate Extension
private extension UIGestureRecognizer {
    convenience init(actionHandler: @escaping (UIGestureRecognizer) -> Void) {
        self.init()
        addAction(actionHandler)
    }
    
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
