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
    
    func viewCorner(radius:CGFloat,borderWidth:CGFloat? = 0,borderColor:UIColor? = UIColor.clear)
    {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.layer.borderWidth = borderWidth!
        self.layer.borderColor = borderColor!.cgColor
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
    
    var x: CGFloat{
        get{
            frame.origin.x
        }
        set{
            frame.origin.x = newValue
        }
    }
    var y: CGFloat{
        get{
            frame.origin.y
        }
        set{
            frame.origin.y = newValue
        }
    }
    var width: CGFloat{
        get{
            frame.size.width
        }
        set{
            frame.size.width = newValue
        }
    }
    var height: CGFloat{
        get{
            frame.size.height
        }
        set{
            frame.size.height = newValue
        }
    }
    
    var viewCenter: CGPoint{
        get{
            CGPoint(x: width * 0.5, y: height * 0.5)
        }
    }
    
    var centerX: CGFloat{
        get{
            width * 0.5
        }
        set{
            center.x = newValue
        }
    }
    var setCenterY: CGFloat{
        get{
            height * 0.5
        }
        set{
            center.y = newValue
        }
    }
    
    var centerY: CGFloat{
        get{
            height * 0.5
        }
        set{
            center.y = newValue
        }
    }
    
    var inSuperViewCenterY: CGFloat{
        y + centerY
    }
    
    var maxX: CGFloat{
        get{
            x + width
        }
        set{
            x = newValue - width
        }
    }
    var maxY: CGFloat{
        get{
            y + height
        }
        set{
            y = newValue - height
        }
    }

}

extension UILabel
{
    func getLabelSize(width:CGFloat,height:CGFloat)->CGSize
    {
        return PTUtils.sizeFor(string: self.text!, font: self.font!, height: height, width: width)
    }
    
    func getLabelWidth(height:CGFloat)->CGFloat
    {
        return self.getLabelSize(width: CGFloat(MAXFLOAT), height: height).width
    }
    
    func getLabelHeight(width:CGFloat)->CGFloat
    {
        return self.getLabelSize(width: width, height: CGFloat(MAXFLOAT)).height
    }
}

extension UIButton
{
    func getButtonSize(width:CGFloat,height:CGFloat)->CGSize
    {
        return PTUtils.sizeFor(string: self.titleLabel!.text!, font: self.titleLabel!.font!, height: height, width: width)
    }
    
    func getButtonWidth(height:CGFloat)->CGFloat
    {
        return self.getButtonSize(width: CGFloat(MAXFLOAT), height: height).width
    }
    
    func getButtonHeight(width:CGFloat)->CGFloat
    {
        return self.getButtonSize(width: width, height: CGFloat(MAXFLOAT)).height
    }
}

extension UITextView
{
    func getTextViewSize(width:CGFloat,height:CGFloat)->CGSize
    {
        return PTUtils.sizeFor(string: self.text!, font: self.font!, height: height, width: width)
    }
    
    func getLabelWidth(height:CGFloat)->CGFloat
    {
        return self.getTextViewSize(width: CGFloat(MAXFLOAT), height: height).width
    }
    
    func getLabelHeight(width:CGFloat)->CGFloat
    {
        return self.getTextViewSize(width: width, height: CGFloat(MAXFLOAT)).height
    }
}
