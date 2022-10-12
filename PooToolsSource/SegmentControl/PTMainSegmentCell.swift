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
import SJAttributesStringMaker
import SDWebImage

public class PTMainSegmentCell: JXSegmentedBaseCell {
    
    open override var isSelected: Bool
    {
        didSet
        {
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

        contentView.addSubviews([self.imageIcon,self.titleLabel,self.subTitleLabel])
        
        lineView.backgroundColor = UIColor(hexString: "#F8F8F8")
        lineView.isHidden = true
        contentView.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(1)
            make.top.bottom.equalToSuperview().inset(10)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.contentView.snp.centerY)
        }
        
        self.subTitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.contentView.snp.centerY)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        //为什么使用`sizeThatFits`，而不用`sizeToFit`呢？在numberOfLines大于0的时候，cell进行重用的时候通过`sizeToFit`，label设置成错误的size。至于原因我用尽毕生所学，没有找到为什么。但是用`sizeThatFits`可以规避掉这个问题。

        switch self.cellItemModel!.onlyShowTitle {
        case .OnlyTitle(type: .OnlyTitle):
            if cellItemModel?.index == 0
            {
                lineView.isHidden = true
            }
            else
            {
                lineView.isHidden = false
            }
            self.titleLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            self.subTitleLabel.isHidden = true
        case .OnlyTitle(type: .Normal):
            if cellItemModel?.index == 0
            {
                lineView.isHidden = true
            }
            else
            {
                lineView.isHidden = false
            }
            
            PTUtils.gcdAfter(time: 0.1) {
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
            self.titleLabel.isHidden = true
            self.subTitleLabel.isHidden = true
            self.contentView.addSubview(self.imageIcon)
            self.imageIcon.snp.makeConstraints { make in
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
                    
        if !(cellItemModel!.subTitle!).stringIsEmpty()
        {
            subTitleLabel.backgroundColor = myItemModel.subTitleCurrentBGColor
            
            let subAtt = NSMutableAttributedString.sj.makeText { make in
                make.append(myItemModel.subTitle!).font(myItemModel.isSelected ? myItemModel.subTitleSelectedFont : myItemModel.subTitleNormalFont).textColor(myItemModel.subTitleCurrentColor).alignment(.center)
            }
            self.subTitleLabel.attributedText = subAtt

        }
        else
        {
            subTitleLabel.backgroundColor = .clear
        }

        switch self.cellItemModel!.onlyShowTitle! {
        case .ImageTitle:
            SDWebImageManager.shared.loadImage(with: URL.init(string: myItemModel.imageURL!), progress: nil) { images, data, error, cache, finish, url in
                if finish
                {
                    let att = NSMutableAttributedString.sj.makeText { make in
                        make.append { imageMake in
                            imageMake.image = images
                            imageMake.bounds = CGRect.init(x: 0, y: -2.5, width: CGFloat.ScaleW(w: 20), height: CGFloat.ScaleW(w: 20))
                        }.alignment(.center)
                        make.append(myItemModel.title!).font(myItemModel.isSelected ? myItemModel.titleSelectedFont : myItemModel.titleNormalFont).textColor(myItemModel.titleCurrentColor).alignment(.center)
                    }
                    self.titleLabel.attributedText = att
                }
            }
        case .OnlyTitle:
            if myItemModel.isSelected {
                titleLabel.font = myItemModel.titleSelectedFont
                titleLabel.textColor = myItemModel.titleSelectedColor

            }
            else
            {
                titleLabel.font = myItemModel.titleNormalFont
                titleLabel.textColor = myItemModel.titleNormalColor
            }
            titleLabel.text = myItemModel.title
            titleLabel.textColor = myItemModel.titleCurrentColor
            titleLabel.textAlignment = .center
        case .OnlyImage:
            self.imageIcon.pt_SDWebImage(imageString: myItemModel.imageURL!)
        }
                
        startSelectedAnimationIfNeeded(itemModel: itemModel, selectedType: selectedType)
        layoutSubviews()
    }
}

