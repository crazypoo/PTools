//
//  UILabel+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 17/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension UILabel {
    private struct AssociatedKey {
        static var startTime: CFTimeInterval = 0
        static var fromValue: Double = 0
        static var toValue: Double = 0
        static var duration: Double = 0
        static var displayLink: CADisplayLink?
        static var formatter:String = "%.2f"
    }
    private var startTime: CFTimeInterval {
        get { return objc_getAssociatedObject(self, &AssociatedKey.startTime) as? CFTimeInterval ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKey.startTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    private var fromValue: Double {
        get { return objc_getAssociatedObject(self, &AssociatedKey.fromValue) as? Double ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKey.fromValue, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var toValue: Double {
        get { return objc_getAssociatedObject(self, &AssociatedKey.toValue) as? Double ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKey.toValue, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var duration: Double {
        get { return objc_getAssociatedObject(self, &AssociatedKey.duration) as? Double ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKey.duration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var displayLink: CADisplayLink? {
        get { return objc_getAssociatedObject(self, &AssociatedKey.displayLink) as? CADisplayLink }
        set { objc_setAssociatedObject(self, &AssociatedKey.displayLink, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private var formatter: NSString? {
        get { return objc_getAssociatedObject(self, &AssociatedKey.formatter) as? NSString }
        set { objc_setAssociatedObject(self, &AssociatedKey.formatter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    //MARK: 數字跳動
    ///數字跳動
    /// - Parameters:
    ///   - fromValue: 從什麼數值開始
    ///   - to: 到哪個數值
    ///   - duration: 動畫時間
    ///   - formatter: 格式化(默認".2f")
    @objc func count(fromValue: Double, to: Double, duration: Double,formatter:NSString?) {
        self.startTime = CACurrentMediaTime()
        self.fromValue = fromValue
        self.toValue = to
        self.duration = duration
        self.formatter = formatter
        displayLink = CADisplayLink(target: self, selector: #selector(updateValue))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc private func updateValue() {
        let now = CACurrentMediaTime()
        let elapsedTime = now - startTime
        if elapsedTime > duration {
            self.text = String(format: self.formatter! as String, toValue)
            displayLink?.invalidate()
            return
        }
        let percentage = elapsedTime / duration
        let value = fromValue + percentage * (toValue - fromValue)
        
        self.text = String(format: self.formatter! as String, value)
    }
    
    //MARK: 計算文字的Size
    ///計算文字的Size
    /// - Parameters:
    ///   - lineSpacing: 行距
    ///   - size: size
    /// - Returns: Size
    @objc func sizeFor(lineSpacing:NSNumber? = nil,
                       size:CGSize)->CGSize
    {
        var dic = [NSAttributedString.Key.font:self.font] as! [NSAttributedString.Key:Any]
        if lineSpacing != nil
        {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = CGFloat(lineSpacing!.floatValue)
            dic[NSAttributedString.Key.paragraphStyle] = paraStyle
        }
        let size = self.text!.boundingRect(with: CGSize.init(width: size.width, height: size.height), options: [.usesLineFragmentOrigin,.usesDeviceMetrics], attributes: dic, context: nil).size
        return size
    }
}
