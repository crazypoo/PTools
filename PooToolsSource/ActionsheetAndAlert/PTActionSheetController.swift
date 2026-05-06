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
public typealias PTActionSheetIndexCallback = (_ sheet:PTActionSheetController, _ index:Int,_ title:String) -> Void

public class PTActionCell:UIView {
        
    private lazy var blur:SSBlurView = {
        let blurs = SSBlurView(to: self)
        blurs.alpha = 0.9
        blurs.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
        return blurs
    }()
    
    lazy var cellButton : PTActionLayoutButton = {
        let view = PTActionLayoutButton()
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
    
    public init(@PTClampedPropertyWrapper(range:0.1...0.5) lineHeight: CGFloat = 0.5,
                @PTClampedPropertyWrapper(range:44...74) rowHeight: CGFloat = 54,
                @PTClampedPropertyWrapper(range:1...10) separatorHeight: CGFloat = 5,
                @PTClampedPropertyWrapper(range:10...50) viewSpace: CGFloat = 10,
                @PTClampedPropertyWrapper(range:0...15) cornerRadii: CGFloat = 15,
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
        let cell = createActionCell(for: cancelSheetItem, withCorner: true) { [weak self] in
            self?.dismissAnimation {
                guard let SELF = self else { return }
                self?.actionSheetCancelSelectBlock?(SELF)
            }
        }
        cell.superGradient(radius:sheetConfig.cornerRadii, corner: .allCorners)
        return cell
    }()
    
    fileprivate func setDestructiveCount(@PTClampedPropertyWrapper(range:0...5) counts:Int = 0) {
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
        view.superGradient(topLeft: sheetConfig.cornerRadii,topRight: sheetConfig.cornerRadii, corner: [.topLeft,.topRight])
        return view
    }()
    
    fileprivate lazy var alertContent:UIView = {
        let view = UIView()
        if canTapBackground {
            let tap = UITapGestureRecognizer { _ in
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
        
        view.addSubviews([alertContent])
        alertContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.setupCancelButton()
        if !self.destructiveItems.isEmpty {
            self.setupDestructiveItems()
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

    // 分离Destructive的设置
    private func setupDestructiveItems() {
        setDestructiveCount(counts: destructiveItems.count)
        
        guard destructiveCount > 0 else { return }
        
        for (index, destructiveItem) in destructiveItems.enumerated() {
            let destructiveView = createActionCell(for: destructiveItem,withCorner: true) { [weak self] in
                self?.dismissAnimation {
                    guard let SELF = self else { return }
                    self?.actionSheetDestructiveSelectBlock?(SELF, index, destructiveItem.title)
                }
            }
            
            alertContent.addSubview(destructiveView)
            let destructiveY = -(sheetConfig.separatorHeight + (sheetConfig.separatorHeight + sheetConfig.rowHeight) * CGFloat(index))
            destructiveView.snp.makeConstraints { make in
                make.left.right.equalTo(cancelBtn)
                make.height.equalTo(sheetConfig.rowHeight)
                make.bottom.equalTo(cancelBtn.snp.top).offset(destructiveY)
            }
            destructiveView.superGradient(radius:sheetConfig.cornerRadii,corner: .allCorners)
        }
    }

    private func createActionCell(for item: PTActionSheetItem, withCorner: Bool, isTitle: Bool = false, action: PTActionTask?) -> PTActionCell {
        
        let cell = PTActionCell()
        let btn = cell.cellButton
        btn.setTitle(item.title, state: .normal)
        btn.setTitleFont(item.titleFont, state: .normal)
        btn.setTitleColor(item.titleColor, state: .normal)
        btn.setTitleFont(item.titleFont, state: .highlighted)
        btn.setTitleColor(item.titleColor, state: .highlighted)
        btn.setBackgroundColor(item.heightlightColor, state: .highlighted)

        let edge = item.contentEdgeValue
        btn.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            switch item.itemAlignment {
            case .left, .leading:
                make.left.equalToSuperview().inset(edge)
            case .right, .trailing:
                make.right.equalToSuperview().inset(edge)
            case .fill:
                make.left.right.equalToSuperview().inset(edge)
            default:
                make.left.right.equalToSuperview()
            }
        }
        
        var showStyle:PTLayoutButtonStyle = .image
        if let image = item.image {
            let maxHeight = sheetConfig.rowHeight - 20
            let size = item.imageSize.height > maxHeight ? CGSize(width: item.imageSize.width, height: maxHeight) : item.imageSize
            btn.imageSize = size
            btn.midSpacing = item.contentImageSpace
            if item.title.stringIsEmpty() {
                showStyle = .image
            } else {
                showStyle = item.itemLayout == .leftImageRightTitle ? .leftImageRightTitle : .leftTitleRightImage
            }
            btn.setImage(image, state: .normal)
        } else {
            showStyle = .title
        }
        btn.layoutStyle = showStyle
        btn.isUserInteractionEnabled = false
        if withCorner {
            if isTitle {
                cell.viewCornerRectCorner(topLeft: sheetConfig.cornerRadii,topRight: sheetConfig.cornerRadii, corner: [.topLeft,.topRight])
            } else {
                cell.viewCornerRectCorner(radius: sheetConfig.cornerRadii, corner: .allCorners)
            }
        }

        if let action = action {
            let tap = UITapGestureRecognizer { _ in action() }
            cell.addGestureRecognizer(tap)
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
        var previousView: UIView?
        let lastIndex = contentItems.count - 1

        for index in contentItems.indices {
            let item = contentItems[index]
            
            // --- 分隔线部分保持你的原样 ---
            if index != 0 {
                let line = UIView()
                line.backgroundColor = .lightGray
                contentScrollerView.addSubview(line)
                line.snp.makeConstraints { make in
                    make.width.equalTo(CGFloat.kSCREEN_WIDTH - sheetConfig.viewSpace * 2)
                    make.centerX.equalToSuperview()
                    make.height.equalTo(sheetConfig.lineHeight)
                    if let prev = previousView {
                        make.top.equalTo(prev.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                }
                previousView = line
            }
            
            // --- 按钮部分 ---
            let button = createActionCell(for: item, withCorner: false) { [weak self] in
                self?.dismissAnimation {
                    guard let self else { return }
                    self.actionSheetSelectBlock?(self, index, item.title)
                }
            }
            contentScrollerView.addSubview(button)
            
            // --- 约束部分（修复坑3：为最后一个元素封底） ---
            button.snp.makeConstraints { make in
                make.width.equalTo(CGFloat.kSCREEN_WIDTH - sheetConfig.viewSpace * 2)
                make.centerX.equalToSuperview()
                make.height.equalTo(sheetConfig.rowHeight)
                make.top.equalTo(previousView?.snp.bottom ?? contentScrollerView.snp.top)
                
                // 🌟 关键：如果是最后一个元素，必须加上 bottom 约束，撑开 ScrollView！
                if index == lastIndex {
                    make.bottom.equalToSuperview()
                }
            }
            
            // --- Corner 处理（修复坑1和坑2） ---
            let isFirst = (titleItem == nil && index == 0)
            let isLast = (index == lastIndex)
            
            if isFirst && isLast {
                // 只有 1 个 Item：四角全部变圆
                button.viewCornerRectCorner(radius: sheetConfig.cornerRadii, corner: .allCorners)
            } else if isFirst {
                // 第 1 个 Item：仅顶部圆角
                button.viewCornerRectCorner(radius: 0, // 全局设0，独立设值
                                            topLeft: sheetConfig.cornerRadii,
                                            topRight: sheetConfig.cornerRadii,
                                            corner: [.topLeft, .topRight])
            } else if isLast {
                // 最后 1 个 Item：仅底部圆角
                button.viewCornerRectCorner(radius: 0,
                                            bottomLeft: sheetConfig.cornerRadii,
                                            bottomRight: sheetConfig.cornerRadii,
                                            corner: [.bottomLeft, .bottomRight])
            } else {
                // 中间的 Item：无圆角，清理一下避免复用问题
                button.layer.mask = nil
            }
            
            previousView = button
        }
    }
}

extension PTActionSheetController {
    public override func showAnimation(completion: PTActionTask?) {
        // 1. 强制刷新布局，确保所有 bounds 已经就位
        view.layoutIfNeeded()
        
        // 2. 将内容直接推到屏幕最底部之外 (使用 view 的高度最保险)
        alertContent.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        
        // 3. 使用 Spring 动画 (阻尼回弹效果)
        UIView.animate(withDuration: 0.45,
                       delay: 0,
                       usingSpringWithDamping: 0.85, // 阻尼系数：越接近 1 越不弹，0.85 是一个很舒适的微弹效果
                       initialSpringVelocity: 0.8,   // 初始速度
                       options: [.curveEaseOut, .allowUserInteraction],
                       animations: {
            self.view.backgroundColor = UIColor.DevMaskColor
            self.alertContent.transform = .identity
        }, completion: { _ in
            completion?()
        })
    }
    
    public override func dismissAnimation(completion: PTActionTask?) {
        // 收回动画不需要弹簧效果，要求干脆利落，时间更短
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: .curveEaseIn, // 渐入加速退出
                       animations: {
            self.view.backgroundColor = .clear
            self.alertContent.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        }, completion: { _ in
            PTAlertManager.dismissAll()
            completion?()
        })
    }
}
