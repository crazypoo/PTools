//
//  UIView+XMExt.swift
//  XianDuoDuo
//
//  Created by 王锦发 on 2019/8/8.
//  Copyright © 2019 Kim. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    var x: CGFloat{
        get{
            return frame.origin.x
        }
        set{
            frame.origin.x = newValue
        }
    }
    var y: CGFloat{
        get{
            return frame.origin.y
        }
        set{
            frame.origin.y = newValue
        }
    }
    var width: CGFloat{
        get{
            return frame.size.width
        }
        set{
            frame.size.width = newValue
        }
    }
    var height: CGFloat{
        get{
            return frame.size.height
        }
        set{
            frame.size.height = newValue
        }
    }
    
    var viewCenter: CGPoint{
        get{
            return CGPoint(x: width * 0.5, y: height * 0.5)
        }
    }
    
    var centerX: CGFloat{
        get{
            return width * 0.5
        }
        set{
            center.x = newValue
        }
    }
    var setCenterY: CGFloat{
        get{
            return height * 0.5
        }
        set{
            center.y = newValue
        }
    }
    
    var centerY: CGFloat{
        get{
            return height * 0.5
        }
        set{
            center.y = newValue
        }
    }
    
    var inSuperViewCenterY: CGFloat{
        return y + centerY
    }
    
    var maxX: CGFloat{
        get{
            return self.x + self.width
        }
        set{
            x = newValue - self.width
        }
    }
    var maxY: CGFloat{
        get{
            return self.y + self.height
        }
        set{
            y = newValue - self.height
        }
    }
    
}

extension UIView {
    
    /// 寻找当前视图所在的控制器
    var responderController: UIViewController? {
        var nextReponder: UIResponder? = self.next
        while nextReponder != nil {
            if let viewController = nextReponder as? UIViewController {
                return viewController
            }
            nextReponder = nextReponder?.next
        }
        return nil
    }
    
    /// 生成视图的截图
    func displayViewToImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}

extension UIView {
    
    // MARK: 添加渐变色图层(例如添加至label上)
    func bk_gradientColor(_ startPoint: CGPoint, _ endPoint: CGPoint, _ colors: [UIColor]) {
        
        guard startPoint.x >= 0, startPoint.x <= 1, startPoint.y >= 0, startPoint.y <= 1, endPoint.x >= 0, endPoint.x <= 1, endPoint.y >= 0, endPoint.y <= 1 else {
            return
        }
        
        // 外界如果改变了self的大小，需要先刷新
        layoutIfNeeded()
        
        removeGradientLayer()
        
        var cgColorArr = [CGColor]()
        for color in colors {
            cgColorArr.append(color.cgColor)
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.layer.bounds
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.colors = cgColorArr
        gradientLayer.cornerRadius = self.layer.cornerRadius
        gradientLayer.masksToBounds = true
        // 渐变图层插入到最底层，避免在uibutton上遮盖文字图片
        self.layer.insertSublayer(gradientLayer, at: 0)
        self.backgroundColor = UIColor.clear
        // self如果是UILabel，masksToBounds设为true会导致文字消失
        self.layer.masksToBounds = false
    }
    
    // MARK: 移除渐变图层
    // （当希望只使用backgroundColor的颜色时，需要先移除之前加过的渐变图层）
    public func removeGradientLayer() {
        if let sl = self.layer.sublayers {
            for layer in sl {
                if layer.isKind(of: CAGradientLayer.self) {
                    layer.removeFromSuperlayer()
                }
            }
        }
    }
}
