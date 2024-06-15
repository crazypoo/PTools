//
//  PTActionSheetController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

public typealias PTActionSheetCallback = (_ sheet:PTActionSheetController) -> Void
public typealias PTActionSheetIndexCallback = (_ sheet:PTActionSheetController, _ index:Int,_ title:String)->Void

public class PTActionSheetController: PTAlertController {
    
    public var actionSheetCancelSelectBlock:PTActionSheetCallback?
    public var actionSheetDestructiveSelectBlock:PTActionSheetIndexCallback?
    public var actionSheetSelectBlock:PTActionSheetIndexCallback?

    fileprivate var cancelSheetItem:PTActionSheetItem!
    fileprivate var destructiveItems:[PTActionSheetItem]?
    fileprivate var contentItems:[PTActionSheetItem]?
    fileprivate var sheetConfig:PTActionSheetViewConfig!
    fileprivate var titleItem:PTActionSheetTitleItem?

    private lazy var cancelBtn : PTActionCell = {
        let view = PTActionCell()
        view.cellButton.addActionHandlers(handler: { (sender) in
            self.dismissAnimation {
                if self.actionSheetCancelSelectBlock != nil {
                    self.actionSheetCancelSelectBlock!(self)
                }
            }
        })
        view.cellButton.normalTitle = cancelSheetItem.title
        view.cellButton.normalTitleFont = cancelSheetItem.titleFont!
        view.cellButton.normalTitleColor = cancelSheetItem.titleColor!
        view.cellButton.hightlightTitleFont = cancelSheetItem.titleFont!
        view.cellButton.hightlightTitleColor = cancelSheetItem.titleColor!
        view.cellButton.configBackgroundHightlightColor = cancelSheetItem.heightlightColor!
        view.cellButton.contentHorizontalAlignment = cancelSheetItem.itemAlignment!
        switch cancelSheetItem.itemAlignment! {
        case .center:
            break
        case .left,.leading:
            view.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: cancelSheetItem.contentEdgeValue, bottom: 0, trailing: 0)
        case .right,.trailing:
            view.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: cancelSheetItem.contentEdgeValue)
        case .fill:
            view.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: cancelSheetItem.contentEdgeValue, bottom: 0, trailing: cancelSheetItem.contentEdgeValue)
        @unknown default:
            break
        }
        if cancelSheetItem.image != nil {
            switch cancelSheetItem.itemLayout! {
            case .leftImageRightTitle:
                view.cellButton.layoutStyle = .leftImageRightTitle
            case .leftTitleRightImage:
                view.cellButton.layoutStyle = .leftTitleRightImage
            }
            
            var itemSize = CGSizeZero
            if cancelSheetItem.imageSize.height >= (self.sheetConfig.rowHeight - 20) {
                itemSize = CGSizeMake(cancelSheetItem.imageSize.width, self.sheetConfig.rowHeight - 20)
            } else {
                itemSize = cancelSheetItem.imageSize
            }
            view.cellButton.imageSize = itemSize
            view.cellButton.midSpacing = cancelSheetItem.contentImageSpace
            view.cellButton.layoutLoadImage(contentData: cancelSheetItem.image as Any,iCloudDocumentName: cancelSheetItem.iCloudDocumentName)
        }
        view.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: .allCorners)
        return view
    }()
    
    private func setDestructiveCount(@PTClampedProperyWrapper(range:0...5) counts:Int = 0) {
        destructiveCount = counts
    }
    private var destructiveCount:Int = 0

    lazy var contentScrollerView:UIScrollView = {
        let view = UIScrollView()
        return view
    }()

    public init(viewConfig:PTActionSheetViewConfig = PTActionSheetViewConfig(),
                titleItem:PTActionSheetTitleItem? = nil,
                cancelItem:PTActionSheetItem = PTActionSheetItem(title: "PT Button cancel".localized()),
                destructiveItems:[PTActionSheetItem] = [PTActionSheetItem](),
                contentItems:[PTActionSheetItem]? = [PTActionSheetItem]()) {
        self.sheetConfig = viewConfig
        self.titleItem = titleItem
        self.cancelSheetItem = cancelItem
        self.destructiveItems = destructiveItems
        self.contentItems = contentItems
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([cancelBtn])
        cancelBtn.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.height.equalTo(self.sheetConfig.rowHeight)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
        }
        
        setDestructiveCount(counts: destructiveItems?.count ?? 0)
        
        if destructiveCount > 0 {
            for i in 0..<destructiveCount {
                let destructiveItem = destructiveItems![i]
                let destructiveView = PTActionCell()
                destructiveView.cellButton.normalTitle = destructiveItem.title
                destructiveView.cellButton.normalTitleFont = destructiveItem.titleFont!
                destructiveView.cellButton.normalTitleColor = destructiveItem.titleColor!
                destructiveView.cellButton.hightlightTitleFont = destructiveItem.titleFont!
                destructiveView.cellButton.hightlightTitleColor = destructiveItem.titleColor!
                destructiveView.cellButton.configBackgroundHightlightColor = destructiveItem.heightlightColor!
                destructiveView.cellButton.contentHorizontalAlignment = destructiveItem.itemAlignment!
                switch destructiveItem.itemAlignment! {
                case .center:
                    break
                case .left,.leading:
                    destructiveView.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: destructiveItem.contentEdgeValue, bottom: 0, trailing: 0)
                case .right,.trailing:
                    destructiveView.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: destructiveItem.contentEdgeValue)
                case .fill:
                    destructiveView.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: destructiveItem.contentEdgeValue, bottom: 0, trailing: destructiveItem.contentEdgeValue)
                @unknown default:
                    break
                }
                if destructiveItem.image != nil {
                    switch destructiveItem.itemLayout! {
                    case .leftImageRightTitle:
                        destructiveView.cellButton.layoutStyle = .leftImageRightTitle
                    case .leftTitleRightImage:
                        destructiveView.cellButton.layoutStyle = .leftTitleRightImage
                    }
                    
                    var itemSize = CGSizeZero
                    if destructiveItem.imageSize.height >= (sheetConfig.rowHeight - 20) {
                        itemSize = CGSizeMake(destructiveItem.imageSize.width, sheetConfig.rowHeight - 20)
                    } else {
                        itemSize = destructiveItem.imageSize
                    }
                    destructiveView.cellButton.imageSize = itemSize
                    destructiveView.cellButton.midSpacing = destructiveItem.contentImageSpace
                    destructiveView.cellButton.layoutLoadImage(contentData: destructiveItem.image as Any,iCloudDocumentName: destructiveItem.iCloudDocumentName)
                }
                destructiveView.cellButton.addActionHandlers { sender in
                    self.dismissAnimation {
                        if self.actionSheetDestructiveSelectBlock != nil {
                            self.actionSheetDestructiveSelectBlock!(self,i,destructiveItem.title)
                        }
                    }
                }
                destructiveView.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: .allCorners)
                view.addSubview(destructiveView)
                let destructiveY = -(self.sheetConfig.separatorHeight + (self.sheetConfig.separatorHeight + self.sheetConfig.rowHeight) * CGFloat(i))
                destructiveView.snp.makeConstraints { make in
                    make.left.right.equalTo(self.cancelBtn)
                    make.height.equalTo(self.sheetConfig.rowHeight)
                    make.bottom.equalTo(self.cancelBtn.snp.top).offset(destructiveY)
                }
            }
        }
        
        var contentItmesBottom:CGFloat = 0
        if destructiveCount > 0 {
            contentItmesBottom = -(self.sheetConfig.separatorHeight + (self.sheetConfig.separatorHeight + self.sheetConfig.rowHeight) * CGFloat(destructiveCount)) - 10
        } else {
            contentItmesBottom = -self.sheetConfig.separatorHeight
        }
        
        let contentItmesMaxHeight:CGFloat = CGFloat.kSCREEN_HEIGHT - (sheetConfig.rowHeight + CGFloat.kTabbarSaveAreaHeight + 10 + sheetConfig.rowHeight * CGFloat(destructiveCount) + sheetConfig.separatorHeight * CGFloat(destructiveCount - 1) + 10 + CGFloat.kNavBarHeight_Total + 20 + self.sheetConfig.rowHeight)
        var currentContentHeight:CGFloat = CGFloat(contentItems?.count ?? 0) * sheetConfig.rowHeight
        var contentItemCanScrol:Bool = false
        if currentContentHeight > contentItmesMaxHeight {
            currentContentHeight = contentItmesMaxHeight
            
            contentItemCanScrol = true
        }
        
        contentScrollerView.contentSize = CGSize(width: CGFloat.kSCREEN_WIDTH - 20, height: CGFloat(contentItems?.count ?? 0) * sheetConfig.rowHeight + CGFloat((contentItems?.count ?? 0) - 1) * sheetConfig.lineHeight)
        contentScrollerView.isScrollEnabled = contentItemCanScrol
        view.addSubviews([contentScrollerView])
        contentScrollerView.snp.makeConstraints { make in
            make.left.right.equalTo(self.cancelBtn)
            make.bottom.equalTo(self.cancelBtn.snp.top).offset(contentItmesBottom)
            make.height.equalTo(currentContentHeight)
        }
        
        contentSubsSet()
    }
    
    func contentSubsSet() {
        if contentItems?.count ?? 0 > 0 {
            contentItems?.enumerated().forEach({ index,value in
                let lineY = self.sheetConfig.rowHeight * CGFloat(index) + self.sheetConfig.lineHeight * CGFloat(index)
                let lineView = UIView()
                lineView.backgroundColor = .lightGray
                contentScrollerView.addSubview(lineView)
                lineView.snp.makeConstraints { make in
                    make.height.equalTo(self.sheetConfig.lineHeight)
                    make.width.equalTo(CGFloat.kSCREEN_WIDTH - self.sheetConfig.viewSpace * 2)
                    make.centerX.equalToSuperview()
                    make.top.equalTo(lineY)
                }
                
                let btn = PTActionCell()
                btn.cellButton.normalTitle = value.title
                btn.cellButton.normalTitleFont = value.titleFont!
                btn.cellButton.normalTitleColor = value.titleColor!
                btn.cellButton.hightlightTitleFont = value.titleFont!
                btn.cellButton.hightlightTitleColor = value.titleColor!
                btn.cellButton.configBackgroundHightlightColor = value.heightlightColor!
                btn.cellButton.contentHorizontalAlignment = value.itemAlignment!
                switch value.itemAlignment! {
                case .center:
                    break
                case .left,.leading:
                    btn.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: value.contentEdgeValue, bottom: 0, trailing: 0)
                case .right,.trailing:
                    btn.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: value.contentEdgeValue)
                case .fill:
                    btn.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: value.contentEdgeValue, bottom: 0, trailing: value.contentEdgeValue)
                @unknown default:
                    break
                }
                if value.image != nil {
                    switch value.itemLayout! {
                    case .leftImageRightTitle:
                        btn.cellButton.layoutStyle = .leftImageRightTitle
                    case .leftTitleRightImage:
                        btn.cellButton.layoutStyle = .leftTitleRightImage
                    }
                    
                    var itemSize = CGSizeZero
                    if value.imageSize.height >= (sheetConfig.rowHeight - 20) {
                        itemSize = CGSizeMake(value.imageSize.width, sheetConfig.rowHeight - 20)
                    } else {
                        itemSize = value.imageSize
                    }
                    btn.cellButton.imageSize = itemSize
                    btn.cellButton.midSpacing = value.contentImageSpace
                    btn.cellButton.layoutLoadImage(contentData: value.image as Any,iCloudDocumentName: value.iCloudDocumentName)
                }
                btn.cellButton.addActionHandlers { sender in
                    self.dismissAnimation {
                        self.actionSheetSelectBlock?(self,index,value.title)
                    }
                }
                contentScrollerView.addSubview(btn)
                
                btn.snp.makeConstraints { make in
                    make.left.right.equalTo(lineView)
                    make.top.equalTo(lineView.snp.bottom)
                    make.height.equalTo(self.sheetConfig.rowHeight)
                }
                
                if titleItem == nil {
                    if index == 0 {
                        lineView.isHidden = true
                        PTGCDManager.gcdAfter(time: 0.1) {
                            btn.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: [.topLeft,.topRight])
                        }
                    }
                }
                
                if index == (contentItems!.count - 1) {
                    PTGCDManager.gcdAfter(time: 0.1) {
                        btn.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: [.bottomLeft,.bottomRight])
                    }
                }

            })
        }
    }
}

extension PTActionSheetController {
    public override func showAnimation(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.40)
//            self.contentView.alpha = 1.0
        }
//        contentView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        UIView.animate(withDuration: 0.35, delay: 0.0, options: UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(7 << 16)), animations: {
//            self.contentView.transform = CGAffineTransform.identity
        }) { _ in
            completion?()
        }
    }
    
    public override func dismissAnimation(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00)
//            self.contentView.alpha = 0.0
        }) { _ in
            PTAlertManager.dismiss(self.key)
            completion?()
        }
    }
}
