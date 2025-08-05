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
    case Normal,Increase,Decrease
}

//界面元素屬性
@objc public enum PTSortButtonShowType:Int {
    case Tres,Dos
}

@objcMembers
public class PTSortButton: UIView {
    
    public var sortTypeHandler:((PTSortButtonType)->Void)?
    
    public var sortType:PTSortButtonType = .Normal {
        didSet {
            switch showType {
            case .Tres:
                switch sortType {
                case .Normal:
                    upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                    downImage.loadImage(contentData: dowmNormalImage, loadFinish:  { _, image,_ in
                        self.downImage.image = image
                    })
                    titleLabel.textColor = buttonTitleNormalColor
                case .Increase:
                    upImage.loadImage(contentData: upSelectedImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                    downImage.loadImage(contentData: dowmNormalImage, loadFinish:  { _, image,_ in
                        self.downImage.image = image
                    })
                    titleLabel.textColor = buttonTitleSelectedColor
                case .Decrease:
                    upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                    downImage.loadImage(contentData: downSelectedImage, loadFinish:  { _, image,_ in
                        self.downImage.image = image
                    })
                    titleLabel.textColor = buttonTitleSelectedColor
                }
            case .Dos:
                switch sortType {
                case .Normal:
                    upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                    titleLabel.textColor = buttonTitleNormalColor
                case .Decrease:
                    upImage.loadImage(contentData: dosDecreaseImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                    titleLabel.textColor = buttonTitleSelectedColor
                case .Increase:
                    upImage.loadImage(contentData: upSelectedImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                    titleLabel.textColor = buttonTitleSelectedColor
                }
            }
        }
    }
    
    public var buttonTitle:String = "" {
        didSet {
            titleLabel.text = buttonTitle
            layoutSubviews()
        }
    }
    
    public var buttonTitleFont:UIFont = .appfont(size: 14) {
        didSet {
            titleLabel.font = buttonTitleFont
            layoutSubviews()
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
            switch showType {
            case .Tres:
                switch sortType {
                case .Normal:
                    upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                case .Decrease:
                    upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                case .Increase:
                    upImage.loadImage(contentData: upSelectedImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                }
            case .Dos:
                switch sortType {
                case .Normal:
                    upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                case .Decrease:
                    upImage.loadImage(contentData: dosDecreaseImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                case .Increase:
                    upImage.loadImage(contentData: upSelectedImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                }
            }
        }
    }
    
    public var upSelectedImage:Any = UIColor.systemRed.createImageWithColor().transformImage(size: CGSizeMake(10, 10)) {
        didSet {
            switch showType {
            case .Tres:
                switch sortType {
                case .Normal:
                    upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                case .Decrease:
                    upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                case .Increase:
                    upImage.loadImage(contentData: upSelectedImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                }
            case .Dos:
                switch sortType {
                case .Normal:
                    upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                case .Decrease:
                    upImage.loadImage(contentData: dosDecreaseImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                case .Increase:
                    upImage.loadImage(contentData: upSelectedImage, loadFinish:  { _, image,_ in
                        self.upImage.image = image
                    })
                }
            }
        }
    }
    
    public var dosDecreaseImage:Any = UIColor.systemRed.createImageWithColor().transformImage(size: CGSizeMake(10, 10)) {
        didSet {
            switch sortType {
            case .Normal:
                upImage.loadImage(contentData: upNormalImage, loadFinish:  { _, image,_ in
                    self.upImage.image = image
                })
            case .Decrease:
                upImage.loadImage(contentData: dosDecreaseImage, loadFinish:  { _, image,_ in
                    self.upImage.image = image
                })
            case .Increase:
                upImage.loadImage(contentData: upSelectedImage, loadFinish:  { _, image,_ in
                    self.upImage.image = image
                })
            }
        }
    }
    
    public var dowmNormalImage:Any = UIColor.lightGray.createImageWithColor().transformImage(size: CGSizeMake(10, 10)) {
        didSet {
            switch sortType {
            case .Normal:
                downImage.loadImage(contentData: dowmNormalImage, loadFinish:  { _, image,_ in
                    self.downImage.image = image
                })
            case .Increase:
                downImage.loadImage(contentData: dowmNormalImage, loadFinish:  { _, image,_ in
                    self.downImage.image = image
                })
            case .Decrease:
                downImage.loadImage(contentData: downSelectedImage, loadFinish:  { _, image,_ in
                    self.downImage.image = image
                })
            }
        }
    }
    
    public var downSelectedImage:Any = UIColor.systemBlue.createImageWithColor().transformImage(size: CGSizeMake(10, 10)) {
        didSet {
            switch sortType {
            case .Normal:
                downImage.loadImage(contentData: dowmNormalImage, loadFinish:  { _, image,_ in
                    self.downImage.image = image
                })
            case .Increase:
                downImage.loadImage(contentData: dowmNormalImage, loadFinish:  { _, image,_ in
                    self.downImage.image = image
                })
            case .Decrease:
                downImage.loadImage(contentData: downSelectedImage, loadFinish:  { _, image,_ in
                    self.downImage.image = image
                })
            }
        }
    }
    
    public var contentImageSpace:CGFloat = 2 {
        didSet {
            layoutSubviews()
        }
    }
    
    public var imageSpace:CGFloat = 4 {
        didSet {
            layoutSubviews()
        }
    }
    
    public var imageSize:CGSize = CGSize(width: 6, height: 4) {
        didSet {
            layoutSubviews()
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
    
    fileprivate var showType:PTSortButtonShowType = .Tres
    
    public init(showType:PTSortButtonShowType = .Tres) {
        self.showType = showType
        super.init(frame: .zero)
        setUpViews()
        layoutSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        layoutSubviews()
    }
    
    func setUpViews() {
        var subViews = [UIView]()
        switch showType {
        case .Tres:
            subViews = [titleLabel,upImage,downImage]
        default:
            subViews = [titleLabel,upImage]
        }
        addSubviews(subViews)
        
        let tap = UITapGestureRecognizer { sender in
            switch self.sortType {
            case .Normal:
                self.sortType = .Increase
            case .Increase:
                self.sortType = .Decrease
            case .Decrease:
                self.sortType = .Normal
            }
            
            self.sortTypeHandler?(self.sortType)
        }
        addGestureRecognizer(tap)
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.text = buttonTitle
        
        let halfHeight = (frame.height - imageSpace) / 2
        var realImageSize:CGSize!
        if halfHeight < self.imageSize.height {
            realImageSize = CGSize(width: self.imageSize.width, height: halfHeight)
        } else {
            realImageSize = self.imageSize
        }
        
        let contentMax = frame.width - contentImageSpace - self.imageSize.width
        var titleWidth = titleLabel.sizeFor(height: frame.height).width + 5
        if titleWidth > contentMax {
            titleWidth = contentMax
        }
        var titleLeft = (frame.width - titleWidth - contentImageSpace - self.imageSize.width) / 2
        if titleLeft < 0 {
            titleLeft = 0
        }
        titleLabel.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(titleLeft)
            make.width.equalTo(titleWidth)
        }
        
        upImage.snp.remakeConstraints { make in
            make.left.equalTo(self.titleLabel.snp.right).offset(contentImageSpace)
            make.size.equalTo(realImageSize)
            switch showType {
            case .Tres:
                make.bottom.equalTo(self.titleLabel.snp.centerY).offset(-(imageSpace / 2))
            case .Dos:
                make.centerY.equalToSuperview()
            }
            make.right.lessThanOrEqualToSuperview()
        }
        
        switch showType {
        case .Tres:
            downImage.snp.remakeConstraints { make in
                make.left.size.right.equalTo(self.upImage)
                make.top.equalTo(self.upImage.snp.bottom).offset(imageSpace)
            }
        default:break
        }
    }
}
