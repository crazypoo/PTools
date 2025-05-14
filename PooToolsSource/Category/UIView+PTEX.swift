//
//  UIView+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/20.
//  Copyright © 2021 DO. All rights reserved.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit
import SnapKit
import WebKit

@objc public enum Imagegradien:Int {
    case LeftToRight
    case TopToBottom
    case RightToLeft
    case BottomToTop
}

var GLOBAL_BORDER_TRACKERS: [BorderManager] = []

extension UIView: PTProtocolCompatible {}

public extension PTPOP where Base:UIView {
    var jx_x: CGFloat{
        get {
            base.frame.origin.x
        } set {
            base.frame.origin.x = newValue
        }
    }
    var jx_y: CGFloat{
        get {
            base.frame.origin.y
        } set {
            base.frame.origin.y = newValue
        }
    }
    var jx_width: CGFloat{
        get {
            base.frame.size.width
        } set {
            base.frame.size.width = newValue
        }
    }
    
    var jx_height: CGFloat{
        get {
            base.frame.size.height
        } set {
            base.frame.size.height = newValue
        }
    }
    
    var jx_viewCenter: CGPoint{
        get {
            CGPoint(x: jx_width * 0.5, y: jx_height * 0.5)
        }
    }
    
    var jx_centerX: CGFloat{
        get {
            jx_width * 0.5
        } set{
            base.center.x = newValue
        }
    }
    
    var jx_centerY: CGFloat{
        get {
            jx_height * 0.5
        } set{
            base.center.y = newValue
        }
    }
    
    var inSuperViewCenterY: CGFloat{
        jx_y + jx_centerY
    }
    
    var maxX: CGFloat{
        get {
            jx_x + jx_width
        } set{
            jx_x = newValue - jx_width
        }
    }
    var maxY: CGFloat{
        get{
            jx_y + jx_height
        }
        set{
            jx_y = newValue - jx_height
        }
    }
}

public typealias LayoutSubviewsCallback = (_ view:UIView) -> Void

public extension UIView {
              
    static func isRTL() -> Bool {
        UIView.userInterfaceLayoutDirection(for: UIView.appearance().semanticContentAttribute) == .rightToLeft
    }
    
    private struct AssociatedKeys {
        static var layoutSubviewsCallback = 998
        static var layoutShapeLayerCallback = 996
        static var layoutShapeLayerProgressLabelCallback = 995
        static var viewCapturing = 997
    }

    private var viewShapeLayer:CAShapeLayer? {
        set{
            objc_setAssociatedObject(self, &AssociatedKeys.layoutShapeLayerCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.layoutShapeLayerCallback)
            guard let haveShape = obj as? CAShapeLayer else {
                return nil
            }
            return haveShape
        }
    }
    
    private var viewShapeLayerProgressLabel:UILabel? {
        set{
            objc_setAssociatedObject(self, &AssociatedKeys.layoutShapeLayerProgressLabelCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.layoutShapeLayerProgressLabelCallback)
            guard let progressLabel = obj as? UILabel else {
                return nil
            }
            return progressLabel
        }
    }
    
    func layerProgress(value: CGFloat,
                       borderWidth: CGFloat = 1,
                       borderColor: UIColor = .systemRed,
                       showValueLabel: Bool = true,
                       valueLabelFont: UIFont = .systemFont(ofSize: 16, weight: .bold),
                       valueLabelColor: UIColor = .white,
                       uniCount: Int = 0) {
        if viewShapeLayer == nil {
            setupLayer(borderWidth: borderWidth, borderColor: borderColor)
            
            if showValueLabel {
                setupLabel(font: valueLabelFont, textColor: valueLabelColor)
            }
        }
        
        updateLayerProgress(progress: value, uniCount: uniCount)
    }

    private func setupLayer(borderWidth: CGFloat, borderColor: UIColor) {
        viewShapeLayer = CAShapeLayer()
        viewShapeLayer?.fillColor = UIColor.clear.cgColor
        viewShapeLayer?.strokeColor = borderColor.cgColor
        viewShapeLayer?.lineWidth = borderWidth
        viewShapeLayer?.lineCap = .round
        layer.addSublayer(viewShapeLayer!)
    }

    private func setupLabel(font: UIFont, textColor: UIColor) {
        let label = UILabel()
        label.font = font
        label.textColor = textColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        viewShapeLayerProgressLabel = label
    }
    
    func updateLayerProgress(progress:CGFloat,
                             uniCount:Int? = 0) {
        if let viewShapeLayer = viewShapeLayer {
            let widthAndHeightTotal = (bounds.height + bounds.width)
            if progress >= 1 {
                clearProgressLayer()
            } else {
                let progressPath = UIBezierPath(rect: .zero)

                if progress <= 0.5 {
                    let progressScale = progress / 0.5
                    let currentValue = widthAndHeightTotal * progressScale
                    if currentValue > bounds.width {
                        progressPath.move(to: CGPoint(x: bounds.width, y: 0))
                        progressPath.addLine(to: CGPoint(x: 0, y: 0))
                        
                        let heightValue = currentValue - bounds.width

                        progressPath.move(to: CGPoint(x: bounds.width, y:  heightValue))
                        progressPath.addLine(to: CGPoint(x: bounds.width, y: 0))
                    } else {
                        progressPath.move(to: CGPoint(x: currentValue, y: 0))
                        progressPath.addLine(to: CGPoint(x: 0, y: 0))
                    }
                } else {
                    let newProgress = (progress - 0.5)
                    
                    let progressScale = newProgress / 0.5

                    let currentValue = widthAndHeightTotal * progressScale
                    if currentValue > bounds.width {
                        
                        progressPath.move(to: CGPoint(x: bounds.width, y: 0))
                        progressPath.addLine(to: CGPoint(x: 0, y: 0))
                        
                        progressPath.move(to: CGPoint(x: bounds.width, y:  bounds.height))
                        progressPath.addLine(to: CGPoint(x: bounds.width, y: 0))

                        progressPath.move(to: CGPoint(x: bounds.width, y: 0))
                        progressPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
                        
                        progressPath.move(to: CGPoint(x: bounds.width, y: bounds.height))
                        progressPath.addLine(to: CGPoint(x: 0, y: bounds.height))

                        let heightValue = bounds.height - (currentValue - bounds.width)

                        progressPath.move(to: CGPoint(x: 0, y:  heightValue))
                        progressPath.addLine(to: CGPoint(x: 0, y: bounds.height))
                    } else {
                        progressPath.move(to: CGPoint(x: bounds.width, y: 0))
                        progressPath.addLine(to: CGPoint(x: 0, y: 0))
                        
                        progressPath.move(to: CGPoint(x: bounds.width, y:  bounds.height))
                        progressPath.addLine(to: CGPoint(x: bounds.width, y: 0))

                        progressPath.move(to: CGPoint(x: bounds.width, y: 0))
                        progressPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
                                        
                        let widthValue = bounds.width - currentValue

                        progressPath.move(to: CGPoint(x: widthValue, y: bounds.height))
                        progressPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
                    }
                }
                viewShapeLayer.path = progressPath.cgPath
            
                viewShapeLayerProgressLabel?.text = String(format: "%.\(uniCount!)f%%", (100 * progress))
            }
        }
    }
    
    func clearProgressLayer() {
        if viewShapeLayer != nil {
            viewShapeLayer!.removeFromSuperlayer()
            viewShapeLayer = nil
        }
        
        if viewShapeLayerProgressLabel != nil {
            viewShapeLayerProgressLabel?.removeFromSuperview()
            viewShapeLayerProgressLabel = nil
        }
    }
    
    @objc func viewCorner(radius:CGFloat = 0,
                          borderWidth:CGFloat = 0,
                          borderColor:UIColor = UIColor.clear) {
        PTGCDManager.gcdMain {
            self.layer.cornerRadius = radius
            self.layer.masksToBounds = true
            self.layer.borderWidth = borderWidth
            self.layer.borderColor = borderColor.cgColor
        }
    }
        
    @objc func viewCornerRectCorner(cornerRadii:CGFloat = 5,
                                    borderWidth:CGFloat = 0,
                                    borderColor:UIColor = UIColor.clear,
                                    corner:UIRectCorner = .allCorners) {
        PTGCDManager.gcdMain {
            let maskPath = UIBezierPath.init(roundedRect: self.bounds, byRoundingCorners: corner, cornerRadii: CGSize.init(width: cornerRadii, height: cornerRadii))
            let maskLayer = CAShapeLayer()
            maskLayer.frame = self.bounds
            maskLayer.path = maskPath.cgPath
            self.layer.mask = maskLayer
            self.layer.masksToBounds = true
            self.layer.borderWidth = borderWidth
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    /// Swizzle UIView to use custom frame system when needed.
    static func swizzleDebugBehaviour_UNTRACKABLE_TOGGLE() {
        guard let originalMethod = class_getInstanceMethod(UIView.self, #selector(layoutSubviews)),
              let swizzledMethod = class_getInstanceMethod(UIView.self, #selector(swizzled_layoutSubviews)) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc func swizzled_layoutSubviews() {
        swizzled_layoutSubviews()
        
        let tracker = BorderManager(view: self)
        GLOBAL_BORDER_TRACKERS.append(tracker)
#if POOTOOLS_DEBUG
        if LocalConsole.shared.debugBordersEnabled {
            tracker.activate()
        } else {
            tracker.deactivate()
        }
#else
        tracker.deactivate()
#endif
    }
    
    //MARK: View的背景渐变
    ///View的背景渐变
    func backgroundGradient(type:Imagegradien,
                            colors:[UIColor],
                            radius:CGFloat? = 0,
                            borderWidth:CGFloat? = 0,
                            borderColor:UIColor? = UIColor.clear,
                            corner:UIRectCorner = .allCorners) {
        PTGCDManager.gcdMain {
            // 检查并移除已经存在的渐变背景层，防止重复添加
            if let existingGradientView = self.viewWithTag(999) {
                existingGradientView.removeFromSuperview()
            }

            // 创建背景视图
            let gradientBackgroundView = UIView(frame: self.bounds)
            gradientBackgroundView.tag = 999 // 用 tag 标记，便于后续移除
            gradientBackgroundView.backgroundColor = .clear
            gradientBackgroundView.isUserInteractionEnabled = false // 确保不干扰用户操作

            let maskPath = UIBezierPath(roundedRect: gradientBackgroundView.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: radius!, height: radius!))
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = maskPath.cgPath

            let maskLayer = CAGradientLayer()
            var cgColors = [CGColor]()
            colors.forEach { value in
                cgColors.append(value.cgColor)
            }

            maskLayer.colors = cgColors
            switch type {
            case .LeftToRight:
                maskLayer.startPoint = CGPoint(x: 0, y: 0)
                maskLayer.endPoint = CGPoint(x: 1, y: 0)
            case .TopToBottom:
                maskLayer.startPoint = CGPoint(x: 0, y: 0)
                maskLayer.endPoint = CGPoint(x: 0, y: 1)
            case .RightToLeft:
                maskLayer.startPoint = CGPoint(x: 1, y: 0)
                maskLayer.endPoint = CGPoint(x: 0, y: 0)
            case .BottomToTop:
                maskLayer.startPoint = CGPoint(x: 0, y: 1)
                maskLayer.endPoint = CGPoint(x: 0, y: 0)
            }
            maskLayer.frame = gradientBackgroundView.bounds
            maskLayer.mask = shapeLayer
            maskLayer.masksToBounds = true
            maskLayer.borderWidth = borderWidth!
            maskLayer.borderColor = borderColor!.cgColor

            gradientBackgroundView.layer.insertSublayer(maskLayer, at: 0)
            gradientBackgroundView.layer.masksToBounds = true

            // 将 gradientBackgroundView 添加到 UILabel 背后
            self.insertSubview(gradientBackgroundView, at: 0)

            self.backgroundColor = .clear // 确保 UILabel 背景透明
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    //MARK: border的背景渐变
    ///border的背景渐变
    func borderGradient(type:Imagegradien,
                        colors:[UIColor],
                        radius:CGFloat? = 0,
                        borderWidth:CGFloat = 1,
                        corner:UIRectCorner = .allCorners) {
        PTGCDManager.gcdMain {
            var cgColorsss = [CGColor]()
            colors.enumerated().forEach { (index,value) in
                cgColorsss.append(value.cgColor)
            }

            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = self.bounds
            gradientLayer.colors = cgColorsss
            switch type {
            case .LeftToRight:
                gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                gradientLayer.endPoint = CGPoint(x: 1, y: 0)
            case .TopToBottom:
                gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                gradientLayer.endPoint = CGPoint(x: 0, y: 1)
            case .RightToLeft:
                gradientLayer.startPoint = CGPoint(x: 1, y: 0)
                gradientLayer.endPoint = CGPoint(x: 0, y: 0)
            case .BottomToTop:
                gradientLayer.startPoint = CGPoint(x: 0, y: 1)
                gradientLayer.endPoint = CGPoint(x: 0, y: 0)
            }
            
            let borderShapeLayer = CAShapeLayer()
            let borderPath = UIBezierPath.init(roundedRect: self.bounds, byRoundingCorners: corner, cornerRadii: CGSize.init(width: radius!, height: radius!))
            borderShapeLayer.path = borderPath.cgPath
            borderShapeLayer.fillColor = UIColor.clear.cgColor
            borderShapeLayer.strokeColor = UIColor.black.cgColor
            borderShapeLayer.lineWidth = borderWidth
            gradientLayer.mask = borderShapeLayer

            self.layer.insertSublayer(gradientLayer, at: 0)

            let bgGradientLayer = CAGradientLayer()
            bgGradientLayer.colors = [self.backgroundColor?.cgColor ?? UIColor.clear.cgColor]
            bgGradientLayer.startPoint = CGPoint(x: 0, y: 0)
            bgGradientLayer.endPoint = CGPoint(x: 1, y: 0)
            bgGradientLayer.frame = self.bounds
            
            let bgShapeLayer = CAShapeLayer()
            bgShapeLayer.path = borderPath.cgPath
            bgGradientLayer.mask = bgShapeLayer
            self.layer.insertSublayer(bgGradientLayer, at: 0)

            self.setNeedsDisplay()
        }
    }
    
    func isRolling()->Bool {
        if self is UIScrollView {
            let scrollView = self as! UIScrollView
            if scrollView.isDragging || scrollView.isDecelerating {
                return true
            }
        }
        
        for subView in subviews {
            if subView.isRolling() {
                return true
            }
        }
        return false
    }
    
    func roundOriginToPixel() {
        frame.origin.x = (round(frame.origin.x * UIScreen.main.scale)) / UIScreen.main.scale
        frame.origin.y = (round(frame.origin.y * UIScreen.main.scale)) / UIScreen.main.scale
    }
    
    @objc class func sizeFor(string:String,
                             font:UIFont,
                             lineSpacing:CGFloat = 2.5,
                             height:CGFloat = CGFloat.greatestFiniteMagnitude,
                             width:CGFloat = CGFloat.greatestFiniteMagnitude)->CGSize {
        var dic = [NSAttributedString.Key.font:font] as! [NSAttributedString.Key:Any]
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = lineSpacing
        dic[NSAttributedString.Key.paragraphStyle] = paraStyle
        if !string.stringIsEmpty() {
            let size = string.boundingRect(with: CGSize.init(width: width, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: dic, context: nil).size
            return size
        }
        return .zero
    }
    
    var viewController: UIViewController? {
        weak var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    var hasSuperview: Bool { superview != nil }

    func allSubViewsOf<T : UIView>(type : T.Type) -> [T] {
        var all = [T]()
        func getSubview(view: UIView) {
            if let aView = view as? T{
                all.append(aView)
            }
            guard view.subviews.count>0 else { return }
            view.subviews.forEach{ getSubview(view: $0) }
        }
        getSubview(view: self)
        return all
    }

    var screenshot: UIImage? {
        /*UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, 0)
         defer {
         UIGraphicsEndImageContext()
         }
         guard let context = UIGraphicsGetCurrentContext() else { return nil }
         layer.render(in: context)
         return UIGraphicsGetImageFromCurrentImageContext()*/
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }

    func addShadow(ofColor color: UIColor, radius: CGFloat, offset: CGSize, opacity: Float) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }
    
    func addParalax(amount: CGFloat) {
        motionEffects.removeAll()
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        self.addMotionEffect(group)
    }
    
    func removeParalax() {
        motionEffects.removeAll()
    }
    
    /**
        If view has LTR interface.
     */
    var ltr: Bool { effectiveUserInterfaceLayoutDirection == .leftToRight }
    
    /**
        If view has TRL interface.
     */
    var rtl: Bool { effectiveUserInterfaceLayoutDirection == .rightToLeft }
    
    /**
         Wrapper for layer property `masksToBounds`.
     */
    var masksToBounds: Bool {
        get {
            layer.masksToBounds
        }
        set {
            layer.masksToBounds = newValue
        }
    }
    
    /**
        Round corners .
     
     - parameter corners: Case of `CACornerMask`. Which corners need to round.
     - parameter curve: Case of `CornerCurve`. Style of rounded corners.
     - parameter radius: Amount of radius.
     */
    func roundCorners(_ corners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner], curve: CornerCurve = .continuous, radius: CGFloat) {
        layer.cornerRadius = radius
        layer.maskedCorners = corners
        layer.cornerCurve = curve.layerCornerCurve
    }
    
    /**
        Round side by minimum `height` or `width`.
     */
    func roundMinimumSide() {
        roundCorners(radius: min(frame.width / 2, frame.height / 2))
    }
    
    /**
        Wrapper for layer property `customBorderColor`.
     */
    var customBorderColor: UIColor? {
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            guard let color = newValue else {
                layer.borderColor = nil
                return
            }
            // Fix React-Native conflict issue
            guard String(describing: type(of: color)) != "__NSCFType" else { return }
            layer.borderColor = color.cgColor
        }
    }
    
    /**
        Wrapper for layer property `customBorderWidth`.
     */
    var customBorderWidth: CGFloat {
        get {
            layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    /**
        Appear view with fade in animation.
     
     - parameter duration: Duration of animation.
     - parameter completion: Completion when animation ended.
     */
    func fadeIn(duration: TimeInterval = 0.3, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: .zero, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.alpha = 1
        }, completion: completion)
    }
    
    /**
        Hide view with fade out animation.
     
     - parameter duration: Duration of animation.
     - parameter completion: Completion when animation ended.
     */
    func fadeOut(duration: TimeInterval = 0.3, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: .zero, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.alpha = 0
        }, completion: completion)
    }
        
    enum CornerCurve {
        
        case circle
        case continuous
        
        var layerCornerCurve: CALayerCornerCurve {
            switch self {
            case .circle: return .circular
            case .continuous: return .continuous
            }
        }
    }
    
    ///查找当前View的XViewController
    func findController<T:UIViewController>(with class :T.Type) -> T? {
        var responder = next
        while responder != nil {
            if responder!.isKind(of: `class`) {
                return responder as? T
            }
            responder = responder?.next
        }
        return nil
    }
    
    var ctrl: UIViewController? {
        return self.findController(with: UIViewController.self)
    }
    
    var naviCtrl: UINavigationController? {
        return self.findController(with: UINavigationController.self)
    }
    
    var tabBarCtrl: UITabBarController? {
        return self.findController(with: UITabBarController.self)
    }
}

public extension UIView {

    @objc func jx_layoutSubviews() {
        jx_layoutSubviews()
        layoutSubviewsCallback?(self)
    }

    var layoutSubviewsCallback: ((UIView) -> Void)? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.layoutSubviewsCallback) as? (UIView) -> Void
        } set {
            objc_setAssociatedObject(self, &AssociatedKeys.layoutSubviewsCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    static func swizzle() {
        let originalSelector = #selector(layoutSubviews)
        let swizzledSelector = #selector(jx_layoutSubviews)

        guard let originalMethod = class_getInstanceMethod(self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        else {
            return
        }

        let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))

        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

public extension UIView {
    @objc func viewUI_shake() {
        let keyFrame = CAKeyframeAnimation(keyPath: "position.x")
        keyFrame.duration = 0.3
        let x = layer.position.x
        keyFrame.values = [(x - 30),(x - 30),(x + 20),(x - 20),(x + 10),(x - 10),(x + 5),(x - 5)]
        layer.add(keyFrame, forKey: "shake")
    }
    
    @objc func pt_createLabel(text: String = "",
                              font: UIFont = .systemFont(ofSize: 15),
                              bgColor: UIColor = .clear,
                              textColor: UIColor = .black,
                              textAlignment: NSTextAlignment = .left) -> UILabel {
        
        let label = UILabel()
        label.backgroundColor = bgColor
        label.textColor = textColor
        label.text = text
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.sizeToFit()
        label.font = font
        label.textAlignment = textAlignment
        return label
    }
}

//MARK: 視頻剪輯
public extension UIView {
    var imageWithView: UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
        return renderer.image { rendererContext in
            self.layer.render(in: rendererContext.cgContext)
        }
    }
    
    func edgesConstraint(subView: UIView, constant: CGFloat = 0) {
        self.leadingConstraint(subView: subView, constant: constant)
        self.trailingConstraint(subView: subView, constant: constant)
        self.topConstraint(subView: subView, constant: constant)
        self.bottomConstraint(subView: subView, constant: constant)
    }
    
    func sizeConstraint(subView: UIView, constant: CGFloat = 0) {
        self.widthConstraint(subView: subView, constant: constant)
        self.heightConstraint(subView: subView, constant: constant)
    }
    
    func sizeConstraint(constant: CGFloat = 0) {
        self.widthConstraint(constant: constant)
        self.heightConstraint(constant: constant)
    }
    
    @discardableResult
    func leadingConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: relatedBy, toItem: subView, attribute: .leading, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func trailingConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: relatedBy, toItem: subView, attribute: .trailing, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func topConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: relatedBy, toItem: subView, attribute: .top, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func bottomConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: relatedBy, toItem: subView, attribute: .bottom, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func centerXConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: relatedBy, toItem: subView, attribute: .centerX, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func centerYConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: relatedBy, toItem: subView, attribute: .centerY, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func leadingConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .leading, relatedBy: relatedBy, toItem: subView, attribute: .leading, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func trailingConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .trailing, relatedBy: relatedBy, toItem: subView, attribute: .trailing, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func topConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .top, relatedBy: relatedBy, toItem: subView, attribute: .top, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func bottomConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .bottom, relatedBy: relatedBy, toItem: subView, attribute: .bottom, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func centerXConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .centerX, relatedBy: relatedBy, toItem: subView, attribute: .centerX, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func centerYConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .centerY, relatedBy: relatedBy, toItem: subView, attribute: .centerY, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func widthConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .width, relatedBy: relatedBy, toItem: subView, attribute: .width, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func heightConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: item, attribute: .height, relatedBy: relatedBy, toItem: subView, attribute: .height, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func widthConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: relatedBy, toItem: subView, attribute: .width, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func heightConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: relatedBy, toItem: subView, attribute: .height, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func widthConstraint(constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: relatedBy, toItem: nil, attribute: .width, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult
    func heightConstraint(constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: relatedBy, toItem: nil, attribute: .height, multiplier: multiplier, constant: constant)
        self.addConstraint(constraint)
        return constraint
    }
}

// MARK: - 截图-对当前视图进行快照
public extension UIView {
    
    /** 是否正在截屏*/
    var isCapturing: Bool {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.viewCapturing) else {
                return false
            }
            guard let boolValue = value as? Bool else {
                return false
            }
            return boolValue
        }
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewCapturing, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /**  是否包含了WKWebView*/
    func isContainWKWebView() -> Bool {
        if self.isKind(of: WKWebView.self) {
            return true
        } else {
            for view in self.subviews {
                return view.isContainWKWebView()
            }
        }
        return false
    }
    
    /** 快照回调*/
    typealias captureCompletion = (UIImage?) -> Void
    
    /// 对视图进行快照
    ///
    /// - Parameter completion: 回调
    func captureCurrent(_ completion: captureCompletion) {
        self.isCapturing = true
        let captureFrame = self.bounds
        
        UIGraphicsBeginImageContextWithOptions(captureFrame.size, true, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.translateBy(x: -self.pt.jx_x, y: -self.pt.jx_y)
        
        if self.isContainWKWebView() {
            self.drawHierarchy(in: bounds, afterScreenUpdates: true)
        } else {
            self.layer.render(in: context!)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        context?.restoreGState()
        UIGraphicsEndImageContext()
        self.isCapturing = false
        completion(image)
    }
}

// MARK: - 截图
public extension UIView {
    
    /// 生成视图的截图 - bounds
    ///
    /// - Parameters:
    ///   - opaque: alpha通道 true:不透明 / false透明
    ///   - scale: 缩放清晰度
    /// - Returns: 截图
    func generateBoundsScreenshot(_ opaque: Bool = false, scale: CGFloat = 0) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, opaque, scale)
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    /// 生成视图的截图 - frame
    ///
    /// - Returns: 截图
    func generateFrameScreenshot() -> UIImage {
        let imageSize = self.frame.size
        var orientation:UIInterfaceOrientation!
        if let orientations = AppWindows?.windowScene?.interfaceOrientation {
            orientation = orientations
        } else {
            orientation = UIInterfaceOrientation(rawValue: UIDevice.current.orientation.rawValue)
        }
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.concatenate(transform)
            context.translateBy(x: -bounds.size.width * layer.anchorPoint.x, y: -bounds.size.height * layer.anchorPoint.y)
            if orientation == .landscapeLeft {
                context.rotate(by: .pi / 2)
                context.translateBy(x: 0, y: -imageSize.width)
            } else if orientation == .landscapeRight {
                context.rotate(by: -.pi / 2)
                context.translateBy(x: -imageSize.height, y: 0)
            } else if orientation == .portraitUpsideDown {
                context.rotate(by: .pi)
                context.translateBy(x: -imageSize.width, y: -imageSize.height)
            }
            if self.responds(to: #selector(drawHierarchy(in:afterScreenUpdates:))) {
                self.drawHierarchy(in: bounds, afterScreenUpdates: true)
            } else {
                layer.render(in: context)
            }
            context.restoreGState()
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
}

public extension UILabel {
    @objc func getLabelSize(width:CGFloat = CGFloat.greatestFiniteMagnitude,
                            height:CGFloat = CGFloat.greatestFiniteMagnitude)->CGSize {
        UIView.sizeFor(string: text!, font: font!, height: height, width: width)
    }
    
    @objc func getLabelWidth(height:CGFloat)->CGFloat {
        getLabelSize(height: height).width
    }
    
    @objc func getLabelHeight(width:CGFloat)->CGFloat {
        getLabelSize(width: width).height
    }
}

public extension UIButton {
    @objc func getButtonSize(width:CGFloat = CGFloat.greatestFiniteMagnitude,
                             height:CGFloat = CGFloat.greatestFiniteMagnitude)->CGSize {
        UIView.sizeFor(string: titleLabel!.text!, font: titleLabel!.font!, height: height, width: width)
    }
    
    @objc func getButtonWidth(height:CGFloat)->CGFloat {
        getButtonSize(height: height).width
    }
    
    @objc func getButtonHeight(width:CGFloat)->CGFloat {
        getButtonSize(width: width).height
    }
}

public extension UITextView {
    @objc func getTextViewSize(width:CGFloat = CGFloat.greatestFiniteMagnitude,
                               height:CGFloat = CGFloat.greatestFiniteMagnitude)->CGSize {
        UIView.sizeFor(string: text!, font: font!, height: height, width: width)
    }
    
    @objc func getLabelWidth(height:CGFloat)->CGFloat {
        getTextViewSize(height: height).width
    }
    
    @objc func getLabelHeight(width:CGFloat)->CGFloat {
        getTextViewSize(width: width).height
    }
}

public protocol UIFadeOut {}

extension UIFadeOut where Self: UIView {
    
    /**
        Hide view with fade out animation.
     
     - parameter duration: Duration of all animation.
     - parameter delay: Pause when view dissapear in middle of animation.
     - parameter work: Apply view changes here.
     - parameter completion: Call after end of animation.
     */
    public func fadeUpdate(duration: TimeInterval = 1, delay: TimeInterval = 0.15, work: @escaping (Self)->Void, completion: (()->Void)? = nil) {
        let partDuration = (duration - delay) / 2
        let storedAlpha = self.alpha
        UIView.animate(withDuration: partDuration, delay: .zero, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] in
            self?.alpha = .zero
        }, completion: { [weak self] finished in
            if let self = self {
                work(self)
            }
            UIView.animate(withDuration: partDuration, delay: delay, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] in
                self?.alpha = storedAlpha
            }, completion: { finished in
                completion?()
            })
        })
    }
}

extension UIView: UIFadeOut {}
#endif
