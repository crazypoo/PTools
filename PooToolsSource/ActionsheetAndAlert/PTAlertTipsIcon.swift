//
//  PTAlertTipsIcon.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public enum PTAlertTipsIcon:Equatable {
    case Done
    case Error
    case Heart
    case SpinnerSmall
    case SpinnerLarge
    case Custom(image:UIImage)
    
    func createView(lineThick:CGFloat) -> UIView {
        switch self {
        case .Done:
            return PTAlertTipsDone(lineThick: lineThick)
        case .Error:
            return PTAlertTipsError(lineThick: lineThick)
        case .Heart:
            return PTAlertTipsHeart()
        case .SpinnerSmall:
            return PTAlertTipsSpinner(style: .medium)
        case .SpinnerLarge:
            return PTAlertTipsSpinner(style: .large)
        case .Custom(let image):
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            return imageView
        }
    }
}

public protocol PTAlertTipsAnimation {
    func animation()
}

public class PTAlertTipsDone:UIView,PTAlertTipsAnimation {
    private let lineThick: CGFloat
    
    init(lineThick: CGFloat) {
        self.lineThick = lineThick
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func animation() {
        let length = frame.width
        let animatablePath = UIBezierPath()
        animatablePath.move(to: CGPoint(x: length * 0.196, y: length * 0.527))
        animatablePath.addLine(to: CGPoint(x: length * 0.47, y: length * 0.777))
        animatablePath.addLine(to: CGPoint(x: length * 0.99, y: length * 0.25))
        
        let animatableLayer = CAShapeLayer()
        animatableLayer.path = animatablePath.cgPath
        animatableLayer.fillColor = UIColor.clear.cgColor
        animatableLayer.strokeColor = tintColor?.cgColor
        animatableLayer.lineWidth = lineThick
        animatableLayer.lineCap = .round
        animatableLayer.lineJoin = .round
        animatableLayer.strokeEnd = 0
        layer.addSublayer(animatableLayer)
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.3
        animation.fromValue = 0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animatableLayer.strokeEnd = 1
        animatableLayer.add(animation, forKey: "animation")
    }
}

public class PTAlertTipsError:UIView,PTAlertTipsAnimation {
    private let lineThick: CGFloat
    
    init(lineThick: CGFloat) {
        self.lineThick = lineThick
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func animation() {
        animateTopToBottomLine()
        animateBottomToTopLine()
    }
    
    private func animateTopToBottomLine() {
        let length = frame.width
        
        let topToBottomLine = UIBezierPath()
        topToBottomLine.move(to: CGPoint(x: length * 0, y: length * 0))
        topToBottomLine.addLine(to: CGPoint(x: length * 1, y: length * 1))
        
        let animatableLayer = CAShapeLayer()
        animatableLayer.path = topToBottomLine.cgPath
        animatableLayer.fillColor = UIColor.clear.cgColor
        animatableLayer.strokeColor = tintColor?.cgColor
        animatableLayer.lineWidth = lineThick
        animatableLayer.lineCap = .round
        animatableLayer.lineJoin = .round
        animatableLayer.strokeEnd = 0
        layer.addSublayer(animatableLayer)
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.22
        animation.fromValue = 0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        animatableLayer.strokeEnd = 1
        animatableLayer.add(animation, forKey: "animation")
    }
        
    private func animateBottomToTopLine() {
        let length = frame.width
        
        let bottomToTopLine = UIBezierPath()
        bottomToTopLine.move(to: CGPoint(x: length * 0, y: length * 1))
        bottomToTopLine.addLine(to: CGPoint(x: length * 1, y: length * 0))
        
        let animatableLayer = CAShapeLayer()
        animatableLayer.path = bottomToTopLine.cgPath
        animatableLayer.fillColor = UIColor.clear.cgColor
        animatableLayer.strokeColor = tintColor?.cgColor
        animatableLayer.lineWidth = lineThick
        animatableLayer.lineCap = .round
        animatableLayer.lineJoin = .round
        animatableLayer.strokeEnd = 0
        layer.addSublayer(animatableLayer)
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.22
        animation.fromValue = 0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        animatableLayer.strokeEnd = 1
        animatableLayer.add(animation, forKey: "animation")
    }
}

public class PTAlertTipsHeart: UIView {
        
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        HeartDraw.draw(frame: rect, resizing: .aspectFit, fillColor: tintColor)
    }
    
    class HeartDraw: NSObject {
        
        @objc dynamic public class func draw(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 510, height: 470), resizing: ResizingBehavior = .aspectFit, fillColor: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {
            let context = UIGraphicsGetCurrentContext()!
            context.saveGState()
            let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 510, height: 470), target: targetFrame)
            context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
            context.scaleBy(x: resizedFrame.width / 510, y: resizedFrame.height / 470)
            let bezierPath = UIBezierPath()
            bezierPath.move(to: CGPoint(x: 255, y: 469.6))
            bezierPath.addLine(to: CGPoint(x: 219.3, y: 433.9))
            bezierPath.addCurve(to: CGPoint(x: 0, y: 140.65), controlPoint1: CGPoint(x: 86.7, y: 316.6), controlPoint2: CGPoint(x: 0, y: 237.55))
            bezierPath.addCurve(to: CGPoint(x: 140.25, y: 0.4), controlPoint1: CGPoint(x: 0, y: 61.6), controlPoint2: CGPoint(x: 61.2, y: 0.4))
            bezierPath.addCurve(to: CGPoint(x: 255, y: 53.95), controlPoint1: CGPoint(x: 183.6, y: 0.4), controlPoint2: CGPoint(x: 226.95, y: 20.8))
            bezierPath.addCurve(to: CGPoint(x: 369.75, y: 0.4), controlPoint1: CGPoint(x: 283.05, y: 20.8), controlPoint2: CGPoint(x: 326.4, y: 0.4))
            bezierPath.addCurve(to: CGPoint(x: 510, y: 140.65), controlPoint1: CGPoint(x: 448.8, y: 0.4), controlPoint2: CGPoint(x: 510, y: 61.6))
            bezierPath.addCurve(to: CGPoint(x: 290.7, y: 433.9), controlPoint1: CGPoint(x: 510, y: 237.55), controlPoint2: CGPoint(x: 423.3, y: 316.6))
            bezierPath.addLine(to: CGPoint(x: 255, y: 469.6))
            bezierPath.close()
            fillColor.setFill()
            bezierPath.fill()
            context.restoreGState()
        }
        
        @objc(HeartStyleKitResizingBehavior)
        public enum ResizingBehavior: Int {
            
            case aspectFit
            case aspectFill
            case stretch
            case center
            
            public func apply(rect: CGRect, target: CGRect) -> CGRect {
                if rect == target || target == CGRect.zero {
                    return rect
                }
                
                var scales = CGSize.zero
                scales.width = abs(target.width / rect.width)
                scales.height = abs(target.height / rect.height)
                
                switch self {
                case .aspectFit:
                    scales.width = min(scales.width, scales.height)
                    scales.height = scales.width
                case .aspectFill:
                    scales.width = max(scales.width, scales.height)
                    scales.height = scales.width
                case .stretch:
                    break
                case .center:
                    scales.width = 1
                    scales.height = 1
                }
                
                var result = rect.standardized
                result.size.width *= scales.width
                result.size.height *= scales.height
                result.origin.x = target.minX + (target.width - result.width) / 2
                result.origin.y = target.minY + (target.height - result.height) / 2
                return result
            }
        }
    }
}

public class PTAlertTipsSpinner: UIView {
    
    let activityIndicatorView: UIActivityIndicatorView
    
    init(style: UIActivityIndicatorView.Style) {
        activityIndicatorView = UIActivityIndicatorView(style: style)
        super.init(frame: .zero)
        backgroundColor = .clear
        addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        activityIndicatorView.sizeToFit()
        activityIndicatorView.center = .init(x: frame.width / 2, y: frame.height / 2)
    }
}

