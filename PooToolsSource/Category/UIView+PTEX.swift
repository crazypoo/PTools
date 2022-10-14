//
//  UIView+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/20.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

@objc public enum Imagegradien:Int
{
    case LeftToRight
    case TopToBottom
    case RightToLeft
    case BottomToTop
}

var GLOBAL_BORDER_TRACKERS: [BorderManager] = []

extension UIView: PTProtocolCompatible {}

public extension PTProtocol where Base:UIView
{
    var jx_x: CGFloat{
        get{
            base.frame.origin.x
        }
        set{
            base.frame.origin.x = newValue
        }
    }
    var jx_y: CGFloat{
        get{
            base.frame.origin.y
        }
        set{
            base.frame.origin.y = newValue
        }
    }
    var jx_width: CGFloat{
        get{
            base.frame.size.width
        }
        set{
            base.frame.size.width = newValue
        }
    }
    
    var jx_height: CGFloat{
        get{
            base.frame.size.height
        }
        set{
            base.frame.size.height = newValue
        }
    }
    
    var jx_viewCenter: CGPoint{
        get{
            CGPoint(x: jx_width * 0.5, y: jx_height * 0.5)
        }
    }
    
    var jx_centerX: CGFloat{
        get{
            jx_width * 0.5
        }
        set{
            base.center.x = newValue
        }
    }
    
    var jx_centerY: CGFloat{
        get{
            jx_height * 0.5
        }
        set{
            base.center.y = newValue
        }
    }
    
    var inSuperViewCenterY: CGFloat{
        jx_y + jx_centerY
    }
    
    var maxX: CGFloat{
        get{
            jx_x + jx_width
        }
        set{
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
    
    @objc func viewCorner_oc(radius:CGFloat,borderWidth:CGFloat,borderColor:UIColor)
    {
        self.viewCorner(radius: radius,borderWidth: borderWidth,borderColor:borderColor)
    }
    
    func viewCorner(radius:CGFloat,borderWidth:CGFloat? = 0,borderColor:UIColor? = UIColor.clear)
    {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.layer.borderWidth = borderWidth!
        self.layer.borderColor = borderColor!.cgColor
    }
    
    @objc func viewCornerRectCorner_oc(cornerRadii:CGFloat,corner:UIRectCorner)
    {
        self.viewCornerRectCorner(cornerRadii: cornerRadii, corner: corner)
    }
    
    func viewCornerRectCorner(cornerRadii:CGFloat? = 5,borderWidth:CGFloat? = 0,borderColor:UIColor? = UIColor.clear,corner:UIRectCorner? = .allCorners)
    {
        PTUtils.gcdMain {
            let maskPath = UIBezierPath.init(roundedRect: self.bounds, byRoundingCorners: corner!, cornerRadii: CGSize.init(width: cornerRadii!, height: cornerRadii!))
            let maskLayer = CAShapeLayer()
            maskLayer.frame = self.bounds
            maskLayer.path = maskPath.cgPath
            self.layer.mask = maskLayer
            self.layer.masksToBounds = true
            self.layer.borderWidth = borderWidth!
            self.layer.borderColor = borderColor!.cgColor
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
    func backgroundGradient(type:Imagegradien,colors:[UIColor],radius:CGFloat? = 0,borderWidth:CGFloat? = 0,borderColor:UIColor? = UIColor.clear)
    {
        PTUtils.gcdMain {
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
}

public extension UIView
{
    @objc func viewUI_shake()
    {
        let keyFrame = CAKeyframeAnimation(keyPath: "position.x")
        keyFrame.duration = 0.3
        let x = self.layer.position.x
        keyFrame.values = [(x - 30),(x - 30),(x + 20),(x - 20),(x + 10),(x - 10),(x + 5),(x - 5)]
        self.layer.add(keyFrame, forKey: "shake")
    }
    
    @objc func pt_createLabel(text: String = "", font: UIFont = .systemFont(ofSize: 15), bgColor: UIColor = .clear, textColor: UIColor = .black, textAlignment: NSTextAlignment = .left) -> UILabel {
        
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

public extension UILabel
{
    @objc func getLabelSize(width:CGFloat,height:CGFloat)->CGSize
    {
        return PTUtils.sizeFor(string: self.text!, font: self.font!, height: height, width: width)
    }
    
    @objc func getLabelWidth(height:CGFloat)->CGFloat
    {
        return self.getLabelSize(width: CGFloat(MAXFLOAT), height: height).width
    }
    
    @objc func getLabelHeight(width:CGFloat)->CGFloat
    {
        return self.getLabelSize(width: width, height: CGFloat(MAXFLOAT)).height
    }
}

public extension UIButton
{
    @objc func getButtonSize(width:CGFloat,height:CGFloat)->CGSize
    {
        return PTUtils.sizeFor(string: self.titleLabel!.text!, font: self.titleLabel!.font!, height: height, width: width)
    }
    
    @objc func getButtonWidth(height:CGFloat)->CGFloat
    {
        return self.getButtonSize(width: CGFloat(MAXFLOAT), height: height).width
    }
    
    @objc func getButtonHeight(width:CGFloat)->CGFloat
    {
        return self.getButtonSize(width: width, height: CGFloat(MAXFLOAT)).height
    }
}

public extension UITextView
{
    @objc func getTextViewSize(width:CGFloat,height:CGFloat)->CGSize
    {
        return PTUtils.sizeFor(string: self.text!, font: self.font!, height: height, width: width)
    }
    
    @objc func getLabelWidth(height:CGFloat)->CGFloat
    {
        return self.getTextViewSize(width: CGFloat(MAXFLOAT), height: height).width
    }
    
    @objc func getLabelHeight(width:CGFloat)->CGFloat
    {
        return self.getTextViewSize(width: width, height: CGFloat(MAXFLOAT)).height
    }
}
