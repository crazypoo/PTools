//
//  PButtonBlock.swift
//  SwiftBlockTest
//
//  Created by 邓杰豪 on 2016/9/1.
//  Copyright © 2016年 邓杰豪. All rights reserved.
//

import UIKit

@objcMembers
open class PFloatingButton: UIButton {
    
    public static let RC_POINT_NULL = CGPoint.init(x: CGFloat(MAXFLOAT), y: -CGFloat(MAXFLOAT))
    public static let RC_TRACES_NUMBER = 10
    public static let RC_TRACE_DISMISS_TIME_INTERVAL = 0.5
    public static let RC_DEFAULT_ANIMATE_DURATION = 0.2
    
    public var longPressBlock:((_ button:PFloatingButton)->Void)?
    {
        didSet
        {
            self.gestureRecognizers?.enumerated().forEach({ (index,gestureRecognizer) in
                if gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self)
                {
                    self.removeGestureRecognizer(gestureRecognizer)
                }
            })
            
            let longPressGestureRecognizer = UILongPressGestureRecognizer.init()
            longPressGestureRecognizer.cancelsTouchesInView = false
            longPressGestureRecognizer.addTarget(self, action: #selector(self.gestureRecognizerHandle(gestureRecognizer:)))
            longPressGestureRecognizer.allowableMovement = 0
            self.addGestureRecognizer(longPressGestureRecognizer)
        }
    }
    public var longPressEndedBlock:((_ button:PFloatingButton)->Void)?
    public var tapBlock:((_ button:PFloatingButton)->Void)?
    public var doubleTapBlock:((_ button:PFloatingButton)->Void)?
    public var layerConfigBlock:((_ button:PFloatingButton)->Void)?
    public var draggingBlock:((_ button:PFloatingButton)->Void)?
    public var dragEndedBlock:((_ button:PFloatingButton)->Void)?
    public var autoDockEndedBlock:((_ button:PFloatingButton)->Void)?
    public var dragCancelledBlock:((_ button:PFloatingButton)->Void)?
    public var autoDockingBlock:((_ button:PFloatingButton)->Void)?
    public var willBeRemovedBlock:((_ button:PFloatingButton)->Void)?
    
    public var draggable : Bool? = true
    public var autoDocking : Bool? = false
    public var dragOutOfBoundsEnabled : Bool? = false
    public var dockPoint : CGPoint? = PFloatingButton.RC_POINT_NULL
    public var limitedDistance : CGFloat? = -1.0
    public var isTraceEnabled : Bool? = false
    
    private var singleTapCanceled : Bool? = false
    private var skipTapEventOnce : Bool? = false
    private var isDragging : Bool? = false
    private var touchBeginPoint:CGPoint?
    private var moveBeginPoint:CGPoint?
    private var traceDismissTimer:Timer?
    private var willBeRemoved : Bool? = false
    private var draggableAfterLongPress : Bool? = false
    private var isRecordingDraggingPathEnabled : Bool? = false
    private var traceButtons = NSMutableArray.init(capacity: PFloatingButton.RC_TRACES_NUMBER)

    private lazy var draggingPath:UIBezierPath = {
        let path = UIBezierPath()
        return path
    }()
    
    lazy var loadTraceButton : PFloatingButton = {
        let view : PFloatingButton = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! PFloatingButton
        view.alpha = 0.8
        view.isSelected = false
        view.isHighlighted = false
        if layerConfigBlock != nil
        {
            layerConfigBlock!(view)
        }
        return view
    }()
        
    var autoAddTraceButtonTimer:Timer?
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.defultSetting()
    }
    
    public init(view:Any,frame:CGRect)
    {
        super.init(frame: frame)
        if view is UIView
        {
            (view as! UIView).addSubview(self)
        }
        else if view is UIWindow
        {
            AppWindows!.addSubview(self)
        }
        else
        {
            AppWindows!.addSubview(self)
        }
        
        self.defultSetting()
    }
    
    func defultSetting()
    {
        self.addActionHandlers { sender in
            if !self.singleTapCanceled! && self.tapBlock != nil && !self.isDragging! && !self.skipTapEventOnce!
            {
                self.tapBlock!(self)
            }
            else
            {
                self.skipTapEventOnce = false
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func gestureRecognizerHandle(gestureRecognizer:UILongPressGestureRecognizer)
    {
        switch gestureRecognizer.state {
        case .began:
            if longPressBlock != nil
            {
                longPressBlock!(self)
            }
            
            skipTapEventOnce = true
            
            if draggableAfterLongPress!
            {
                draggable = true
            }
        case .ended:break
        case .cancelled:
            if longPressEndedBlock != nil
            {
                longPressEndedBlock!(self)
            }
        default:break
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        isDragging = false
        super.touchesBegan(touches, with: event)
        let touch:UITouch = touches.first!
        if touch.tapCount == 2
        {
            if doubleTapBlock != nil {
                singleTapCanceled = true
                doubleTapBlock!(self)
            }
        }
        else
        {
            singleTapCanceled = false
        }
        touchBeginPoint = touch.location(in: self)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if draggable!
        {
            isDragging = true
            let touch = touches.first
            let currentPoint = touch?.location(in: self)
            let offsetX = currentPoint!.x - touchBeginPoint!.x
            let offsetY = currentPoint!.y - touchBeginPoint!.y

            self.resetCenter(center: CGPoint.init(x: center.x + offsetX, y: center.y + offsetY))
            
            if isTraceEnabled!
            {
                self.addTraceButton()
            }
            
            if isRecordingDraggingPathEnabled!
            {
                draggingPath.addLine(to: self.center)
            }
            
            if draggingBlock != nil
            {
                draggingBlock!(self)
            }
            
            skipTapEventOnce = true
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if (isDragging! && dragEndedBlock != nil) {
            dragEndedBlock!(self);
            singleTapCanceled = true;
        }
        
        if isDragging! && autoDocking!
        {
            if !self.isDockPointAvailable()
            {
                self.dockingToBorder()
            }
            else
            {
                self.dockingToPoint()
            }
        }
        
        if draggableAfterLongPress!
        {
            draggable = false
        }
        
        isDragging = false
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        isDragging = false
        singleTapCanceled = true
        if draggableAfterLongPress!
        {
            draggable = false
        }
        
        if dragCancelledBlock != nil
        {
            dragCancelledBlock!(self)
        }
    }

    func resetCenter(center:CGPoint)
    {
        self.center = center
        
        if self.isDockPointAvailable() && self.isLimitedDistanceAvailable()
        {
            let bool = self.checkIfExceedingLimitedDistanceThenFixIt(fixIt: true)
            print(bool)
        }
        else if !dragOutOfBoundsEnabled!
        {
            let bool = self.checkIfOutOfBoundsThenFixIt(fixIt: true)
            print(bool)
        }
    }
    
    func isLimitedDistanceAvailable()->Bool
    {
        return (limitedDistance! > 0)
    }
    
    func checkIfExceedingLimitedDistanceThenFixIt(fixIt:Bool)->Bool
    {
        let tmpPoint = CGPoint.init(x: self.center.x - dockPoint!.x, y: self.center.y - dockPoint!.y)
        let distance = self.distanceFromPoint(point: dockPoint!)
        let willExceedingLimitedDistance = distance > limitedDistance!
        if willExceedingLimitedDistance && fixIt
        {
            self.center = CGPoint.init(x: tmpPoint.x * limitedDistance! / distance + dockPoint!.y, y: tmpPoint.y * limitedDistance! / distance + dockPoint!.y)
        }
        return willExceedingLimitedDistance
    }
    
    func checkIfOutOfBoundsThenFixIt(fixIt:Bool)->Bool
    {
        var willOutOfBounds = true
        let superviewFrame = self.superview!.frame
        let frame = self.frame
        let leftLimitX = frame.size.width / 2
        let rightLimitX = superviewFrame.size.width - leftLimitX
        let topLimitY = frame.size.height / 2
        let bottomLimitY = superviewFrame.size.height - topLimitY
        var fixedPoint = self.center
        
        if self.center.x > rightLimitX
        {
            fixedPoint.x = rightLimitX
        }
        else if self.center.x <= leftLimitX
        {
            fixedPoint.x = leftLimitX
        }
        
        if self.center.y > bottomLimitY
        {
            fixedPoint.y = bottomLimitY
        }
        else if self.center.y <= topLimitY
        {
            fixedPoint.y = topLimitY
        }
        
        if __CGPointEqualToPoint(self.center, fixedPoint)
        {
            willOutOfBounds = false
        }
        else if (fixIt)
        {
            self.center = fixedPoint
        }
        return willOutOfBounds
    }
    
    func distanceFromPoint(point:CGPoint)->CGFloat
    {
        return hypot(self.center.x - point.x, self.center.y - point.y)
    }
    
    func isDockPointAvailable()->Bool
    {
        return !__CGPointEqualToPoint(self.dockPoint!, PFloatingButton.RC_POINT_NULL)
    }
    
    func dockingToBorder()
    {
        let superviewFrame:CGRect = (self.superview?.frame)!
        let frame = self.frame
        let middleX = superviewFrame.size.width/2

        UIView.animate(withDuration: PFloatingButton.RC_DEFAULT_ANIMATE_DURATION) {
            if self.center.x >= middleX
            {
                self.center = CGPoint.init(x: superviewFrame.size.width - frame.size.width / 2, y: self.center.y)
            }
            else
            {
                self.center = CGPoint.init(x:frame.size.width / 2, y:self.center.y)
            }
            
            if self.autoDockingBlock != nil {
                self.autoDockingBlock!(self)
            }
        } completion: { finish in
            if self.isRecordingDraggingPathEnabled!
            {
                self.draggingPath.addLine(to: self.center)
            }
            
            if self.autoDockEndedBlock != nil
            {
                self.autoDockEndedBlock!(self)
            }
        }
    }
    
    func dockingToPoint()
    {
        UIView.animate(withDuration: PFloatingButton.RC_DEFAULT_ANIMATE_DURATION) {
            self.center = self.dockPoint!
            if self.autoDockingBlock != nil {
                self.autoDockingBlock!(self)
            }
        } completion: { (finish) in
            if self.isRecordingDraggingPathEnabled!
            {
                self.draggingPath.addLine(to: self.center)
            }
            
            if self.autoDockEndedBlock != nil
            {
                self.autoDockEndedBlock!(self)
            }
        }
    }
    
    func addTraceButton()
    {
        if traceButtons.count < PFloatingButton.RC_TRACES_NUMBER
        {
            let traceButton = self.loadTraceButton
            self.superview?.addSubview(traceButton)
            traceButtons.add(traceButton)
        }
        self.superview?.bringSubviewToFront(self)
        
        if traceDismissTimer == nil
        {
            traceDismissTimer = Timer.scheduledTimer(timeInterval: PFloatingButton.RC_TRACE_DISMISS_TIME_INTERVAL, target: self, selector: #selector(self.dismissTraceButton), userInfo: nil, repeats: true)
        }
    }
    
    @objc func dismissTraceButton()
    {
        if traceButtons.count > 0
        {
            (traceButtons.firstObject as! PFloatingButton).removeFromSuperview()
            traceButtons.remove(traceButtons.firstObject as Any)
        }
        else
        {
            traceDismissTimer?.invalidate()
            traceDismissTimer = nil
        }
    }
    
    @objc func dismissSelf()
    {
        self.isHidden = false
        self.perform(#selector(self.removeFromSuperView), with: nil, afterDelay: PFloatingButton.RC_TRACE_DISMISS_TIME_INTERVAL)
    }
    
    class open func itemInView(view:Any?)->[PFloatingButton]
    {
        var newView : Any?
        if view == nil
        {
            newView = AppWindows!
        }
        else
        {
            newView = view
        }
        
        var subViews = [PFloatingButton]()
        if newView is UIWindow
        {
            (newView as! UIWindow).subviews.enumerated().forEach { (index,value) in
                if value.isKind(of: PFloatingButton.self)
                {
                    subViews.append(value as! PFloatingButton)
                }
            }
        }
        else if newView is UIView
        {
            (newView as! UIView).subviews.enumerated().forEach { (index,value) in
                if value.isKind(of: PFloatingButton.self)
                {
                    subViews.append(value as! PFloatingButton)
                }
            }
        }
        return subViews
    }
    
    class open func removeAllFromView(view:Any)
    {
        PFloatingButton.itemInView(view: view).enumerated().forEach { (index,value) in
            value.removeFromSuperview()
        }
    }
    
    class open func removeAllFromView(view:Any,tag:NSInteger)
    {
        PFloatingButton.itemInView(view: view).enumerated().forEach { (index,value) in
            if value.tag == tag
            {
                value.removeFromSuperview()
            }
        }
    }
    
    class open func removeAllFromViews(view:Any,tags:[NSInteger])
    {
        tags.enumerated().forEach { (index,value) in
            PFloatingButton.removeAllFromView(view: view, tag: value)
        }
    }
    
    class open func removeAllFromView(view:Any,insideRect:CGRect)
    {
        PFloatingButton.itemInView(view: view).enumerated().forEach { (index,value) in
            if value.isInsideRect(rect: insideRect)
            {
                value.removeFromSuperview()
            }
        }
    }
    
    func removeFromSuperviewInsideRect(rect:CGRect)
    {
        if self.superview != nil && self.isInsideRect(rect: rect)
        {
            self.removeFromSuperview()
        }
    }
    
    class open func removeAllFromView(view:Any,intersectsRect:CGRect) {
        PFloatingButton.itemInView(view: view).enumerated().forEach { (index,value) in
            if value.isIntersectsRect(rect: intersectsRect)
            {
                value.removeFromSuperview()
            }
        }
    }

    func removeFromSuperviewIntersectsRect(rect:CGRect) {
        if self.superview != nil && self.isIntersectsRect(rect: rect)
        {
            self.removeFromSuperview()
        }
    }
    
    class open func removeAllFromView(view:Any,crossedRect:CGRect) {
        PFloatingButton.itemInView(view: view).enumerated().forEach { (index,value) in
            if value.isCrossedRect(rect: crossedRect)
            {
                value.removeFromSuperview()
            }
        }
    }

    func removeFromSuperviewCrossedRect(rect:CGRect) {
        if self.superview != nil && self.isInsideRect(rect: rect)
        {
            self.removeFromSuperview()
        }
    }
    
    @objc func removeFromSuperView()
    {
        if willBeRemovedBlock != nil
        {
            willBeRemovedBlock!(self)
        }
        willBeRemoved = true
        
        super.removeFromSuperview()
    }
    
    func isInsideRect(rect:CGRect)->Bool
    {
        return rect.contains(self.frame)
    }
    
    func isIntersectsRect(rect:CGRect)->Bool
    {
        return rect.intersects(self.frame)
    }
    
    func isCrossedRect(rect:CGRect)->Bool
    {
        return self.isIntersectsRect(rect: rect) && !self.isInsideRect(rect: rect)
    }
    
    class open func allInView(view:Any,point:CGPoint,duration:TimeInterval? = PFloatingButton.RC_DEFAULT_ANIMATE_DURATION,delay:TimeInterval? = 0,options:UIView.AnimationOptions? = UIView.AnimationOptions.layoutSubviews,completion:(()->Void)?)
    {
        PFloatingButton.itemInView(view: view).enumerated().forEach { (index,value) in
            value.moveToPoint(point: point, duration: duration, delay: delay, options: options, completion: completion)
        }
    }
    
    class open func inView(view:Any,tag:NSInteger,point:CGPoint,duration:TimeInterval? = PFloatingButton.RC_DEFAULT_ANIMATE_DURATION,delay:TimeInterval? = 0,options:UIView.AnimationOptions? = UIView.AnimationOptions.layoutSubviews,completion:(()->Void)?)
    {
        PFloatingButton.itemInView(view: view).enumerated().forEach { (index,value) in
            if value.tag == tag
            {
                value.moveToPoint(point: point, duration: duration, delay: delay, options: options, completion: completion)
            }
        }
    }

    class open func inViews(view:Any,tags:[NSInteger],point:CGPoint,duration:TimeInterval? = PFloatingButton.RC_DEFAULT_ANIMATE_DURATION,delay:TimeInterval? = 0,options:UIView.AnimationOptions? = UIView.AnimationOptions.layoutSubviews,completion:(()->Void)?)
    {
        tags.enumerated().forEach { (index,value) in
            PFloatingButton.inView(view: view, tag: value, point: point, duration: duration, delay: delay, options: options, completion: completion)
        }
    }

    func addTraceButtonsDuringMoveToPoint(point:CGPoint,duration:TimeInterval,delay:TimeInterval,options:UIView.AnimationOptions)
    {
        for count in 0...PFloatingButton.RC_TRACES_NUMBER
        {
            let traceButton = self.loadTraceButton
            traceButton.center = moveBeginPoint!
            self.superview?.addSubview(traceButton)
            
            traceButton.moveToPoint(point: point, duration: duration + duration * Double(PFloatingButton.RC_TRACES_NUMBER - count) / Double(PFloatingButton.RC_TRACES_NUMBER), delay: delay, options: options, completion: nil)
            
            traceButton.perform(#selector(self.dismissSelf), with: nil, afterDelay: Double(count) * duration / Double(PFloatingButton.RC_TRACES_NUMBER))
        }
        
        self.superview?.bringSubviewToFront(self)
    }
    
    func moveToPoint(point:CGPoint,duration:TimeInterval? = PFloatingButton.RC_DEFAULT_ANIMATE_DURATION,delay:TimeInterval? = 0,options:UIView.AnimationOptions? = UIView.AnimationOptions.layoutSubviews,completion:(()->Void)?)
    {
        if !willBeRemoved!
        {
            moveBeginPoint = self.center
            
            if isTraceEnabled!
            {
                self.addTraceButtonsDuringMoveToPoint(point: point, duration: duration!, delay: delay!, options: options!)
            }
            
            UIView.animate(withDuration: duration!, delay: delay!, options: options!) {
                self.resetCenter(center: point)
            } completion: { finish in
                if self.autoAddTraceButtonTimer != nil
                {
                    self.autoAddTraceButtonTimer?.invalidate()
                    self.autoAddTraceButtonTimer = nil
                }
                
                if self.isRecordingDraggingPathEnabled!
                {
                    self.draggingPath.addLine(to: self.center)
                }
                
                if completion != nil
                {
                    completion!()
                }
            }
        }
    }
}
