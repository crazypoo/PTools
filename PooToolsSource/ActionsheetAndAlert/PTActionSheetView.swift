//
//  PTActionSheetView.swift
//  Diou
//
//  Created by ken lam on 2021/10/19.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import pop
import SnapKit
import AttributedString

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
                self.blur.style = previousTraitCollection.userInterfaceStyle == .dark ? .dark : .extraLight
            }
        }
        addSubview(cellButton)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        cellButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        blur.enable()
    }
    
    @available(iOS, introduced: 8.0, deprecated: 17.0,message: "17後不再支持了")
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // 适配代码
            blur.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
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

@objcMembers
public class PTActionSheetView: UIView {
    
    public var actionSheetSelectBlock:PTActionSheetIndexHandler?
    public var actionSheetTapDismissBlock:PTActionSheetHandler?
    public var actionSheetDestructiveSelectBlock:PTActionSheetIndexHandler?
    public var actionSheetCancelSelectBlock:PTActionSheetHandler?
    
    private var sheetConfig:PTActionSheetViewConfig = PTActionSheetViewConfig()
    private var actionSheetTitleViewItem:PTActionSheetTitleItem?
    private var cancelSheetItem:PTActionSheetItem!
    private var destructiveSheetItems:[PTActionSheetItem] = [PTActionSheetItem]() {
        didSet {
            setDestructiveCount(counts: destructiveSheetItems.count)
        }
    }
    private var contentSheetItems:[PTActionSheetItem] = [PTActionSheetItem]()
    private lazy var backgroundView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.DevMaskColor
        return view
    }()
    private lazy var actionSheetView : UIView = {
        let view = UIView()
        return view
    }()
    private lazy var actionSheetScroll : UIScrollView = {
        let view = UIScrollView()
        return view
    }()
    private lazy var titleLbale : PTActionCell = {
        let view = PTActionCell()
        view.cellButton.isUserInteractionEnabled = false
        view.cellButton.normalTitleFont = actionSheetTitleViewItem!.titleFont!
        view.cellButton.normalTitleColor = actionSheetTitleViewItem!.titleColor!
        view.cellButton.normalSubTitleFont = actionSheetTitleViewItem!.titleFont!
        view.cellButton.normalSubTitleColor = actionSheetTitleViewItem!.titleColor!
        if actionSheetTitleViewItem!.image != nil {
            switch actionSheetTitleViewItem!.itemLayout! {
            case .leftImageRightTitle:
                view.cellButton.layoutStyle = .leftImageRightTitle
            case .leftTitleRightImage:
                view.cellButton.layoutStyle = .leftTitleRightImage
            }
            
            var itemSize = CGSizeZero
            if actionSheetTitleViewItem!.imageSize.height >= (titleHeight() - 20) {
                itemSize = CGSizeMake(actionSheetTitleViewItem!.imageSize.width, (titleHeight() - 20))
            } else {
                itemSize = actionSheetTitleViewItem!.imageSize
            }
            view.cellButton.imageSize = itemSize
            view.cellButton.midSpacing = actionSheetTitleViewItem!.contentImageSpace
            view.cellButton.layoutLoadImage(contentData: actionSheetTitleViewItem!.image as Any,iCloudDocumentName: actionSheetTitleViewItem!.iCloudDocumentName)
        }

        return view
    }()
    private lazy var cancelBtn : PTActionCell = {
        let view = PTActionCell()
        view.cellButton.addActionHandlers(handler: { (sender) in
            self.dismiss {
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
        return view
    }()
    private func setDestructiveCount(@PTClampedProperyWrapper(range:0...5) counts:Int = 0) {
        destructiveCount = counts
    }
    private var destructiveCount:Int = 0
    private lazy var destructiveView : UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    //MARK: 初始化創建Actionsheet
    ///初始化創建Actionsheet
    /// - Parameters:
    ///   - viewConfig: 界面配置
    ///   - titleItem: 標題
    ///   - cancelItem: 取消按鈕
    ///   - destructiveItems: 額外按鈕(s)最多5个
    ///   - contentItems: 其他按鈕(s)
    ///   - corner: 邊框角弧度最大15
    ///   - dismissWithTapBG: 是否支持點擊背景消失Alert
    public init(viewConfig:PTActionSheetViewConfig = PTActionSheetViewConfig(),
                titleItem:PTActionSheetTitleItem? = nil,
                cancelItem:PTActionSheetItem = PTActionSheetItem(title: "PT Button cancel".localized()),
                destructiveItems:[PTActionSheetItem] = [PTActionSheetItem](),
                contentItems:[PTActionSheetItem]? = [PTActionSheetItem]()) {
        super.init(frame: .zero)
        sheetConfig = viewConfig
        createData(titleItem: titleItem,
                   cancelItem: cancelItem,
                   destructiveItems: destructiveItems,
                   contentItems: contentItems!,
                   corner: sheetConfig.cornerRadii)
        createView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createData(titleItem:PTActionSheetTitleItem?,
                    cancelItem:PTActionSheetItem,
                    destructiveItems:[PTActionSheetItem],
                    contentItems:[PTActionSheetItem],
                    corner:CGFloat) {
        actionSheetTitleViewItem = titleItem
        cancelSheetItem = cancelItem
        destructiveSheetItems = destructiveItems
        contentSheetItems = contentItems
    }
    
    func createView() {
        UIApplication.shared.delegate!.window!!.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(backgroundView)
        addSubview(actionSheetView)
        actionSheetView.addSubview(actionSheetScroll)
        
        if actionSheetTitleViewItem != nil {
            titleLbale.cellButton.normalTitle = actionSheetTitleViewItem!.title
            titleLbale.cellButton.normalSubTitle = actionSheetTitleViewItem!.subTitle
            actionSheetView.addSubview(titleLbale)
        }
                
        if destructiveCount != 0 {
            actionSheetView.addSubview(destructiveView)
        }
        
        actionSheetView.addSubview(cancelBtn)
    }
    
    func destlineH()->CGFloat {
        destructiveCount != 0 ? sheetConfig.lineHeight : 0
    }
    
    func destRowH()->CGFloat {
        destructiveCount != 0 ? sheetConfig.rowHeight * CGFloat(destructiveCount) + CGFloat(destructiveCount - 1) * (sheetConfig.separatorHeight / 2) : 0
    }
    
    func titleHeight()->CGFloat {
        
        var titleH:CGFloat = 0
        var subTitleH:CGFloat = 0
        if actionSheetTitleViewItem != nil {
            if !actionSheetTitleViewItem!.title.stringIsEmpty() {
                titleH = UIView.sizeFor(string: actionSheetTitleViewItem!.title, font: actionSheetTitleViewItem!.titleFont!, width: CGFloat.kSCREEN_WIDTH - sheetConfig.viewSpace * 2).height
            }
            
            if !actionSheetTitleViewItem!.subTitle.stringIsEmpty() {
                subTitleH = UIView.sizeFor(string: actionSheetTitleViewItem!.subTitle, font: actionSheetTitleViewItem!.titleFont!, width: CGFloat.kSCREEN_WIDTH - sheetConfig.viewSpace * 2).height
            }
        }
                
        var total:CGFloat = 0
        if titleH > 0 || subTitleH > 0 {
            total = titleH + subTitleH + 50
        }
        
        return total
    }
    
    func scrollContentHeight()->CGFloat {
        let realH = CGFloat(contentSheetItems.count) * sheetConfig.rowHeight + sheetConfig.lineHeight * CGFloat(contentSheetItems.count)
        return realH
    }
    
    func actionSheetRealHeight()->CGFloat {
        scrollContentHeight() + (titleHeight() + sheetConfig.lineHeight) + (sheetConfig.separatorHeight + sheetConfig.rowHeight) + destRowH() + destlineH() + sheetConfig.lineHeight * 2
    }
    
    func actionSheetHeight(orientation:UIDeviceOrientation)->CGFloat {
        let realH = actionSheetRealHeight()
        let canshowViewH:CGFloat = CGFloat.kSCREEN_HEIGHT - CGFloat.kTabbarSaveAreaHeight - CGFloat.statusBarHeight() - 10
        if actionSheetRealHeight() >= canshowViewH {
            return canshowViewH
        } else {
            return realH
        }
    }
    
    func scrollHieght(orientation:UIDeviceOrientation)->CGFloat {
        let a:CGFloat = actionSheetHeight(orientation: orientation)
        let b:CGFloat = CGFloat.kSCREEN_HEIGHT
        if (a - b) <= 0 {
            return a - (titleHeight() + sheetConfig.lineHeight) - (sheetConfig.separatorHeight + sheetConfig.rowHeight) - (destRowH() + destlineH() + sheetConfig.lineHeight * 2)
        } else {
            return scrollContentHeight()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let device = UIDevice.current
        
        actionSheetView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(self.sheetConfig.viewSpace)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
            make.height.equalTo(self.actionSheetHeight(orientation: device.orientation))
        }
        
        cancelBtn.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(self.sheetConfig.rowHeight)
        }
        
        if destructiveCount != 0 {
            destructiveView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(cancelBtn.snp.top).offset(-(self.sheetConfig.separatorHeight / 2))
                make.height.equalTo(CGFloat(self.destructiveCount) * self.sheetConfig.rowHeight + CGFloat(self.destructiveCount - 1) * (self.sheetConfig.separatorHeight / 2))
            }
            
            for i in 0..<destructiveCount {
                let destructiveItem = destructiveSheetItems[i]
                let view = PTActionCell()
                view.cellButton.normalTitle = destructiveItem.title
                view.cellButton.normalTitleFont = destructiveItem.titleFont!
                view.cellButton.normalTitleColor = destructiveItem.titleColor!
                view.cellButton.hightlightTitleFont = destructiveItem.titleFont!
                view.cellButton.hightlightTitleColor = destructiveItem.titleColor!
                view.cellButton.configBackgroundHightlightColor = destructiveItem.heightlightColor!
                view.cellButton.contentHorizontalAlignment = destructiveItem.itemAlignment!
                switch destructiveItem.itemAlignment! {
                case .center:
                    break
                case .left,.leading:
                    view.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: destructiveItem.contentEdgeValue, bottom: 0, trailing: 0)
                case .right,.trailing:
                    view.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: destructiveItem.contentEdgeValue)
                case .fill:
                    view.cellButton.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: destructiveItem.contentEdgeValue, bottom: 0, trailing: destructiveItem.contentEdgeValue)
                @unknown default:
                    break
                }
                if destructiveItem.image != nil {
                    switch destructiveItem.itemLayout! {
                    case .leftImageRightTitle:
                        view.cellButton.layoutStyle = .leftImageRightTitle
                    case .leftTitleRightImage:
                        view.cellButton.layoutStyle = .leftTitleRightImage
                    }
                    
                    var itemSize = CGSizeZero
                    if destructiveItem.imageSize.height >= (sheetConfig.rowHeight - 20) {
                        itemSize = CGSizeMake(destructiveItem.imageSize.width, sheetConfig.rowHeight - 20)
                    } else {
                        itemSize = destructiveItem.imageSize
                    }
                    view.cellButton.imageSize = itemSize
                    view.cellButton.midSpacing = destructiveItem.contentImageSpace
                    view.cellButton.layoutLoadImage(contentData: destructiveItem.image as Any,iCloudDocumentName: destructiveItem.iCloudDocumentName)
                }
                view.cellButton.addActionHandlers { sender in
                    self.dismiss {
                        if self.actionSheetDestructiveSelectBlock != nil {
                            self.actionSheetDestructiveSelectBlock!(self,i,destructiveItem.title)
                        }
                    }
                }
                destructiveView.addSubview(view)
                view.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.height.equalTo(self.sheetConfig.rowHeight)
                    make.top.equalTo(self.sheetConfig.rowHeight * CGFloat(i) + (self.sheetConfig.separatorHeight / 2) * CGFloat(i))
                }
                
                PTGCDManager.gcdAfter(time: 0.1) {
                    view.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: .allCorners)
                }
            }
        }

        if actionSheetTitleViewItem != nil {
            titleLbale.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(self.titleHeight())
            }
            
            if destructiveCount != 0 {
                actionSheetScroll.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(titleLbale.snp.bottom).offset(self.sheetConfig.lineHeight)
                    make.height.equalTo(self.scrollHieght(orientation: device.orientation))
                    make.bottom.equalTo(destructiveView.snp.top).offset(-(self.sheetConfig.separatorHeight + self.sheetConfig.lineHeight))
                }
            } else {
                actionSheetScroll.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(titleLbale.snp.bottom).offset(self.sheetConfig.lineHeight)
                    make.height.equalTo(self.scrollHieght(orientation: device.orientation))
                    make.bottom.equalToSuperview().inset((self.sheetConfig.rowHeight + self.sheetConfig.separatorHeight + self.sheetConfig.lineHeight))
                }
            }

            PTGCDManager.gcdAfter(time: 0.1) {
                if self.contentSheetItems.count == 0 {
                    self.titleLbale.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: [.allCorners])
                } else {
                    self.titleLbale.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: [.topLeft,.topRight])
                }
            }
        } else {
            if destructiveCount != 0 {
                actionSheetScroll.snp.makeConstraints { make in
                    make.left.right.top.equalToSuperview()
                    make.height.equalTo(self.scrollHieght(orientation: device.orientation))
                    make.bottom.equalTo(destructiveView.snp.top).offset(-(self.sheetConfig.separatorHeight + self.sheetConfig.lineHeight))
                }
            } else {
                actionSheetScroll.snp.makeConstraints { make in
                    make.left.right.top.equalToSuperview()
                    make.height.equalTo(self.scrollHieght(orientation: device.orientation))
                    make.bottom.equalToSuperview().inset((self.sheetConfig.rowHeight + self.sheetConfig.separatorHeight + self.sheetConfig.lineHeight))
                }
            }
        }
        
        let contentW : CGFloat = CGFloat.kSCREEN_WIDTH - sheetConfig.viewSpace * 2
        actionSheetScroll.contentSize = CGSize.init(width: contentW, height: scrollContentHeight())
        actionSheetScroll.showsVerticalScrollIndicator = false
        actionSheetScroll.isScrollEnabled = scrollContentHeight() > scrollHieght(orientation: device.orientation) ? true : false
                
        if contentSheetItems.count > 0 {
            contentSheetItems.enumerated().forEach({ (index,value) in
                let lineView = UIView()
                lineView.backgroundColor = .lightGray
                actionSheetScroll.addSubview(lineView)
                lineView.snp.makeConstraints { make in
                    make.height.equalTo(self.sheetConfig.lineHeight)
                    make.width.equalTo(CGFloat.kSCREEN_WIDTH - self.sheetConfig.viewSpace * 2)
                    make.centerX.equalToSuperview()
                    make.top.equalTo(self.sheetConfig.rowHeight * CGFloat(index) + self.sheetConfig.lineHeight * CGFloat(index))
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
                    self.dismiss {
                        if self.actionSheetSelectBlock != nil {
                            self.actionSheetSelectBlock!(self,index,value.title)
                        }
                    }
                }
                actionSheetScroll.addSubview(btn)
                
                btn.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.left.right.equalTo(lineView)
                    make.top.equalTo(lineView.snp.bottom)
                    make.height.equalTo(self.sheetConfig.rowHeight)
                }
                
                if actionSheetTitleViewItem == nil {
                    if index == 0 {
                        lineView.isHidden = true
                        PTGCDManager.gcdAfter(time: 0.1) {
                            btn.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: [.topLeft,.topRight])
                        }
                    }
                }
                
                if index == (contentSheetItems.count - 1) {
                    PTGCDManager.gcdAfter(time: 0.1) {
                        btn.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: [.bottomLeft,.bottomRight])
                    }
                }
            })
        }
                        
        PTGCDManager.gcdAfter(time: 0.1) {
            self.cancelBtn.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: .allCorners)
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let view = touches.first
        let point = view!.location(in: backgroundView)
        if !actionSheetView.frame.contains(point) {
            if sheetConfig.dismissWithTapBG {
                dismiss {
                    if self.actionSheetTapDismissBlock != nil {
                        self.actionSheetTapDismissBlock!(self)
                    }
                }
            }
        }
    }
    
    public func dismiss(block:PTActionTask?) {
        
        PTAnimationFunction.animationOut(animationView: actionSheetView, animationType: .Bottom) {
            self.backgroundView.alpha = 0
        } completion: { ok in
            self.removeFromSuperview()
            if block != nil {
                block!()
            }
        }
    }
    
    public func show() {
        PTAnimationFunction.animationIn(animationView: actionSheetView, animationType: .Bottom, transformValue: actionSheetRealHeight())
    }    
}
