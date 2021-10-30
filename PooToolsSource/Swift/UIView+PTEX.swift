//
//  UIView+PTEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/20.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

var GLOBAL_BORDER_TRACKERS: [BorderManager] = []

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
    
    func viewCornerRectCorner(cornerRadii:CGFloat? = 5,corner:UIRectCorner? = .allCorners)
    {
        let maskPath = UIBezierPath.init(roundedRect: self.bounds, byRoundingCorners: corner!, cornerRadii: CGSize.init(width: cornerRadii!, height: cornerRadii!))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
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
    
    @objc var x: CGFloat{
        get{
            frame.origin.x
        }
        set{
            frame.origin.x = newValue
        }
    }
    @objc var y: CGFloat{
        get{
            frame.origin.y
        }
        set{
            frame.origin.y = newValue
        }
    }
    @objc var width: CGFloat{
        get{
            frame.size.width
        }
        set{
            frame.size.width = newValue
        }
    }
    
    @objc var height: CGFloat{
        get{
            frame.size.height
        }
        set{
            frame.size.height = newValue
        }
    }
    
    @objc var viewCenter: CGPoint{
        get{
            CGPoint(x: width * 0.5, y: height * 0.5)
        }
    }
    
    @objc var centerX: CGFloat{
        get{
            width * 0.5
        }
        set{
            center.x = newValue
        }
    }
    
    @objc var centerY: CGFloat{
        get{
            height * 0.5
        }
        set{
            center.y = newValue
        }
    }
    
    @objc var inSuperViewCenterY: CGFloat{
        y + centerY
    }
    
    @objc var maxX: CGFloat{
        get{
            x + width
        }
        set{
            x = newValue - width
        }
    }
    @objc var maxY: CGFloat{
        get{
            y + height
        }
        set{
            y = newValue - height
        }
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
