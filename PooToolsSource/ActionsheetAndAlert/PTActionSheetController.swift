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
        let blurs = SSBlurView(to: self)
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
                self.blurChange(style: previousTraitCollection.userInterfaceStyle)
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
        
        if #available(iOS 18.0, *) {
            blurChange(style: traitCollection.userInterfaceStyle)
        }
    }
    
    @available(iOS, introduced: 8.0, deprecated: 17.0,message: "17後不再支持了")
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // 适配代码
            blurChange(style: UITraitCollection.current.userInterfaceStyle)
        }
    }
    
    func blurChange(style:UIUserInterfaceStyle) {
        blur.style = style == .dark ? .extraLight : .dark
    }
}

@objc public enum PTSheetButtonStyle: Int {
    case leftImageRightTitle,leftTitleRightImage
}

@objcMembers
public class PTActionSheetItem:NSObject {
    public var title:String = ""
    public var titleColor:UIColor = .systemBlue
    public var titleFont:UIFont = .systemFont(ofSize: 20)
    public var image:Any?
    public var imageSize:CGSize = CGSizeMake(34, 34)
    public var iCloudDocumentName:String = ""
    public var heightlightColor:UIColor = .lightGray
    public var itemAlignment:UIControl.ContentHorizontalAlignment = .center
    public var itemLayout:PTSheetButtonStyle = .leftImageRightTitle
    public var contentEdgeValue:CGFloat = 20
    public var contentImageSpace:CGFloat = 15

    public init(title: String,
                titleColor: UIColor = .systemBlue,
                titleFont: UIFont = .systemFont(ofSize: 20),
                image: Any? = nil,
                imageSize:CGSize = CGSizeMake(34, 34),
                iCloudDocumentName:String = "",
                heightlightColor: UIColor = .lightGray,
                itemAlignment: UIControl.ContentHorizontalAlignment = .center,
                itemLayout:PTSheetButtonStyle = .leftImageRightTitle,
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
public class PTActionSheetTitleItem:PTActionSheetItem {
    public var subTitle:String = ""

    public init(title: String = "",
                subTitle: String = "",
                titleFont: UIFont = .systemFont(ofSize: 16),
                titleColor: UIColor = .systemGray,
                image: Any? = nil,
                imageSize:CGSize = CGSizeMake(34, 34),
                iCloudDocumentName:String = "",
                itemLayout:PTSheetButtonStyle = .leftImageRightTitle,
                contentImageSpace:CGFloat = 15) {
        self.subTitle = subTitle
        super.init(title: title,titleColor: titleColor,titleFont: titleFont,image: image,imageSize: imageSize,iCloudDocumentName: iCloudDocumentName,itemLayout: itemLayout,contentImageSpace: contentImageSpace)
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
    
    public var actionSheetCancelSelectBlock: PTActionSheetCallback?
    public var actionSheetDestructiveSelectBlock: PTActionSheetIndexCallback?
    public var actionSheetSelectBlock: PTActionSheetIndexCallback?
    public var tapBackgroundBlock: PTActionSheetCallback?

    private var cancelSheetItem: PTActionSheetItem
    private var destructiveItems: [PTActionSheetItem]
    private var contentItems: [PTActionSheetItem]
    private var sheetConfig: PTActionSheetViewConfig
    private var titleItem: PTActionSheetTitleItem?
    private var canTapBackground: Bool

    private lazy var cancelBtn : PTActionCell = {
        createActionCell(for: cancelSheetItem, withCorner: true) { [weak self] in
            self?.dismissAnimation {
                self?.actionSheetCancelSelectBlock?(self!)
            }
        }
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
    
    fileprivate lazy var titleLabel : PTActionCell? = {
        guard let item = titleItem else { return nil }
        let view = createActionCell(for: item, withCorner: true, isTitle: true, action: nil)
        view.cellButton.isUserInteractionEnabled = false
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
        self.contentItems = contentItems ?? []
        self.canTapBackground = canTapBackground
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupCancelButton()
        view.addSubviews([alertContent])
        alertContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if !destructiveItems.isEmpty {
            setupDestructiveItems()
        }
        
        self.setupContentScrollerView()
        self.setupTitleLabel()
        self.contentSubsSet()
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
        setDestructiveCount(counts: destructiveItems.count)
        
        guard destructiveCount > 0 else { return }
        
        for (index, destructiveItem) in destructiveItems.enumerated() {
            let destructiveView = createActionCell(for: destructiveItem,withCorner: true) { [weak self] in
                self?.dismissAnimation {
                    self?.actionSheetDestructiveSelectBlock?(self!, index, destructiveItem.title)
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

    private func createActionCell(for item: PTActionSheetItem, withCorner: Bool, isTitle: Bool = false, action: PTActionTask?) -> PTActionCell {
        
        let cell = PTActionCell()
        let btn = cell.cellButton
        btn.normalTitle = item.title
        btn.normalTitleFont = item.titleFont
        btn.normalTitleColor = item.titleColor
        btn.hightlightTitleFont = btn.normalTitleFont
        btn.hightlightTitleColor = btn.normalTitleColor
        btn.configBackgroundHightlightColor = item.heightlightColor
        btn.contentHorizontalAlignment = item.itemAlignment

        let edge = item.contentEdgeValue
        switch item.itemAlignment {
        case .left, .leading:
            btn.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: edge, bottom: 0, trailing: 0)
        case .right, .trailing:
            btn.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: edge)
        case .fill:
            btn.contentEdges = NSDirectionalEdgeInsets(top: 0, leading: edge, bottom: 0, trailing: edge)
        default:
            break
        }

        if let image = item.image {
            let maxHeight = sheetConfig.rowHeight - 20
            let size = item.imageSize.height > maxHeight ? CGSize(width: item.imageSize.width, height: maxHeight) : item.imageSize
            btn.imageSize = size
            btn.midSpacing = item.contentImageSpace
            btn.layoutStyle = item.itemLayout == .leftImageRightTitle ? .leftImageRightTitle : .leftTitleRightImage
            btn.layoutLoadImage(contentData: image, iCloudDocumentName: item.iCloudDocumentName)
        }

        if withCorner {
            if isTitle {
                cell.viewCornerRectCorner(cornerRadii: sheetConfig.cornerRadii, corner: [.topLeft,.topRight])
            } else {
                cell.viewCornerRectCorner(cornerRadii: sheetConfig.cornerRadii, corner: .allCorners)
            }
        }

        if let action = action {
            btn.addActionHandlers { _ in action() }
        }

        return cell

    }

    /// 分离内容滚动视图的设置
    private func setupContentScrollerView() {
        let destructiveHeight = (sheetConfig.separatorHeight + sheetConfig.rowHeight) * CGFloat(destructiveCount)
        let destructiveSpacing: CGFloat = 10
        let destructivePadding = destructiveHeight + destructiveSpacing
        let tabbarPadding = CGFloat.kTabbarSaveAreaHeight + destructiveSpacing

        // 提取變量
        let titleHeight: CGFloat = titleItem == nil ? 0 : sheetConfig.rowHeight
        let statusBarHeight = CGFloat.statusBarHeight()

        // 計算 destructive 高度和 contentItems 底部偏移
        let contentItemsBottom = destructiveCount > 0 ? -destructivePadding : -destructiveSpacing

        // 最大可用內容高度
        let contentItemsMaxHeight: CGFloat = CGFloat.kSCREEN_HEIGHT - (sheetConfig.rowHeight + tabbarPadding + (destructiveHeight < 1 ? destructiveSpacing : destructivePadding) + statusBarHeight + 20 + sheetConfig.rowHeight)

        // 內容項高度計算
        let contentItemsCount = CGFloat(contentItems.count)
        let currentContentHeight = contentItemsCount * sheetConfig.rowHeight + (contentItemsCount - 1) * sheetConfig.lineHeight

        // 計算是否可以滾動
        let realContentSize = min(currentContentHeight, contentItemsMaxHeight)
        let contentItemCanScroll = currentContentHeight > contentItemsMaxHeight

        // 計算總高度
        totalHeight = realContentSize + destructiveHeight + titleHeight + (destructiveHeight < 1 ? destructiveSpacing : destructivePadding) + tabbarPadding

        // 設置 ScrollerView
        contentScrollerView.contentSize = CGSize(width: CGFloat.kSCREEN_WIDTH - sheetConfig.viewSpace * 2, height: currentContentHeight)
        contentScrollerView.isScrollEnabled = contentItemCanScroll

        // 添加子視圖和佈局約束
        alertContent.addSubviews([contentScrollerView])

        contentScrollerView.snp.makeConstraints { make in
            make.left.right.equalTo(cancelBtn)
            make.bottom.equalTo(cancelBtn.snp.top).offset(contentItemsBottom)
            make.height.equalTo(realContentSize)
        }
    }

    // 分离标题标签的设置
    private func setupTitleLabel() {
        if let titleView = titleLabel {
            alertContent.addSubview(titleView)
            titleView.snp.makeConstraints { make in
                make.left.right.equalTo(cancelBtn)
                make.height.equalTo(sheetConfig.rowHeight)
                make.bottom.equalTo(contentScrollerView.snp.top)
            }
        }
    }

    func contentSubsSet() {
        guard !contentItems.isEmpty else { return }

        let lastIndex = contentItems.count - 1

        contentItems.enumerated().forEach { index, item in
            let yOffset = sheetConfig.rowHeight * CGFloat(index) + sheetConfig.lineHeight * CGFloat(index)

            // 分隔線
            let lineView = UIView()
            lineView.backgroundColor = .lightGray
            contentScrollerView.addSubview(lineView)
            lineView.snp.makeConstraints { make in
                make.height.equalTo(sheetConfig.lineHeight)
                make.width.equalTo(CGFloat.kSCREEN_WIDTH - sheetConfig.viewSpace * 2)
                make.centerX.equalToSuperview()
                make.top.equalTo(yOffset)
            }

            // 按鈕
            let button = createActionCell(for: item, withCorner: false) { [weak self] in
                self?.dismissAnimation {
                    self?.actionSheetSelectBlock?(self!, index, item.title)
                }
            }
            contentScrollerView.addSubview(button)
            button.snp.makeConstraints { make in
                make.left.right.equalTo(lineView)
                make.top.equalTo(lineView.snp.bottom)
                make.height.equalTo(sheetConfig.rowHeight)
            }

            // Corner 處理
            if titleItem == nil, index == 0 {
                lineView.isHidden = true
                PTGCDManager.gcdAfter(time: 0.1) {
                    button.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: [.topLeft, .topRight])
                }
            }

            if index == lastIndex {
                PTGCDManager.gcdAfter(time: 0.1) {
                    button.viewCornerRectCorner(cornerRadii: self.sheetConfig.cornerRadii, corner: [.bottomLeft, .bottomRight])
                }
            }
        }
    }
}

extension PTActionSheetController {
    public override func showAnimation(completion: PTActionTask?) {
        self.view.backgroundColor = UIColor.DevMaskColor
        PTGCDManager.gcdMain {
            PTAnimationFunction.animationIn(animationView: self.alertContent, animationType: .Bottom, transformValue: CGFloat.kSCREEN_HEIGHT) { anim, finish in
                if finish {
                    completion?()
                }
            }
        }
    }
    
    public override func dismissAnimation(completion: PTActionTask?) {
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
