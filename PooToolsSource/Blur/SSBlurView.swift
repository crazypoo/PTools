//
//  SSBlurView.swift
//  SpeedySwift
//
//  Created by 2020 on 2021/8/2.
//

import UIKit
import SnapKit

/// 高斯模糊
@objcMembers
public class SSBlurView: NSObject {

    private weak var superview: UIView?
    private var blur: UIVisualEffectView?
    private var editing: Bool = false
    private(set) var blurContentView: UIView?
    private(set) var vibrancyContentView: UIView?
    
    open var animationDuration: TimeInterval = 0.1
    
    open var style: UIBlurEffect.Style = .light {
        didSet {
            guard oldValue != style, !editing else { return }
            applyBlurEffect()
        }
    }

    open var alpha: CGFloat = 0 {
        didSet {
            guard !editing else { return }
            if blur == nil {
                applyBlurEffect()
            }
            // 使用 UIViewPropertyAnimator 來處理動畫
            animateBlurEffectChange()
        }
    }
    
    public init(to view: UIView) {
        superview = view
        super.init()
        guard let _ = superview else {
            assertionFailure("Superview cannot be nil when initializing SSBlurView")
            return
        }
    }
    
    public func enable(isHidden: Bool = false) {
        if blur == nil {
            applyBlurEffect()
        }
        blur?.isHidden = isHidden
    }
    
    private func animateBlurEffectChange() {
        let animator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeInOut) {
            self.blur?.alpha = self.alpha
        }
        animator.startAnimation()
    }
    
    private func applyBlurEffect() {
        if blur != nil {
            // 如果已經有模糊視圖，更新其效果和透明度
            blur?.effect = UIBlurEffect(style: style)
            blur?.alpha = alpha
            return
        }
        createBlurEffectView(style: style, blurAlpha: alpha)
    }
    
    private func createBlurEffectView(style: UIBlurEffect.Style, blurAlpha: CGFloat) {
        guard let superview = superview else { return }
        
        if blur != nil {
            // 如果模糊視圖已經存在，僅更新效果和透明度
            blur?.effect = UIBlurEffect(style: style)
            blur?.alpha = blurAlpha
            return
        }
        
        // 創建新的模糊視圖
        let blurEffectView = createBlurEffectView(style: style)
        blurEffectView.alpha = blurAlpha
        superview.insertSubview(blurEffectView, at: 0)
        blurEffectView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        blur = blurEffectView
        blurContentView = blurEffectView.contentView
    }
    
    private func createBlurEffectView(style: UIBlurEffect.Style) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        blurEffectView.contentView.addSubview(vibrancyView)
        vibrancyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        vibrancyContentView = vibrancyView.contentView
        
        return blurEffectView
    }
}
