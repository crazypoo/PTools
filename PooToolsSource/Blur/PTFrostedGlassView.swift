//
//  PTFrostedGlassView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/22/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import CoreImage

public class PTFrostedGlassView: UIView {
    // English: Retain the effect views and layer so layout and trait updates do not create duplicate resources.
    // Español: Conserva las vistas de efecto y la capa para que los cambios de layout y traits no creen recursos duplicados.
    // 中文：保留效果视图和渐变层，避免布局与 trait 更新时重复创建资源。
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let gradientLayer = CAGradientLayer()
    private var traitChangeRegistration: (any UITraitChangeRegistration)?
    
    // 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // 配置视图，添加模糊和渐变层
    private func setupView() {
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)

        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.15).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.locations = [0, 1]
        layer.insertSublayer(gradientLayer, at: 0)

        traitChangeRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: PTFrostedGlassView, _: UITraitCollection) in
            self?.updateGradientColors()
        }
        updateGradientColors()
    }

    private func updateGradientColors() {
        let highlightAlpha: CGFloat = traitCollection.userInterfaceStyle == .dark ? 0.10 : 0.15
        let highlight = UIColor.white.withAlphaComponent(highlightAlpha).resolvedColor(with: traitCollection)
        let clear = UIColor.clear.resolvedColor(with: traitCollection)
        gradientLayer.colors = [highlight.cgColor, clear.cgColor]
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        blurEffectView.frame = bounds
        gradientLayer.frame = bounds
    }
}
