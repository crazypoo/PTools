//
//  PTSortButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/1.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit

@objc public enum PTSortButtonType:Int {
    case Normal
    case Increase
    case Decrease
}

@objcMembers
public class PTSortButton: UIView {
    
    public var sortTypeHandler:((PTSortButtonType)->Void)?
    
    public var sortType:PTSortButtonType = .Normal {
        didSet {
            switch sortType {
            case .Normal:
                upImage.loadImage(contentData: upNormalImage)
                downImage.loadImage(contentData: dowmNormalImage)
                titleLabel.textColor = buttonTitleNormalColor
            case .Increase:
                upImage.loadImage(contentData: upSelectedImage)
                downImage.loadImage(contentData: dowmNormalImage)
                titleLabel.textColor = buttonTitleSelectedColor
            case .Decrease:
                upImage.loadImage(contentData: upNormalImage)
                downImage.loadImage(contentData: downSelectedImage)
                titleLabel.textColor = buttonTitleSelectedColor
            }
        }
    }
    
    public var buttonTitle:String = "" {
        didSet {
            titleLabel.text = buttonTitle
        }
    }
    
    public var buttonTitleFont:UIFont = .appfont(size: 14) {
        didSet {
            titleLabel.font = buttonTitleFont
        }
    }
    
    public var buttonTitleSelectedColor:UIColor = .white {
        didSet {
            switch sortType {
            case .Increase,.Decrease:
                titleLabel.textColor = buttonTitleSelectedColor
            default:
                titleLabel.textColor = buttonTitleNormalColor
            }
        }
    }
    
    public var buttonTitleNormalColor:UIColor = .lightGray {
        didSet {
            switch sortType {
            case .Normal:
                titleLabel.textColor = buttonTitleNormalColor
            default:
                titleLabel.textColor = buttonTitleSelectedColor
            }
        }
    }
    
    public var upNormalImage:Any = UIColor.lightGray.createImageWithColor().transformImage(size: CGSizeMake(10, 10)) {
        didSet {
            switch sortType {
            case .Normal:
                upImage.loadImage(contentData: upNormalImage)
            case .Decrease:
                upImage.loadImage(contentData: upNormalImage)
            case .Increase:
                upImage.loadImage(contentData: upSelectedImage)
            }
        }
    }
    
    public var upSelectedImage:Any = UIColor.systemRed.createImageWithColor().transformImage(size: CGSizeMake(10, 10)) {
        didSet {
            switch sortType {
            case .Normal:
                upImage.loadImage(contentData: upNormalImage)
            case .Decrease:
                upImage.loadImage(contentData: upNormalImage)
            case .Increase:
                upImage.loadImage(contentData: upSelectedImage)
            }
        }
    }
    
    public var dowmNormalImage:Any = UIColor.lightGray.createImageWithColor().transformImage(size: CGSizeMake(10, 10)) {
        didSet {
            switch sortType {
            case .Normal:
                downImage.loadImage(contentData: dowmNormalImage)
            case .Increase:
                downImage.loadImage(contentData: dowmNormalImage)
            case .Decrease:
                downImage.loadImage(contentData: downSelectedImage)
            }
        }
    }
    
    public var downSelectedImage:Any = UIColor.systemBlue.createImageWithColor().transformImage(size: CGSizeMake(10, 10)) {
        didSet {
            switch sortType {
            case .Normal:
                downImage.loadImage(contentData: dowmNormalImage)
            case .Increase:
                downImage.loadImage(contentData: dowmNormalImage)
            case .Decrease:
                downImage.loadImage(contentData: downSelectedImage)
            }
        }
    }
    
    fileprivate lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.font = buttonTitleFont
        view.textAlignment = .center
        view.numberOfLines = 0
        view.textColor = buttonTitleNormalColor
        view.text = buttonTitle
        return view
    }()
    
    fileprivate lazy var upImage:UIImageView = {
        let view = UIImageView()
        view.loadImage(contentData: upNormalImage)
        return view
    }()
    
    fileprivate lazy var downImage:UIImageView = {
        let view = UIImageView()
        view.loadImage(contentData: dowmNormalImage)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([titleLabel,upImage,downImage])
        
        let tap = UITapGestureRecognizer { sender in
            switch self.sortType {
            case .Normal:
                self.sortType = .Increase
            case .Increase:
                self.sortType = .Decrease
            case .Decrease:
                self.sortType = .Normal
            }
            
            if self.sortTypeHandler != nil {
                self.sortTypeHandler!(self.sortType)
            }
        }
        addGestureRecognizer(tap)
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.text = buttonTitle
    }
    
    public override func draw(_ rect: CGRect) {
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(2.5)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(10)
        }
        
        upImage.snp.makeConstraints { make in
            make.left.equalTo(self.titleLabel.snp.right).offset(2)
            make.size.equalTo(CGSize(width: 6, height: 4))
            make.bottom.equalTo(self.titleLabel.snp.centerY).offset(-2)
        }
        downImage.snp.makeConstraints { make in
            make.left.size.equalTo(self.upImage)
            make.top.equalTo(self.upImage.snp.bottom).offset(4)
        }
    }
}
