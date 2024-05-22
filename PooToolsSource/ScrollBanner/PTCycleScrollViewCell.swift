//
//  LLCycleScrollViewCell.swift
//  LLCycleScrollView
//
//  Created by LvJianfeng on 2016/11/22.
//  Copyright © 2016年 LvJianfeng. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString

class PTCycleScrollViewCell: PTBaseNormalCell {
    static let ID = "PTCycleScrollViewCell"
    
    // 标题
    var title: Any? {
        didSet {
            if title != nil {
                titleBackView.isHidden = false
                titleLabel.isHidden = false

                if title is String {
                    titleLabel.text = "\(title as! String)"
                } else if title is ASAttributedString {
                    titleLabel.attributedText = (title as! ASAttributedString).value
                }
            } else {
                titleBackView.isHidden = true
                titleLabel.isHidden = true
            }
        }
    }
    
    /*
     如果内容是att则字体颜色,字体失效
     */
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
    
    // 标题Label高度
    var titleLabelHeight: CGFloat! = 56 {
        didSet {
            layoutSubviews()
        }
    }

    lazy var titleBackView: UIView = {
        let view = UIView()
        view.backgroundColor = titleBackViewBackgroundColor
        view.isHidden = true
        return view
    }()
    
    // 图片
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        // 默认模式
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    fileprivate lazy var titleLabel: UILabel = {
        let view = UILabel.init()
        view.isHidden = true
        view.textColor = titleLabelTextColor
        view.numberOfLines = titleLines
        view.font = titleFont
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = false
        return view
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([imageView,titleBackView])
        titleBackView.addSubview(titleLabel)
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
    // MARK: layoutSubviews
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleBackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(self.titleLabelHeight)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(self.titleLabelHeight)
            make.left.right.equalToSuperview().inset(self.titleLabelLeading)
            make.top.equalToSuperview()
        }
    }
}
