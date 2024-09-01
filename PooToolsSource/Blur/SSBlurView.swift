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
            UIView.animate(withDuration: animationDuration) {
                self.blur?.alpha = self.alpha
            }
        }
    }
    
    public init(to view: UIView) {
        superview = view
        super.init()
    }
    
    public func enable(isHidden: Bool = false) {
        if blur == nil {
            applyBlurEffect()
        }
        blur?.isHidden = isHidden
    }
    
    private func applyBlurEffect() {
        blur?.removeFromSuperview()
        createBlurEffectView(style: style, blurAlpha: alpha)
    }
    
    private func createBlurEffectView(style: UIBlurEffect.Style, blurAlpha: CGFloat) {
        guard let superview = superview else { return }
        
        superview.backgroundColor = .clear
        
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
