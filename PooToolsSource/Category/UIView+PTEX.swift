//
//  UIView+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/20.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SnapKit

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
                
    private struct AssociatedKeys {
        static var layoutSubviewsCallback = 998
        static var layoutShapeLayerCallback = 996
        static var layoutShapeLayerProgressLabelCallback = 995
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

    func layerProgress(value:CGFloat,
                       borderWidth:CGFloat? = 1,
                       borderColor:UIColor? = .systemRed,
                       showValueLabel:Bool? = true,
                       valueLabelFont:UIFont? = .appfont(size: 16,bold: true),
                       valueLabelColor:UIColor? = .white,
                       uniCount:Int? = 0) {
        if self.viewShapeLayer != nil {
            updateLayerProgress(progress: value)
        } else {
            // 创建一个矩形的路径
            let path = UIBezierPath(rect: .zero)
            
            // 设置CAShapeLayer属性
            viewShapeLayer = CAShapeLayer()
            viewShapeLayer!.path = path.cgPath
            viewShapeLayer!.fillColor = UIColor.clear.cgColor
            viewShapeLayer!.strokeColor = borderColor!.cgColor
            viewShapeLayer!.lineWidth = borderWidth!
            viewShapeLayer!.lineCap = .round
            
            // 添加CAShapeLayer到视图的layer中
            layer.addSublayer(viewShapeLayer!)
            
            if showValueLabel! {
                viewShapeLayerProgressLabel = UILabel()
                viewShapeLayerProgressLabel?.font = valueLabelFont!
                viewShapeLayerProgressLabel?.textColor = valueLabelColor!
                viewShapeLayerProgressLabel?.textAlignment = .center
                addSubview(viewShapeLayerProgressLabel!)
                viewShapeLayerProgressLabel?.snp.makeConstraints({ make in
                    make.edges.equalToSuperview()
                })
            }
            
            updateLayerProgress(progress: value)
        }
    }
    
    func updateLayerProgress(progress:CGFloat,
                             uniCount:Int? = 0) {
        if viewShapeLayer != nil {
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
                viewShapeLayer!.path = progressPath.cgPath
            
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
        layer.cornerRadius = radius
        layer.masksToBounds = true
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
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
        tracker.activate()
    }
    
    //MARK: View的背景渐变
    ///View的背景渐变
    func backgroundGradient(type:Imagegradien,
                            colors:[UIColor],
                            radius:CGFloat? = 0,
                            borderWidth:CGFloat? = 0,
                            borderColor:UIColor? = UIColor.clear) {
        PTGCDManager.gcdMain {
            self.backgroundColor = .clear
            let maskLayer = CAGradientLayer()
            
            var cgColorsss = [CGColor]()
            colors.enumerated().forEach { (index,value) in
                cgColorsss.append(value.cgColor)
            }
            
            maskLayer.colors = cgColorsss
            switch type {
            case .LeftToRight:
                maskLayer.startPoint = CGPoint.init(x: 0, y: 0)
                maskLayer.endPoint = CGPoint.init(x: 1, y: 0)
            case .TopToBottom:
                maskLayer.startPoint = CGPoint.init(x: 0, y: 0)
                maskLayer.endPoint = CGPoint.init(x: 0, y: 1)
            case .RightToLeft:
                maskLayer.startPoint = CGPoint.init(x: 1, y: 0)
                maskLayer.endPoint = CGPoint.init(x: 0, y: 0)
            case .BottomToTop:
                maskLayer.startPoint = CGPoint.init(x: 0, y: 1)
                maskLayer.endPoint = CGPoint.init(x: 0, y: 0)
            }
            maskLayer.frame = self.bounds
            maskLayer.cornerRadius = radius!
            maskLayer.masksToBounds = true
            maskLayer.borderWidth = borderWidth!
            maskLayer.borderColor = borderColor!.cgColor
            self.layer.addSublayer(maskLayer)
            self.layer.insertSublayer(maskLayer, at: 0)
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
                             lineSpacing:NSNumber? = nil,
                             height:CGFloat = CGFloat.greatestFiniteMagnitude,
                             width:CGFloat = CGFloat.greatestFiniteMagnitude)->CGSize {
        var dic = [NSAttributedString.Key.font:font] as! [NSAttributedString.Key:Any]
        if lineSpacing != nil {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = CGFloat(lineSpacing!.floatValue)
            dic[NSAttributedString.Key.paragraphStyle] = paraStyle
        }
        let size = string.boundingRect(with: CGSize.init(width: width, height: height), options: [.usesLineFragmentOrigin], attributes: dic, context: nil).size
        return size
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
