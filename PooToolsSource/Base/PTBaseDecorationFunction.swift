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
        fatalError("init(coder:) has not been implemented")
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
    
    // 🌟 核心：每次被复用时重置状态
    open override func prepareForReuse() {
        super.prepareForReuse()
        bgView.backgroundColor = PTAppBaseConfig.share.decorationBackgroundColor
        bgImageView.isHidden = true
        bgImageView.image = nil
        layer.shadowOpacity = 0.08
    }
}
