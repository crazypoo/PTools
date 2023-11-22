//
//  LLCycleScrollViewCell.swift
//  LLCycleScrollView
//
//  Created by LvJianfeng on 2016/11/22.
//  Copyright © 2016年 LvJianfeng. All rights reserved.
//

import UIKit
import SnapKit

class LLCycleScrollViewCell: UICollectionViewCell {
    
    // 标题
    var title: String = "" {
        didSet {
            titleLabel.text = "\(title)"
            
            if title.count > 0 {
                titleBackView.isHidden = false
                titleLabel.isHidden = false
            }else{
                titleBackView.isHidden = true
                titleLabel.isHidden = true
            }
        }
    }
    
    // 标题颜色
    var titleLabelTextColor: UIColor = UIColor.white {
        didSet {
            titleLabel.textColor = titleLabelTextColor
        }
    }
    
    // 标题字体
    var titleFont: UIFont = UIFont.systemFont(ofSize: 15) {
        didSet {
            titleLabel.font = titleFont
        }
    }
    
    // 文本行数
    var titleLines: NSInteger = 2 {
        didSet {
            titleLabel.numberOfLines = titleLines
        }
    }
    
    // 标题文本x轴间距
    var titleLabelLeading: CGFloat = 15 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    // 标题背景色
    var titleBackViewBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3) {
        didSet {
            titleBackView.backgroundColor = titleBackViewBackgroundColor
        }
    }
    
    var titleBackView: UIView!
    
    // 标题Label高度
    var titleLabelHeight: CGFloat! = 56 {
        didSet {
            layoutSubviews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
        setupLabelBackView()
        setupTitleLabel()
    }
    
    // 图片
    var imageView: UIImageView!
    fileprivate var titleLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Setup ImageView
    fileprivate func setupImageView() {
        imageView = UIImageView.init()
        // 默认模式
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
    }
    
    // Setup Label BackView
    fileprivate func setupLabelBackView() {
        titleBackView = UIView.init()
        titleBackView.backgroundColor = titleBackViewBackgroundColor
        titleBackView.isHidden = true
        contentView.addSubview(titleBackView)
    }
    
    // Setup Title
    fileprivate func setupTitleLabel() {
        titleLabel = UILabel.init()
        titleLabel.isHidden = true
        titleLabel.textColor = titleLabelTextColor
        titleLabel.numberOfLines = titleLines
        titleLabel.font = titleFont
        titleLabel.backgroundColor = UIColor.clear
        titleBackView.addSubview(titleLabel)
    }
    
    // MARK: layoutSubviews
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = bounds
        titleBackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(self.titleLabelHeight)
        }
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(self.titleLabelHeight)
            make.width.equalTo(self.pt.jx_width - self.titleLabelLeading - 5)
            make.left.equalToSuperview().inset(self.titleLabelLeading)
            make.top.equalToSuperview()
        }
    }
}
