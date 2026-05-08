//
//  SSBlurView.swift
//  SpeedySwift
//
//  Created by 2020 on 2021/8/2.
//

import UIKit
import SnapKit

/// 高斯模糊视图 (重构为标准的 UIView 子类)
@objcMembers
public class SSBlurView: UIView {
    
    private let blurEffectView = UIVisualEffectView(effect: nil)
    private let vibrancyView = UIVisualEffectView(effect: nil)
    
    public var animationDuration: TimeInterval = 0.2
    public var style: UIBlurEffect.Style = .light {
        didSet { updateBlurEffect() }
    }
    
    // 暴露内容视图供外部添加子视图
    public var blurContentView: UIView { blurEffectView.contentView }
    public var vibrancyContentView: UIView { vibrancyView.contentView }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        self.isUserInteractionEnabled = false // 默认不拦截事件
        
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        blurEffectView.contentView.addSubview(vibrancyView)
        vibrancyView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    /// 开启模糊效果 (带动画)
    public func enable(animated: Bool = true) {
        let targetEffect = UIBlurEffect(style: style)
        vibrancyView.effect = UIVibrancyEffect(blurEffect: targetEffect)
        
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut) {
                self.blurEffectView.effect = targetEffect
            }
        } else {
            self.blurEffectView.effect = targetEffect
        }
    }
    
    /// 关闭模糊效果 (带动画)
    public func disable(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut) {
                self.blurEffectView.effect = nil
                self.vibrancyView.effect = nil
            }
        } else {
            self.blurEffectView.effect = nil
            self.vibrancyView.effect = nil
        }
    }
    
    private func updateBlurEffect() {
        // 如果当前已经开启了模糊，则更新样式
        if blurEffectView.effect != nil {
            enable(animated: true)
        }
    }
}
