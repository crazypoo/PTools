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
    private(set) var blurContentView: UIView?
    private(set) var vibrancyContentView: UIView?
    
    private var animator: UIViewPropertyAnimator?
    
    open var animationDuration: TimeInterval = 0.1
    open var style: UIBlurEffect.Style = .light {
        didSet { updateBlurEffect() }
    }
    
    open var alpha: CGFloat = 0 {
        didSet { updateBlurEffect() }
    }
    
    public init(to view: UIView) {
        superview = view
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
    
    private func updateBlurEffect() {
        guard blur != nil else {
            applyBlurEffect()
            return
        }
        blur?.effect = UIBlurEffect(style: style)
        animateBlurEffectChange()
    }
    
    private func animateBlurEffectChange() {
        animator?.stopAnimation(true)
        animator = UIViewPropertyAnimator(duration: animationDuration, curve: .easeInOut) {
            self.blur?.alpha = self.alpha
        }
        animator?.startAnimation()
    }
    
    private func applyBlurEffect() {
        guard blur == nil, let superview = superview else { return }
        let blurEffectView = createBlurEffectView(style: style)
        blurEffectView.alpha = alpha
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
