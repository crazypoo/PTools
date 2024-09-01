//
//  PButtonBlock.swift
//  SwiftBlockTest
//
//  Created by 邓杰豪 on 2016/9/1.
//  Copyright © 2016年 邓杰豪. All rights reserved.
//

import UIKit

public typealias PTFloatingButtonTask = (_ button:PFloatingButton) -> Void

@objcMembers
open class PFloatingButton: UIButton {
    
    public static let RC_POINT_NULL = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: -CGFloat.greatestFiniteMagnitude)
    public static let RC_TRACES_NUMBER = 10
    public static let RC_TRACE_DISMISS_TIME_INTERVAL = 0.5
    public static let RC_DEFAULT_ANIMATE_DURATION = 0.2
    
    //MARK: 回调闭包
    public var longPressBlock: PTFloatingButtonTask? {
        didSet {
            gestureRecognizers?
                .filter { $0 is UILongPressGestureRecognizer }
                .forEach { removeGestureRecognizer($0) }
            
            let longPressGestureRecognizer = UILongPressGestureRecognizer { [weak self] sender in
                guard let self = self else { return }
                let gestureRecognizer = sender as! UILongPressGestureRecognizer
                switch gestureRecognizer.state {
                case .began:
                    self.longPressBlock?(self)
                    self.skipTapEventOnce = true
                    if self.draggableAfterLongPress {
                        self.draggable = true
                    }
                case .cancelled:
                    self.longPressEndedBlock?(self)
                default: break
                }
            }
            longPressGestureRecognizer.cancelsTouchesInView = false
            longPressGestureRecognizer.allowableMovement = 0
            addGestureRecognizer(longPressGestureRecognizer)
        }
    }
    
    //MARK: 長按結束後回調
    open var longPressEndedBlock: PTFloatingButtonTask?
    //MARK: 點擊回調
    open var tapBlock: PTFloatingButtonTask?
    //MARK: 雙擊回調
    open var doubleTapBlock: PTFloatingButtonTask?
    //MARK: 浮動Content回調
    open var layerConfigBlock: PTFloatingButtonTask?
    //MARK: 拖動回調
    open var draggingBlock: PTFloatingButtonTask?
    //MARK: 拖動結束回調
    open var dragEndedBlock: PTFloatingButtonTask?
    //MARK: 自動歸邊結束回調
    open var autoDockEndedBlock: PTFloatingButtonTask?
    //MARK: 取消拖動回調
    open var dragCancelledBlock: PTFloatingButtonTask?
    //MARK: 自動歸邊回調
    open var autoDockingBlock: PTFloatingButtonTask?
    //MARK: 將要移除回調
    open var willBeRemovedBlock: PTFloatingButtonTask?
    
    //MARK: 是否支持拖動
    open var draggable: Bool = true
    //MARK: 是否支持自動歸邊
    open var autoDocking: Bool = false
    //MARK: 是否支持超邊拖動
    open var dragOutOfBoundsEnabled: Bool = false
    //MARK: 邊界
    open var dockPoint: CGPoint = PFloatingButton.RC_POINT_NULL
    //MARK: 最小距離
    open var limitedDistance: CGFloat = -1.0
    //MARK: 是否跟蹤按鈕
    open var isTraceEnabled: Bool = false
    open var dragEnd: PTActionTask?

    private var singleTapCanceled = false
    private var skipTapEventOnce = false
    private var isDragging = false
    private var touchBeginPoint: CGPoint?
    private var moveBeginPoint: CGPoint?
    private var traceDismissTimer: Timer?
    private var willBeRemoved = false
    private var draggableAfterLongPress = false
    private var isRecordingDraggingPathEnabled = false
    private var traceButtons = NSMutableArray(capacity: PFloatingButton.RC_TRACES_NUMBER)

    private lazy var draggingPath: UIBezierPath = {
        return UIBezierPath()
    }()
    
    private lazy var loadTraceButton: PFloatingButton = {
        do {
            let view = try NSKeyedUnarchiver.unarchivedObject(ofClass: PFloatingButton.self, from: NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false))!
            view.alpha = 0.8
            view.isSelected = false
            view.isHighlighted = false
            layerConfigBlock?(view)
            return view
        } catch {
            return PFloatingButton()
        }
    }()
        
    private var autoAddTraceButtonTimer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        defaultSetting()
    }
    
    public init(view: Any, frame: CGRect) {
        super.init(frame: frame)
        if let superview = view as? UIView {
            superview.addSubview(self)
        } else if view is UIWindow {
            AppWindows!.addSubview(self)
        } else {
            AppWindows!.addSubview(self)
        }
        defaultSetting()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func defaultSetting() {
        addActionHandlers { [weak self] _ in
            guard let self = self else { return }
            if !self.singleTapCanceled && self.tapBlock != nil && !self.isDragging && !self.skipTapEventOnce {
                self.tapBlock!(self)
            } else {
                self.skipTapEventOnce = false
            }
        }
    }
    
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
        guard draggable, let touch = touches.first else { return }
        isDragging = true
        let currentPoint = touch.location(in: self)
        let offsetX = currentPoint.x - touchBeginPoint!.x
        let offsetY = currentPoint.y - touchBeginPoint!.y

        resetCenter(center: CGPoint(x: center.x + offsetX, y: center.y + offsetY))
        
        if isTraceEnabled {
            addTraceButton()
        }
        
        if isRecordingDraggingPathEnabled {
            draggingPath.addLine(to: center)
        }
        
        draggingBlock?(self)
        skipTapEventOnce = true
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
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

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        isDragging = false
        singleTapCanceled = true
        if draggableAfterLongPress {
            draggable = false
        }
        dragCancelledBlock?(self)
    }

    private func resetCenter(center: CGPoint) {
        self.center = center
        
        if isDockPointAvailable(), isLimitedDistanceAvailable() {
            let _ = checkIfExceedingLimitedDistanceThenFixIt(fixIt: true)
        } else if !dragOutOfBoundsEnabled {
            let _ = checkIfOutOfBoundsThenFixIt(fixIt: true)
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
        var willOutOfBounds = true
        let superviewFrame = superview.frame
        let frame = frame
        let leftLimitX = frame.size.width / 2
        let rightLimitX = superviewFrame.size.width - leftLimitX
        let topLimitY = frame.size.height / 2
        let bottomLimitY = superviewFrame.size.height - topLimitY
        var fixedPoint = center
        
        fixedPoint.x = min(max(center.x, leftLimitX), rightLimitX)
        fixedPoint.y = min(max(center.y, topLimitY), bottomLimitY)
        
        if center == fixedPoint {
            willOutOfBounds = false
        } else if fixIt {
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
    
    private func dockingToBorder() {
        guard let superview = superview else { return }

        let superviewFrame = superview.frame
        let middleX = superviewFrame.size.width / 2
        let animationDuration = PFloatingButton.RC_DEFAULT_ANIMATE_DURATION

        UIView.animate(withDuration: animationDuration) {
            if self.center.x >= middleX {
                self.center.x = superviewFrame.size.width - self.frame.size.width / 2
            } else {
                self.center.x = self.frame.size.width / 2
            }
            let _ = self.checkIfOutOfBoundsThenFixIt(fixIt: true)
            self.autoDockEndedBlock?(self)
        }
    }
    
    private func dockingToPoint() {
        guard isDockPointAvailable() else { return }
        UIView.animate(withDuration: PFloatingButton.RC_DEFAULT_ANIMATE_DURATION) {
            self.center = self.dockPoint
            let _ = self.checkIfExceedingLimitedDistanceThenFixIt(fixIt: true)
            let _ = self.checkIfOutOfBoundsThenFixIt(fixIt: true)
            self.autoDockEndedBlock?(self)
        }
    }
    
    private func addTraceButton() {
        guard traceButtons.count < PFloatingButton.RC_TRACES_NUMBER else {
            traceButtons.removeObject(at: 0)
            return
        }
        
        let traceButton = loadTraceButton
        traceButton.frame = frame
        traceButtons.add(traceButton)
        superview?.insertSubview(traceButton, belowSubview: self)
        
        autoAddTraceButtonTimer?.invalidate()
        autoAddTraceButtonTimer = Timer.scheduledTimer(withTimeInterval: PFloatingButton.RC_TRACE_DISMISS_TIME_INTERVAL, repeats: false) { [weak self] _ in
            traceButton.removeFromSuperview()
            self?.traceButtons.remove(traceButton)
        }
    }
    
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
        traceButtons.forEach {
            ($0 as! PFloatingButton).removeFromSuperview()
        }
        traceButtons.removeAllObjects()
    }
    
    public func setDraggableAfterLongPress(_ enabled: Bool) {
        draggableAfterLongPress = enabled
    }
    
    public func triggerWillBeRemoved() {
        willBeRemoved = true
        willBeRemovedBlock?(self)
    }
    
    // Utility method to add action handlers to the button
    private func addActionHandlers(_ action: @escaping (PFloatingButton) -> Void) {
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    @objc private func handleTap() {
        if !singleTapCanceled && tapBlock != nil && !isDragging && !skipTapEventOnce {
            tapBlock?(self)
        } else {
            skipTapEventOnce = false
        }
    }
    
    public func removeFromSuperView() {
        if willBeRemovedBlock != nil {
            willBeRemovedBlock!(self)
        }
        super.removeFromSuperview()
    }
}
