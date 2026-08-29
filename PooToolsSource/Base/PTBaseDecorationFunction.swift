//
//  PTBaseDecorationFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

@MainActor
open class PTBaseDecorationView: UICollectionReusableView {
    public static let ID = "PTBaseDecorationView"

    // English: Cache the shadow geometry to avoid rebuilding the path on every layout pass.
    // Español: Guarda la geometría de la sombra para no reconstruir la ruta en cada pasada de diseño.
    // 中文：缓存阴影几何信息，避免每次布局都重复创建路径。
    private var shadowPathBounds: CGRect?
    private var shadowPathCornerRadius: CGFloat?
    
    // 背景容器，方便加圆角和裁切
    public lazy var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = PTAppBaseConfig.share.decorationBackgroundColor
        view.layer.cornerRadius = PTAppBaseConfig.share.decorationBackgroundCornerRadius
        view.layer.masksToBounds = true
        return view
    }()
    
    // 🌟 扩展功能 1：图片背景
    public lazy var bgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true // 默认隐藏
        return imageView
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 🌟 扩展功能 2：底层加一层高级阴影 (独立于bgView以防被masksToBounds裁掉)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 8
        
        addSubview(bgView)
        bgView.addSubview(bgImageView)
        
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 统一更新装饰视图状态，避免复用时遗留上一个分区的样式。
    public func configure(backgroundColor: UIColor,
                          cornerRadius: CGFloat,
                          shadowOpacity: Float,
                          backgroundImage: UIImage? = nil) {
        bgView.backgroundColor = backgroundColor
        bgView.layer.cornerRadius = max(0, cornerRadius)
        layer.shadowOpacity = max(0, min(1, shadowOpacity))
        bgImageView.image = backgroundImage
        bgImageView.isHidden = backgroundImage == nil
        setNeedsLayout()
    }
    
    // 🌟 核心：每次被复用时重置状态
    open override func prepareForReuse() {
        super.prepareForReuse()
        bgView.backgroundColor = PTAppBaseConfig.share.decorationBackgroundColor
        bgView.layer.cornerRadius = PTAppBaseConfig.share.decorationBackgroundCornerRadius
        bgImageView.isHidden = true
        bgImageView.image = nil
        layer.shadowOpacity = 0.08
        layer.shadowPath = nil
        shadowPathBounds = nil
        shadowPathCornerRadius = nil
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius = bgView.layer.cornerRadius
        guard shadowPathBounds != bounds || shadowPathCornerRadius != cornerRadius else { return }

        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        shadowPathBounds = bounds
        shadowPathCornerRadius = cornerRadius
    }
}
