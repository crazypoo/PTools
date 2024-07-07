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
import AttributedString
import pop

public typealias PTActionSheetCallback = (_ sheet:PTActionSheetController) -> Void
public typealias PTActionSheetIndexCallback = (_ sheet:PTActionSheetController, _ index:Int,_ title:String)->Void

public class PTActionCell:UIView {
        
    private lazy var blur:SSBlurView = {
        let blurs = SSBlurView.init(to: self)
        blurs.alpha = 0.9
        blurs.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
        return blurs
    }()
    
    lazy var cellButton : PTLayoutButton = {
        let view = PTLayoutButton()
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                self.blur.style = previousTraitCollection.userInterfaceStyle == .dark ? .extraLight : .dark
            }
        }
        addSubview(cellButton)
        cellButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        blur.enable()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @available(iOS, introduced: 8.0, deprecated: 17.0,message: "17後不再支持了")
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // 适配代码
            PTNSLogConsole("\(UITraitCollection.current.userInterfaceStyle)")
            blur.style = UITraitCollection.current.userInterfaceStyle == .dark ? .extraLight : .dark
        }
    }
}

@objc public enum PTSheetButtonStyle: Int {
    case leftImageRightTitle
    case leftTitleRightImage
}

@objcMembers
public class PTActionSheetItem:NSObject {
    public var title:String = ""
    public var titleColor:UIColor? = .systemBlue
    public var titleFont:UIFont? = .systemFont(ofSize: 20)
    public var image:Any?
    public var imageSize:CGSize = CGSizeMake(34, 34)
    public var iCloudDocumentName:String = ""
    public var heightlightColor:UIColor? = .lightGray
    public var itemAlignment:UIControl.ContentHorizontalAlignment? = .center
    public var itemLayout:PTSheetButtonStyle? = .leftImageRightTitle
    public var contentEdgeValue:CGFloat = 20
    public var contentImageSpace:CGFloat = 15

    public init(title: String,
                titleColor: UIColor? = .systemBlue,
                titleFont: UIFont? = .systemFont(ofSize: 20),
                image: Any? = nil,
                imageSize:CGSize = CGSizeMake(34, 34),
                iCloudDocumentName:String = "",
                heightlightColor: UIColor? = .lightGray,
                itemAlignment: UIControl.ContentHorizontalAlignment? = .center,
                itemLayout:PTSheetButtonStyle? = .leftImageRightTitle,
                contentEdgeValue:CGFloat = 20,
                contentImageSpace:CGFloat = 15) {
        self.title = title
        self.titleColor = titleColor
        self.titleFont = titleFont
        self.image = image
        self.imageSize = imageSize
        self.heightlightColor = heightlightColor
        self.itemAlignment = itemAlignment
        self.itemLayout = itemLayout
        self.iCloudDocumentName = iCloudDocumentName
        self.contentEdgeValue = contentEdgeValue
        self.contentImageSpace = contentImageSpace
    }
}

@objcMembers
public class PTActionSheetTitleItem:NSObject {
    public var title:String = ""
    public var subTitle:String = ""
    public var titleFont:UIFont? = .systemFont(ofSize: 16)
    public var titleColor:UIColor? = UIColor.systemGray
    public var image:Any?
    public var imageSize:CGSize = CGSizeMake(34, 34)
    public var iCloudDocumentName:String = ""
    public var itemLayout:PTSheetButtonStyle? = .leftImageRightTitle
    public var contentImageSpace:CGFloat = 15

    public init(title: String = "",
                subTitle: String = "",
                titleFont: UIFont? = .systemFont(ofSize: 16),
                titleColor: UIColor? = .systemGray,
                image: Any? = nil,
                imageSize:CGSize = CGSizeMake(34, 34),
                iCloudDocumentName:String = "",
                itemLayout:PTSheetButtonStyle? = .leftImageRightTitle,
                contentImageSpace:CGFloat = 15) {
        self.title = title
        self.subTitle = subTitle
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.image = image
        self.imageSize = imageSize
        self.itemLayout = itemLayout
        self.iCloudDocumentName = iCloudDocumentName
        self.contentImageSpace = contentImageSpace
    }
}

public class PTActionSheetViewConfig:NSObject {
    fileprivate var lineHeight:CGFloat = 0
    fileprivate var rowHeight:CGFloat = 0
    fileprivate var separatorHeight:CGFloat = 0
    fileprivate var viewSpace:CGFloat = 0
    fileprivate var cornerRadii:CGFloat = 0
    fileprivate var dismissWithTapBG:Bool = true
    
    public init(
    @PTClampedProperyWrapper(range:0.1...0.5) lineHeight: CGFloat = 0.5,
    @PTClampedProperyWrapper(range:44...74) rowHeight: CGFloat = 54,
    @PTClampedProperyWrapper(range:1...10) separatorHeight: CGFloat = 5,
    @PTClampedProperyWrapper(range:10...50) viewSpace: CGFloat = 10,
    @PTClampedProperyWrapper(range:0...15) cornerRadii: CGFloat = 15,
dismissWithTapBG: Bool = true) {
        self.lineHeight = lineHeight
        self.rowHeight = rowHeight
        self.separatorHeight = separatorHeight
        self.viewSpace = viewSpace
        self.cornerRadii = cornerRadii
        self.dismissWithTapBG = dismissWithTapBG
    }
}

public class PTActionSheetController: PTAlertController {
    
    public var actionSheetCancelSelectBlock:PTActionSheetCallback?
    public var actionSheetDestructiveSelectBlock:PTActionSheetIndexCallback?
    public var actionSheetSelectBlock:PTActionSheetIndexCallback?
    public var tapBackgroundBlock:PTActionSheetCallback?

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
    
    fileprivate func setDestructiveCount(@PTClampedProperyWrapper(range:0...5) counts:Int = 0) {
        destructiveCount = counts
    }
    fileprivate var destructiveCount:Int = 0
    
    fileprivate var totalHeight:CGFloat = 0
    
    lazy var contentScrollerView:UIScrollView = {
        let view = UIScrollView()
        return view
    }()
    
    fileprivate lazy var titleLabel : PTActionCell = {
        let view = PTActionCell()
        view.cellButton.normalTitle = titleItem!.title
        view.cellButton.normalSubTitle = titleItem!.subTitle
        view.cellButton.isUserInteractionEnabled = false
        view.cellButton.normalTitleFont = titleItem!.titleFont!
        view.cellButton.normalTitleColor = titleItem!.titleColor!
        view.cellButton.normalSubTitleFont = titleItem!.titleFont!
        view.cellButton.normalSubTitleColor = titleItem!.titleColor!
        if titleItem!.image != nil {
            switch titleItem!.itemLayout! {
            case .leftImageRightTitle:
                view.cellButton.layoutStyle = .leftImageRightTitle
            case .leftTitleRightImage:
                view.cellButton.layoutStyle = .leftTitleRightImage
            }
            
            var itemSize = CGSizeZero
//            if titleItem!.imageSize.height >= (titleHeight() - 20) {
//                itemSize = CGSizeMake(actionSheetTitleViewItem!.imageSize.width, (titleHeight() - 20))
//            } else {
                itemSize = titleItem!.imageSize
//            }
            view.cellButton.imageSize = itemSize
            view.cellButton.midSpacing = titleItem!.contentImageSpace
            view.cellButton.layoutLoadImage(contentData: titleItem!.image as Any,iCloudDocumentName: titleItem!.iCloudDocumentName)
        }
        view.viewCornerRectCorner(cornerRadii: sheetConfig.cornerRadii,corner: [.topLeft,.topRight])
        return view
    }()
    
    fileprivate lazy var alertContent:UIView = {
        let view = UIView()
        if canTapBackground {
            let tap = UITapGestureRecognizer { ges in
                self.dismissAnimation {
                    self.tapBackgroundBlock?(self)
                }
            }
            view.addGestureRecognizer(tap)
        }
        return view
    }()
    
    fileprivate var canTapBackground:Bool = false

    public init(viewConfig:PTActionSheetViewConfig = PTActionSheetViewConfig(),
                titleItem:PTActionSheetTitleItem? = nil,
                cancelItem:PTActionSheetItem = PTActionSheetItem(title: "PT Button cancel".localized()),
                destructiveItems:[PTActionSheetItem] = [PTActionSheetItem](),
                contentItems:[PTActionSheetItem]? = [PTActionSheetItem](),
                canTapBackground:Bool = false) {
        self.sheetConfig = viewConfig
        self.titleItem = titleItem
        self.cancelSheetItem = cancelItem
        self.destructiveItems = destructiveItems
        self.contentItems = contentItems
        self.canTapBackground = canTapBackground
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubviews([alertContent])
        alertContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // 分离取消按钮的设置
    private func setupCancelButton() {
        alertContent.addSubviews([cancelBtn])
        cancelBtn.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(sheetConfig.viewSpace)
            make.height.equalTo(sheetConfig.rowHeight)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 5)
        }
    }

    // 分离毁灭性项目的设置
    private func setupDestructiveItems() {
        setDestructiveCount(counts: destructiveItems?.count ?? 0)
        
        guard destructiveCount > 0 else { return }
        
        for (index, destructiveItem) in destructiveItems!.enumerated() {
            let destructiveView = createDestructiveView(for: destructiveItem)
            destructiveView.cellButton.addActionHandlers { sender in
                self.dismissAnimation {
                    self.actionSheetDestructiveSelectBlock?(self, index, destructiveItem.title)
                }
            }
            
            alertContent.addSubview(destructiveView)
            let destructiveY = -(sheetConfig.separatorHeight + (sheetConfig.separatorHeight + sheetConfig.rowHeight) * CGFloat(index))
            destructiveView.snp.makeConstraints { make in
                make.left.right.equalTo(cancelBtn)
                make.height.equalTo(sheetConfig.rowHeight)
                make.bottom.equalTo(cancelBtn.snp.top).offset(destructiveY)
            }
        }
    }

    private func createDestructiveView(for item: PTActionSheetItem) -> PTActionCell {
        let destructiveView = PTActionCell()
        destructiveView.cellButton.normalTitle = item.title
        destructiveView.cellButton.normalTitleFont = item.titleFont!
        destructiveView.cellButton.normalTitleColor = item.titleColor!
        destructiveView.cellButton.hightlightTitleFont = item.titleFont!
        destructiveView.cellButton.hightlightTitleColor = item.titleColor!
        destructiveView.cellButton.configBackgroundHightlightColor = item.heightlightColor!
        destructiveView.cellButton.contentHorizontalAlignment = item.itemAlignment!
        
        let contentEdgeValue = item.contentEdgeValue
        switch item.itemAlignment! {
        case .center: break
        case .left, .leading:
            destructiveView.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: contentEdgeValue, bottom: 0, trailing: 0)
        case .right, .trailing:
            destructiveView.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: contentEdgeValue)
        case .fill:
            destructiveView.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: contentEdgeValue, bottom: 0, trailing: contentEdgeValue)
        @unknown default: break
        }
        
        if let image = item.image {
            let imageSize = item.imageSize.height >= (sheetConfig.rowHeight - 20) ? CGSize(width: item.imageSize.width, height: sheetConfig.rowHeight - 20) : item.imageSize
            destructiveView.cellButton.imageSize = imageSize
            destructiveView.cellButton.midSpacing = item.contentImageSpace
            destructiveView.cellButton.layoutLoadImage(contentData: image as Any, iCloudDocumentName: item.iCloudDocumentName)
            destructiveView.cellButton.layoutStyle = item.itemLayout == .leftImageRightTitle ? .leftImageRightTitle : .leftTitleRightImage
        }
        
        destructiveView.viewCornerRectCorner(cornerRadii: sheetConfig.cornerRadii, corner: .allCorners)
        return destructiveView
    }

    // 分离内容滚动视图的设置
    private func setupContentScrollerView() {
        let destructiveHeight = (sheetConfig.separatorHeight + sheetConfig.rowHeight) * CGFloat(destructiveCount)
        let contentItemsBottom: CGFloat = destructiveCount > 0 ? -(destructiveHeight + 10) : -10
        let contentItemsMaxHeight: CGFloat = CGFloat.kSCREEN_HEIGHT - (sheetConfig.rowHeight + CGFloat.kTabbarSaveAreaHeight + 10 + (destructiveHeight < 1 ? 10 : (destructiveHeight + 10)) + CGFloat.statusBarHeight() + 20 + sheetConfig.rowHeight)
        
        let contentItemsCount = CGFloat(contentItems?.count ?? 0)
        let currentContentHeight: CGFloat = contentItemsCount * sheetConfig.rowHeight + (contentItemsCount - 1) * sheetConfig.lineHeight
        var realContentSize: CGFloat = currentContentHeight
        let contentItemCanScroll: Bool = realContentSize > contentItemsMaxHeight
        
        if contentItemCanScroll {
            realContentSize = contentItemsMaxHeight
        }
        
        totalHeight = realContentSize + destructiveHeight + (titleItem == nil ? 0 : sheetConfig.rowHeight) + (destructiveHeight < 1 ? 10 : (destructiveHeight + 10)) + CGFloat.kTabbarSaveAreaHeight + 10
        
        contentScrollerView.contentSize = CGSize(width: CGFloat.kSCREEN_WIDTH - sheetConfig.viewSpace * 2, height: currentContentHeight)
        contentScrollerView.isScrollEnabled = contentItemCanScroll
        alertContent.addSubviews([contentScrollerView])
        contentScrollerView.snp.makeConstraints { make in
            make.left.right.equalTo(cancelBtn)
            make.bottom.equalTo(cancelBtn.snp.top).offset(contentItemsBottom)
            make.height.equalTo(realContentSize)
        }
    }

    // 分离标题标签的设置
    private func setupTitleLabel() {
        guard titleItem != nil else { return }
        
        alertContent.addSubviews([titleLabel])
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(cancelBtn)
            make.height.equalTo(sheetConfig.rowHeight)
            make.bottom.equalTo(contentScrollerView.snp.top)
        }
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
        self.view.backgroundColor = UIColor.DevMaskColor
        
        PTGCDManager.gcdMain {
            self.setupCancelButton()
            self.setupDestructiveItems()
            self.setupContentScrollerView()
            self.setupTitleLabel()
            self.contentSubsSet()
        }
        PTAnimationFunction.animationIn(animationView: alertContent, animationType: .Bottom, transformValue: CGFloat.kSCREEN_HEIGHT) { anim, finish in
            if finish {
                completion?()
            }
        }
    }
    
    public override func dismissAnimation(completion: (() -> Void)?) {
        PTAnimationFunction.animationOut(animationView: alertContent, animationType: .Bottom,duration: 0.55) {
            self.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00)
        } completion: { ok in
            if ok {
                PTAlertManager.dismissAll()
                completion?()
            }
        }
    }
}
