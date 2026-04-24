//
//  PTPurchaseCarAnimationTool.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public typealias AnimationFinishBlock = (_ finish: Bool) -> Void

/// 使用 enum 替代 class 作为命名空间，防止被意外实例化，且不需要维护单例状态
public enum PTPurchaseCarAnimationTool {
    
    /// 开始购物车抛物线动画
    /// - Parameters:
    ///   - view: 需要做动画的原始视图 (例如商品图片)
    ///   - startRect: 动画开始的相对位置
    ///   - finishPoint: 动画结束的坐标点 (购物车图标的中心点)
    ///   - duration: 动画持续时间
    ///   - completion: 动画结束后的回调闭包
    public static func startAnimation(from view: UIView,
                                      startRect: CGRect,
                                      finishPoint: CGPoint,
                                      duration: CFTimeInterval = 1.2,
                                      completion: @escaping AnimationFinishBlock) {
        
        // 1. 安全获取当前活跃的 KeyWindow (适配 iOS 13+ 多 Scene 机制)
        guard let keyWindow = getKeyWindow() else {
            completion(false)
            return
        }
        
        // 2. 创建动画图层
        let animLayer = CALayer()
        // 使用现代 API 生成视图快照，确保任何类型的 UIView 都能正确显示出图像
        animLayer.contents = renderSnapshot(from: view)?.cgImage
        animLayer.contentsGravity = .resizeAspectFill
        
        // 设置图层大小与圆角
        let layerSize = view.bounds.size
        animLayer.bounds = CGRect(origin: .zero, size: layerSize)
        animLayer.cornerRadius = layerSize.width / 2
        animLayer.masksToBounds = true
        
        // 设置图层初始位置为 startRect 的中心点
        animLayer.position = CGPoint(x: startRect.midX, y: startRect.midY)
        keyWindow.layer.addSublayer(animLayer)
        
        // 3. 创建贝塞尔抛物线路径
        let path = UIBezierPath()
        path.move(to: animLayer.position)
        // 控制点计算：X轴位于屏幕中间，Y轴向上偏移以形成抛物线的弧度
        let controlPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: startRect.origin.y - 80)
        path.addQuadCurve(to: finishPoint, controlPoint: controlPoint)
        
        // 4. 组装动画
        let pathAnimation = CAKeyframeAnimation(keyPath: "position")
        pathAnimation.path = path.cgPath
        
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = CGFloat.pi * 4 // 旋转 2 圈 (可调)
        rotateAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [pathAnimation, rotateAnimation]
        animationGroup.duration = duration
        animationGroup.isRemovedOnCompletion = false
        animationGroup.fillMode = .forwards
        
        // 5. 使用 CATransaction 处理回调，完美避开 Delegate 造成的并发状态污染
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            // 动画完成后自动移除临时图层，并执行回调
            animLayer.removeFromSuperlayer()
            completion(true)
        }
        
        animLayer.add(animationGroup, forKey: "cartParabolaAnimation")
        
        CATransaction.commit()
    }
    
    /// 上下震动的反馈动画 (常用于购物车接收到商品时的跳动)
    public static func shakeAnimation(for view: UIView) {
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.duration = 0.25
        animation.fromValue = -5
        animation.toValue = 5
        animation.autoreverses = true // 自动反转回去
        view.layer.add(animation, forKey: "shakeAnimation")
    }
    
    // MARK: - Private Helper Methods
    
    /// 兼容 iOS 13 及以上版本的安全获取 KeyWindow 的方法
    private static func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    /// 使用现代 UIGraphicsImageRenderer API 高效截取 View 内容
    private static func renderSnapshot(from view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        return renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
    }
}
