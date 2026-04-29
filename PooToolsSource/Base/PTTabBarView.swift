//
//  PTTabBarView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Lottie
import SnapKit
import SwifterSwift
import DeviceKit

public enum PTTabBarLayoutStyle {
    case normal
    case centerRaised
}

public protocol PTTabBarItemContent {
    var view: UIView { get }
    func setSelected(_ selected: Bool, animated: Bool)
}

public struct PTTabBarItemConfig {
    let title: String
    let content: PTTabBarItemContent
    let viewController: UIViewController
    
    public init(title: String,
                content: PTTabBarItemContent,
                viewController: UIViewController) {
        self.title = title
        self.content = content
        self.viewController = viewController
    }
}

final public class PTTabBarImageContent: PTTabBarItemContent {

    private let container = UIView()
    private let imageView = UIImageView()
    private let lottieView = LottieAnimationView()

    private let normalImage: Any
    private let selectedImage: Any?

    public init(normal: Any, selected: Any? = nil) {
        self.normalImage = normal
        self.selectedImage = selected
        container.isUserInteractionEnabled = false
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFit
        
        var showViews = [UIView]()
        showViews = [imageView,lottieView]
        container.addSubviews(showViews)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        lottieView.isHidden = true
        lottieView.loopMode = .autoReverse
        lottieView.isUserInteractionEnabled = false
        lottieView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public var view: UIView { container }

    public func setSelected(_ selected: Bool, animated: Bool) {
        imageSet(media: selected ? (selectedImage ?? normalImage) : normalImage)
    }
    
    private func imageSet(media:Any) {
        switch media {
        case let string as String:
            if string.lowercased().contains("json") {
                if string.isURL(),let lottieURL = URL(string: string) {
                    Task { @MainActor in
                        let lottieAnimation = await LottieAnimation.loadedFrom(url: lottieURL)
                        if let findAnimation = lottieAnimation {
                            lottieAnimationSet(findAnimation: findAnimation)
                        } else {
                            imageView.isHidden = true
                            lottieView.isHidden = false
                            self.imageSet(media: self.normalImage)
                        }
                    }
                }
            } else {
                if let findAnimation = LottieAnimation.named(string) {
                    lottieAnimationSet(findAnimation: findAnimation)
                } else {
                    imageView.isHidden = false
                    lottieView.isHidden = true
                    imageView.loadImage(contentData: string)
                }
            }
        case let animation as LottieAnimation:
            lottieAnimationSet(findAnimation: animation)
        default:
            imageView.isHidden = false
            lottieView.isHidden = true
            self.imageView.loadImage(contentData: media)
        }
    }
    
    private func lottieAnimationSet(findAnimation:LottieAnimation) {
        lottieView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        lottieView.isHidden = false
        lottieView.animation = findAnimation
        lottieView.play()
    }
}

final public class PTTabBarItemView: UIControl {

    private let titleLabel = UILabel()
    private var content: PTTabBarItemContent!

    private let metailView = UIView()
    private let glassBackgroundView = UIVisualEffectView()

    public class func itemImageSize() -> CGFloat {
        let tab26ModeBottomSpacing = Gobal_device_info.isFaceIDCapable ? PTAppBaseConfig.share.tab26BottomSpacing : 0
        let safeAreaHeight:CGFloat = PTAppBaseConfig.share.tab26Mode ? tab26ModeBottomSpacing : 0
        let barHeight:CGFloat = PTAppBaseConfig.share.tab26Mode ? CGFloat.kTabbarHeight_Total : CGFloat.kTabbarHeight
        let imageSize = barHeight - safeAreaHeight - PTAppBaseConfig.share.tabTopSpacing - PTAppBaseConfig.share.tabContentSpacing - (PTAppBaseConfig.share.tabSelectedFont.pointSize + 2) - PTAppBaseConfig.share.tabBottomSpacing
        return imageSize
    }
    
    public var imageContent: UIView {
        get {
            return content.view
        }
    }
    
    public var isSelectedItem = false {
        didSet {
            content.setSelected(isSelectedItem, animated: true)
            titleLabel.textColor = isSelectedItem ? PTAppBaseConfig.share.tabSelectedColor : PTAppBaseConfig.share.tabNormalColor
            titleLabel.font = isSelectedItem ? PTAppBaseConfig.share.tabSelectedFont : PTAppBaseConfig.share.tabNormalFont
            if PTAppBaseConfig.share.tabSelectedMetail {
                metailView.backgroundColor = isSelectedItem ? PTAppBaseConfig.share.tabSelectedMetailColor : .clear
                glassBackgroundView.isHidden = !isSelectedItem
                self.layoutMetailView()
            }
        }
    }

    public init(content: PTTabBarItemContent, title: String) {
        super.init(frame: .zero)

        self.content = content
        setupUI(title: title)
    }

    public required init?(coder: NSCoder) { fatalError() }

    private func setupUI(title: String) {
        
        var subViews = [UIView]()
        if PTAppBaseConfig.share.tabSelectedMetail {
            if !title.stringIsEmpty() {
                subViews = [metailView,titleLabel,content.view]
            } else {
                subViews = [metailView,content.view]
            }
        } else {
            if !title.stringIsEmpty() {
                subViews = [titleLabel,content.view]
            } else {
                subViews = [content.view]
            }
        }
        
        if !title.stringIsEmpty() {
            titleLabel.numberOfLines = 1
            titleLabel.text = title
            titleLabel.font = PTAppBaseConfig.share.tabNormalFont
            titleLabel.textAlignment = .center
            titleLabel.textColor = PTAppBaseConfig.share.tabNormalColor
        }

        addSubviews(subViews)

        if PTAppBaseConfig.share.tabSelectedMetail {
            metailView.isUserInteractionEnabled = false
            metailView.clipsToBounds = true
            metailView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.tabSelectedMetailLRSpacing)
            }
            
            glassBackgroundView.isHidden = true
            glassBackgroundView.clipsToBounds = true
            glassBackgroundView.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            metailView.addSubviews([glassBackgroundView])
            glassBackgroundView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        content.view.snp.makeConstraints {
            if !title.stringIsEmpty() {
                $0.top.centerX.equalToSuperview()
            } else {
                $0.center.equalToSuperview()
            }
            $0.size.equalTo(PTTabBarItemView.itemImageSize())
        }

        if !title.stringIsEmpty() {
            titleLabel.snp.makeConstraints {
                $0.top.equalTo(content.view.snp.bottom).offset(PTAppBaseConfig.share.tabContentSpacing)
                $0.left.right.bottom.equalToSuperview()
            }
        }
        
        if PTAppBaseConfig.share.tabSelectedMetail {
            PTGCDManager.gcdAfter(time: 0.1, block: {
                self.layoutMetailView()
            })
        }
    }
    
    private func layoutMetailView() {
        self.layoutSubviews()
        if PTAppBaseConfig.share.tabSelectedMetail {
            metailView.viewCorner(radius: self.frame.size.height / 2)
            glassBackgroundView.layer.cornerRadius = self.frame.size.height / 2
            glassBackgroundView.layer.cornerCurve = .continuous
        }
    }
    
    // 🌟 新增方法：用于恢复 Icon 的初始布局
    public func restoreIconLayout() {
        let hasTitle = !(titleLabel.text?.stringIsEmpty() ?? true)
        content.view.snp.remakeConstraints {
            if hasTitle {
                $0.top.centerX.equalToSuperview()
            } else {
                $0.center.equalToSuperview()
            }
            $0.size.equalTo(PTTabBarItemView.itemImageSize())
        }
    }
}

final public class PTTabBarView: UIView {

    /// 是否允许选中（可拦截）
    public var shouldSelectIndex: ((Int) -> Bool)?
    /// 即将选中
    public var willSelectIndex: ((Int) -> Void)?
    /// 已经选中
    public var didSelectIndex: ((Int) -> Void)?
    /// 已经选中
    var didSelectInsideIndex: ((Int) -> Void)?
    // 🌟 新增：双击 Item 的 Callback
    public var didDoubleTapIndex: ((Int) -> Void)?
    /// 中间点击
    public var didTapCenter: PTActionTask?
    /// Badge removecallback
    public var badgeDragRemoveIndex: ((Int) -> Void)?

    public var items: [PTTabBarItemView] = []
    private var currentIndex: Int = 0
    
    private let glassBackgroundView = UIVisualEffectView()
    private let leftStackView = UIStackView()
    private let rightStackView = UIStackView()
    private var centerButton = UIView()
    private var centerContent:PTTabBarItemContent?
    private let highlightLayer = CAGradientLayer()
    
    public var centerTitle:String {
        get {
            PTAppBaseConfig.share.tabbarCenterName
        }
        set {
            centerNameLabel.text = newValue
        }
    }
    
    private lazy var centerNameLabel:UILabel = {
        let view = UILabel()
        view.font = PTAppBaseConfig.share.tabbarCenterNameFont
        view.textColor = PTAppBaseConfig.share.tabbarCenterNameColor
        view.textAlignment = .center
        view.numberOfLines = 0
        view.lineBreakMode = .byTruncatingTail
        view.isHidden = PTAppBaseConfig.share.tabbarCenterName.stringIsEmpty()
        view.text = centerTitle
        return view
    }()
    
    private var layoutStyle: PTTabBarLayoutStyle = .normal
    public var currentBarLayoutStyle : PTTabBarLayoutStyle {
        get {
            layoutStyle
        }
    }
    
    // 🌟 新增：用于最小化时展示当前 Icon 的容器
    lazy var minimizedCenterView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true // 让点击事件穿透
        // 单击手势
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMinimizedSingleTap))
        view.addGestureRecognizer(singleTap)
        
        // 双击手势（保持和你原有 Item 一致的逻辑）
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleMinimizedDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false
        view.addGestureRecognizer(doubleTap)
        return view
    }()

    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {

        backgroundColor = .clear

        setupGlassEffect()
        setupStackView()
        setupShadow()
        setupCenterButton()
    }

    private func setupGlassEffect() {

        var tabContainerHeight:CGFloat = 0
        
        if PTAppBaseConfig.share.tab26Mode {
            glassBackgroundView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
            if Gobal_device_info.isFaceIDCapable {
                tabContainerHeight = CGFloat.kTabbarHeight_Total - PTAppBaseConfig.share.tab26BottomSpacing
            } else {
                tabContainerHeight = CGFloat.kTabbarHeight_Total
            }
        } else {
            if PTAppBaseConfig.share.tabbarMetailMode {
                glassBackgroundView.effect = UIBlurEffect(style: .systemMaterial)
                tabContainerHeight = CGFloat.kTabbarHeight_Total
            } else {
                tabContainerHeight = CGFloat.kTabbarHeight_Total
            }
        }

        if PTAppBaseConfig.share.tab26Mode || PTAppBaseConfig.share.tabbarMetailMode {
            glassBackgroundView.clipsToBounds = true
            addSubview(glassBackgroundView)
            
            glassBackgroundView.snp.makeConstraints {
                $0.top.equalToSuperview()
                if PTAppBaseConfig.share.tab26Mode {
                    $0.left.right.equalToSuperview().inset(PTAppBaseConfig.share.tabbarBar26LRSpacing)
                } else {
                    $0.left.right.equalToSuperview()
                }
                $0.height.equalTo(tabContainerHeight)
            }

            if PTAppBaseConfig.share.tab26Mode {
                glassBackgroundView.layer.cornerRadius = tabContainerHeight / 2
            }
            glassBackgroundView.layer.cornerCurve = .continuous

            // 细边框
            glassBackgroundView.layer.borderWidth = 0.5
            glassBackgroundView.layer.borderColor =
                UIColor.white.withAlphaComponent(0.25).cgColor

            // 顶部高光渐变
            highlightLayer.colors = [
                UIColor.white.withAlphaComponent(0.35).cgColor,
                UIColor.white.withAlphaComponent(0.08).cgColor,
                UIColor.clear.cgColor
            ]
            highlightLayer.startPoint = CGPoint(x: 0.5, y: 0)
            highlightLayer.endPoint = CGPoint(x: 0.5, y: 1)
            if PTAppBaseConfig.share.tab26Mode {
                highlightLayer.cornerRadius = tabContainerHeight / 2
            }

            glassBackgroundView.layer.addSublayer(highlightLayer)
        }
    }

    private func setupStackView() {

        [leftStackView, rightStackView].forEach {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            if PTAppBaseConfig.share.tab26Mode || PTAppBaseConfig.share.tabbarMetailMode {
                glassBackgroundView.contentView.addSubview($0)
            } else {
                addSubview($0)
            }
        }
    }

    private func setupCenterButton() {

        addSubviews([centerButton,centerNameLabel])
        centerButton.backgroundColor = PTAppBaseConfig.share.tabbarCenterBGColor
        centetButtonEffect()
        
        centerButton.viewCorner(radius: PTAppBaseConfig.share.tabbarCenterButtonSize / 2)
        centerButton.layer.shadowColor = UIColor.black.cgColor
        centerButton.layer.shadowOpacity = 0.2
        centerButton.layer.shadowRadius = 20
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        let tap = UITapGestureRecognizer { sender in
            self.didTapCenter?()
        }
        centerButton.addGestureRecognizer(tap)
    }
    
    private func centetButtonEffect() {
        let effectView = UIVisualEffectView()
        if PTAppBaseConfig.share.tab26Mode {
            effectView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            if PTAppBaseConfig.share.tabbarCenterMetail {
                effectView.effect = UIBlurEffect(style: .systemMaterial)
            }
        }

        if PTAppBaseConfig.share.tab26Mode && PTAppBaseConfig.share.tabbarCenterMetail {
            effectView.clipsToBounds = true
            centerButton.addSubview(effectView)
            effectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            effectView.layer.cornerRadius = PTAppBaseConfig.share.tabbarCenterButtonSize / 2
            effectView.layer.cornerCurve = .continuous
        }
    }

    private func setupShadow() {
        if PTAppBaseConfig.share.tab26Mode {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.12
            layer.shadowRadius = 30
            layer.shadowOffset = CGSize(width: 0, height: 12)
        }
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        if PTAppBaseConfig.share.tab26Mode || PTAppBaseConfig.share.tabbarMetailMode {
            highlightLayer.frame = glassBackgroundView.bounds
        }
    }

    public func setup(configs: [PTTabBarItemConfig],
                      layoutStyle: PTTabBarLayoutStyle = .normal,
                      centerContent:PTTabBarItemContent? = nil) {
        self.layoutStyle = layoutStyle
        self.centerContent = centerContent
        configureItems(configs,centerContent: centerContent)
    }

    private func configureItems(_ configs: [PTTabBarItemConfig],
                                centerContent:PTTabBarItemContent? = nil) {

        // 清空
        items.forEach { $0.removeFromSuperview() }
        leftStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rightStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        centerButton.subviews.forEach { $0.removeFromSuperview() }
        items.removeAll()

        switch layoutStyle {
        case .normal:
            normalCaseStack(configs: configs)
        case .centerRaised:
            if let findBig = centerContent?.view {
                centetButtonEffect()
                centerButton.isHidden = false
                centerButton.addSubviews([findBig])
                findBig.snp.remakeConstraints { make in
                    make.edges.equalToSuperview().inset(PTAppBaseConfig.share.tabbarCenterInsideOffset)
                }

                let midIndex = configs.count / 2

                for (index, config) in configs.enumerated() {

                    let item = makeItem(config: config, index: index)
                    items.append(item)

                    if index < midIndex {
                        leftStackView.addArrangedSubview(item)
                    } else {
                        rightStackView.addArrangedSubview(item)
                    }
                }

                leftStackView.snp.remakeConstraints {
                    $0.left.equalToSuperview()
                    $0.top.equalToSuperview().inset(PTAppBaseConfig.share.tabTopSpacing)
                    if PTAppBaseConfig.share.tab26Mode {
                        $0.bottom.equalToSuperview().inset(PTAppBaseConfig.share.tabBottomSpacing)
                    } else {
                        $0.height.equalTo(CGFloat.kTabbarHeight)
                    }
                    $0.width.equalTo(self.barItemWidth() * CGFloat(self.leftStackView.arrangedSubviews.count))
                }

                centerButton.snp.remakeConstraints {
                    $0.left.equalTo(self.leftStackView.snp.right)
                    if PTAppBaseConfig.share.tab26Mode || PTAppBaseConfig.share.tabbarMetailMode {
                        $0.centerY.equalTo(glassBackgroundView.snp.top)
                    } else {
                        $0.centerY.equalTo(self.snp.top)
                    }
                    $0.size.equalTo(PTAppBaseConfig.share.tabbarCenterButtonSize)
                }

                centerNameLabel.snp.remakeConstraints { make in
                    make.left.right.equalTo(self.centerButton)
                    make.top.equalTo(self.centerButton.snp.bottom).offset(PTAppBaseConfig.share.tabbarCenterNameContentSpacing)
                    make.bottom.greaterThanOrEqualTo(self.rightStackView)
                }
                
                rightStackView.snp.remakeConstraints {
                    $0.right.equalToSuperview()
                    $0.top.equalTo(self.leftStackView)
                    $0.height.equalTo(self.leftStackView)
                    $0.left.equalTo(self.centerButton.snp.right)
                }
                
                centerContent?.setSelected(true, animated: true)
            } else {
                normalCaseStack(configs: configs)
            }
        }

        select(currentIndex)
    }
    
    private func normalCaseStack(configs: [PTTabBarItemConfig]) {
        centerButton.isHidden = true

        for (index, config) in configs.enumerated() {

            let item = makeItem(config: config, index: index)
            items.append(item)
            leftStackView.addArrangedSubview(item)
        }

        leftStackView.snp.remakeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().inset(PTAppBaseConfig.share.tabTopSpacing)
            if PTAppBaseConfig.share.tab26Mode {
                $0.bottom.equalToSuperview().inset(PTAppBaseConfig.share.tabBottomSpacing)
            } else {
                $0.height.equalTo(CGFloat.kTabbarHeight)
            }
        }
    }
    
    public func select(_ index: Int) {
        guard index >= 0, index < items.count else { return }

        // 如果是重复点击
        if index == currentIndex {
            for i in items.indices {
                items[i].isSelectedItem = i == index
            }
            didSelectIndex?(index)
            didSelectInsideIndex?(index)
            return
        }

        // 1️⃣ 是否允许选中
        if let should = shouldSelectIndex, should(index) == false {
            return
        }

        // 2️⃣ 即将选中
        willSelectIndex?(index)

        // 3️⃣ 更新UI
        for (i, item) in items.enumerated() {
            item.isSelectedItem = (i == index)
        }

        currentIndex = index

        // 4️⃣ 已选中
        didSelectIndex?(index)
        didSelectInsideIndex?(index)
    }
    
    private func makeItem(config: PTTabBarItemConfig,
                          index: Int) -> PTTabBarItemView {

        let item = PTTabBarItemView(
            content: config.content,
            title: config.title
        )

        item.addAction(UIAction { [weak self] _ in
            self?.select(index)
        }, for: .touchUpInside)

        // 🌟 新增：2. 实例化并配置双击手势
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2 // 必须连续点击两次
        
        // ⚠️ 关键设置：设为 false 可以让系统不拦截单击事件。
        // 这保证了用户第一次点击时 Tab 能瞬间切换完毕，而在短时间内发生第二次点击时，触发双击回调。
        doubleTapGesture.cancelsTouchesInView = false
        
        // 3. 将手势添加到 item 视图上
        item.addGestureRecognizer(doubleTapGesture)

        return item
    }
    
    // 🌟 新增：双击手势的响应方法
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        // 确保手势绑定的 View 是我们的 PTTabBarItemView
        if let item = gesture.view as? PTTabBarItemView {
            // 触发 Callback，把保存在 tag 中的 index 传给外部
            didDoubleTapIndex?(item.tag)
        }
    }

    private func barItemWidth() -> CGFloat {
        var itemWidth:CGFloat = 0
        switch layoutStyle {
        case .normal:
            if PTAppBaseConfig.share.tab26Mode {
                itemWidth = (CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.tabbarBar26LRSpacing * 2) / CGFloat(items.count)
            } else {
                itemWidth = CGFloat.kSCREEN_WIDTH / CGFloat(items.count)
            }
        case .centerRaised:
            if PTAppBaseConfig.share.tab26Mode {
                itemWidth = (CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.tabbarBar26LRSpacing * 2 - PTAppBaseConfig.share.tabbarCenterButtonSize) / CGFloat(items.count)
            } else {
                itemWidth = (CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.tabbarCenterButtonSize) / CGFloat(items.count)
            }
        }
        return itemWidth
    }
    
    public func badge(index:Int,badgeValue:Any,badgeStyle:PTBadgeStyle = .number,anumationType:PTBadgeAnimType = .none) {
        let item = items[index]
        let itemWidth:CGFloat = barItemWidth()
        var config = PTBadgeConfiguration()
        config.centerOffset = CGPointMake(itemWidth / 2 + PTTabBarItemView.itemImageSize() / 2, 7)
        item.badgeConfig = config
        item.showBadge(style: badgeStyle, value: badgeValue, aniType: anumationType)
        item.badgeRemoveCallback = {
            self.badgeDragRemoveIndex?(index)
        }
    }
    
    public func removeBadge(index:Int) {
        items[index].clearBadge()
    }

    // MARK: - HitTest (支持凸起点击)
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if layoutStyle == .centerRaised && centerButton.alpha > 0.01 && !centerButton.isHidden {
            let centerPoint = convert(point, to: centerButton)
            if centerButton.bounds.contains(centerPoint) {
                return centerButton
            }
        }

        return super.hitTest(point, with: event)
    }
    
    // 🌟 新增：处理最小化/正常状态的内部 UI 切换
    public func toggleMinimize(isMinimized: Bool, selectedIndex: Int) {
        guard selectedIndex >= 0 && selectedIndex < items.count else { return }
        let selectedItem = items[selectedIndex]
        let circleRadius: CGFloat = PTAppBaseConfig.share.tabbarMiniSize / 2

        if isMinimized {
            // 1. 偷天换日：将当前选中的 Icon 转移到最小化容器中
            let iconView = selectedItem.imageContent
            minimizedCenterView.addSubview(iconView)
            iconView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(PTTabBarItemView.itemImageSize())
            }

            addSubview(minimizedCenterView)
            minimizedCenterView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            // 2. 隐藏其他普通状态的 UI（使用 alpha 隐藏，防止破坏 StackView 结构）
            leftStackView.alpha = 0
            rightStackView.alpha = 0
            centerButton.alpha = 0
            centerNameLabel.alpha = 0

            // 3. ✅ 修复点 2：安全校验。只有当配置允许展示毛玻璃且它已在视图树中，才去更新约束
            if glassBackgroundView.superview != nil {
                glassBackgroundView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
                glassBackgroundView.layer.cornerRadius = circleRadius
                highlightLayer.cornerRadius = circleRadius
            }
        } else {
            // 1. 物归原主：恢复 Icon 到原本的 ItemView 中
            let iconView = selectedItem.imageContent
            selectedItem.addSubview(iconView)
            selectedItem.restoreIconLayout() // 调用我们在步骤 1 写的恢复方法

            minimizedCenterView.removeFromSuperview()

            // 2. 恢复普通 UI 的显示
            leftStackView.alpha = 1
            rightStackView.alpha = 1
            centerButton.alpha = 1
            centerNameLabel.alpha = 1

            // 3. ✅ 安全校验：恢复毛玻璃背景的正常约束
            if glassBackgroundView.superview != nil {
                let tabContainerHeight = PTAppBaseConfig.share.tab26Mode ? (CGFloat.kTabbarHeight_Total - PTAppBaseConfig.share.tab26BottomSpacing) : CGFloat.kTabbarHeight_Total
                glassBackgroundView.snp.remakeConstraints { make in
                    make.top.equalToSuperview()
                    if PTAppBaseConfig.share.tab26Mode {
                        make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.tabbarBar26LRSpacing)
                    } else {
                        make.left.right.equalToSuperview()
                    }
                    make.height.equalTo(tabContainerHeight)
                }
                let normalRadius = PTAppBaseConfig.share.tab26Mode ? tabContainerHeight / 2 : 0
                glassBackgroundView.layer.cornerRadius = normalRadius
                highlightLayer.cornerRadius = normalRadius
            }
        }
    }
    
    @objc private func handleMinimizedSingleTap() {
        // 当点击左下角的小圆圈时，相当于点击了当前选中的 Item
        select(currentIndex)
    }
    
    @objc private func handleMinimizedDoubleTap() {
        // 触发外部的双击回调
        didDoubleTapIndex?(currentIndex)
    }
}
