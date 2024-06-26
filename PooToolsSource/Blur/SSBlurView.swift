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
public class SSBlurView:NSObject {
    
    private var superview: UIView
    private var blur: UIVisualEffectView?
    private var editing: Bool = false
    private(set) var blurContentView: UIView?
    private(set) var vibrancyContentView: UIView?
    
    open var animationDuration: TimeInterval = 0.1
    
    /**
     * Blur style. After it is changed all subviews on
     * blurContentView & vibrancyContentView will be deleted.
     */
    open var style: UIBlurEffect.Style = .light {
        didSet {
            guard oldValue != style,
                  !editing else { return }
            applyBlurEffect()
        }
    }
    /**
     * Alpha component of view. It can be changed freely.
     */
    open var alpha: CGFloat = 0 {
        didSet {
            guard !editing else { return }
            if blur == nil {
                applyBlurEffect()
            }
            let alpha = alpha
            UIView.animate(withDuration: animationDuration) {
                self.blur?.alpha = alpha
            }
        }
    }
    
    public init(to view: UIView) {
        superview = view
    }
    
    
    public func enable(isHidden: Bool = false) {
        if blur == nil {
            applyBlurEffect()
        }
        
        blur?.isHidden = isHidden
    }
    
    private func applyBlurEffect() {
        blur?.removeFromSuperview()
        
        applyBlurEffect(
            style: style,
            blurAlpha: alpha
        )
    }
    
    private func applyBlurEffect(style: UIBlurEffect.Style,
                                 blurAlpha: CGFloat) {
        superview.backgroundColor = UIColor.clear
        
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        blurEffectView.contentView.addSubview(vibrancyView)
        
        blurEffectView.alpha = blurAlpha
        
        superview.insertSubview(blurEffectView, at: 0)
        blurEffectView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        vibrancyView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        blur = blurEffectView
        blurContentView = blurEffectView.contentView
        vibrancyContentView = vibrancyView.contentView
    }
}

