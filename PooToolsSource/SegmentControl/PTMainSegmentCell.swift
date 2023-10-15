//
//  MSMainSegmentCell.swift
//  MinaTicket
//
//  Created by jax on 2022/6/18.
//  Copyright © 2022 Hola. All rights reserved.
//

import UIKit
import JXSegmentedView
import SnapKit
import SwifterSwift
import AttributedString
import Kingfisher

public class PTMainSegmentCell: JXSegmentedBaseCell {
    
    open override var isSelected: Bool {
        didSet {
        }
    }
    
    private var cellItemModel:PTMainSegmentModel?
    
    public let lineView = UIView()

    public let titleLabel = UILabel()
    public let subTitleLabel = UILabel()
    
    lazy var imageIcon : UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    open override func commonInit() {
        super.commonInit()

        contentView.addSubviews([imageIcon, titleLabel, subTitleLabel])
        
        lineView.backgroundColor = UIColor(hexString: "#F8F8F8")
        lineView.isHidden = true
        contentView.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(1)
            make.top.bottom.equalToSuperview().inset(10)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.contentView.snp.centerY)
        }
        
        subTitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.contentView.snp.centerY)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        //为什么使用`sizeThatFits`，而不用`sizeToFit`呢？在numberOfLines大于0的时候，cell进行重用的时候通过`sizeToFit`，label设置成错误的size。至于原因我用尽毕生所学，没有找到为什么。但是用`sizeThatFits`可以规避掉这个问题。

        switch cellItemModel!.onlyShowTitle {
        case .OnlyTitle(type: .OnlyTitle):
            if cellItemModel?.index == 0 {
                lineView.isHidden = true
            } else {
                lineView.isHidden = false
            }
            titleLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            subTitleLabel.isHidden = true
        case .OnlyTitle(type: .Normal):
            if cellItemModel?.index == 0 {
                lineView.isHidden = true
            } else {
                lineView.isHidden = false
            }
            
            PTGCDManager.gcdAfter(time: 0.1) {
                self.titleLabel.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.bottom.equalTo(self.contentView.snp.centerY)
                }
                
                self.subTitleLabel.isHidden = false
                self.subTitleLabel.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(self.contentView.snp.centerY)
                }
            }
        case .OnlyImage:
            titleLabel.isHidden = true
            subTitleLabel.isHidden = true
            contentView.addSubview(imageIcon)
            imageIcon.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        default:
            break
        }
    }

    open override func reloadData(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.reloadData(itemModel: itemModel, selectedType: selectedType )

        guard let myItemModel = itemModel as? PTMainSegmentModel else {
            return
        }
        cellItemModel = myItemModel        
                    
        if !(cellItemModel!.subTitle!).stringIsEmpty() {
            subTitleLabel.backgroundColor = myItemModel.subTitleCurrentBGColor
            
            let subAtt:ASAttributedString =  ASAttributedString("\(myItemModel.subTitle!)",.paragraph(.alignment(.center)),.font(myItemModel.isSelected ? myItemModel.subTitleSelectedFont : myItemModel.subTitleNormalFont),.foreground(myItemModel.subTitleCurrentColor))
            subTitleLabel.attributed.text = subAtt

        } else {
            subTitleLabel.backgroundColor = .clear
        }

        switch cellItemModel!.onlyShowTitle! {
        case .ImageTitle:
            ImageDownloader.default.downloadImage(with: URL.init(string: myItemModel.imageURL!)!, options: PTAppBaseConfig.share.gobalWebImageLoadOption()) { result in
                switch result {
                case .success(let value):
                    let imageAtt:ASAttributedString = """
                    \(wrap:.embedding("""
                    \(.image(value.image,.custom(size: CGSize(width: 20, height: 20))))
                    """),.paragraph(.alignment(.center)),.baselineOffset(2.5))
                    """
                    let textAtt:ASAttributedString = ASAttributedString("\(myItemModel.title!)",.paragraph(.alignment(.center)),.font(myItemModel.isSelected ? myItemModel.titleSelectedFont : myItemModel.titleNormalFont),.foreground(myItemModel.titleCurrentColor))
                    self.titleLabel.attributed.text = imageAtt + textAtt
                case .failure(let error):
                    PTNSLogConsole(error)
                }
            }
        case .OnlyTitle:
            if myItemModel.isSelected {
                titleLabel.font = myItemModel.titleSelectedFont
                titleLabel.textColor = myItemModel.titleSelectedColor
            } else {
                titleLabel.font = myItemModel.titleNormalFont
                titleLabel.textColor = myItemModel.titleNormalColor
            }
            titleLabel.text = myItemModel.title
            titleLabel.textColor = myItemModel.titleCurrentColor
            titleLabel.textAlignment = .center
        case .OnlyImage:
            imageIcon.pt_SDWebImage(imageString: myItemModel.imageURL!)
        }
                
        startSelectedAnimationIfNeeded(itemModel: itemModel, selectedType: selectedType)
        layoutSubviews()
    }
}

