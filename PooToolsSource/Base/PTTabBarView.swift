//
//  PTTabBarView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
#if canImport(Lottie)
import Lottie
#endif
import SnapKit
import SwifterSwift

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
}

final public class PTTabBarImageContent: PTTabBarItemContent {

    private let imageView = UIImageView()

    private let normalImage: UIImage
    private let selectedImage: UIImage?

    public init(normal: UIImage, selected: UIImage? = nil) {
        self.normalImage = normal
        self.selectedImage = selected
        imageView.contentMode = .scaleAspectFit
        imageView.image = normal
    }

    public var view: UIView { imageView }

    public func setSelected(_ selected: Bool, animated: Bool) {
        imageView.image = selected ? (selectedImage ?? normalImage) : normalImage
    }
}

final public class PTTabBarBigImageContent: PTTabBarItemContent {

    private let imageView = UIImageView()

    private let normalImage: UIImage

    public init(normal: UIImage) {
        self.normalImage = normal
        imageView.contentMode = .scaleAspectFit
        imageView.image = normal
    }

    public var view: UIView { imageView }
    
    public func setSelected(_ selected: Bool, animated: Bool) {}
}

#if canImport(Lottie)
final public class PTTabBarLottieContent: PTTabBarItemContent {

    private let lottieView = LottieAnimationView()
    private let normalName: String
    private let selectedName: String?

    public init(normal: String, selected: String? = nil) {
        self.normalName = normal
        self.selectedName = selected
        lottieView.loopMode = .autoReverse
        lottieView.isUserInteractionEnabled = false
        if let lottieURL = URL(string: normal) {
            Task { @MainActor in
                lottieView.animation = await LottieAnimation.loadedFrom(url: lottieURL)
            }
        } else {
            lottieView.animation = .named(normal)
        }
    }

    public var view: UIView { lottieView }

    public func setSelected(_ selected: Bool, animated: Bool) {
        let name = selected ? (selectedName ?? normalName) : normalName
        if let lottieURL = URL(string: name) {
            Task { @MainActor in
                lottieView.animation = await LottieAnimation.loadedFrom(url: lottieURL)
            }
        } else {
            lottieView.animation = .named(name)
        }

        if animated && selected {
            lottieView.play()
        } else {
            lottieView.currentProgress = selected ? 1 : 0
        }
    }
}

final public class PTTabBarBigLottieContent: PTTabBarItemContent {

    private let lottieView = LottieAnimationView()
    private let normalName: String

    public init(normal: String) {
        self.normalName = normal
        lottieView.loopMode = .autoReverse
        if let lottieURL = URL(string: normal) {
            Task { @MainActor in
                lottieView.animation = await LottieAnimation.loadedFrom(url: lottieURL)
            }
        } else {
            lottieView.animation = LottieAnimation.named(normal)
        }
        lottieView.play()
    }

    public var view: UIView { lottieView }

    public func setSelected(_ selected: Bool, animated: Bool) { }
}

#endif

final public class PTTabBarItemView: UIControl {

    private let titleLabel = UILabel()
    private var content: PTTabBarItemContent!

    private let metailView = UIView()
    private let glassBackgroundView = UIVisualEffectView()

    public class func itemImageSize() -> CGFloat {
        let safeAreaHeight:CGFloat = PTAppBaseConfig.share.tab26Mode ? PTAppBaseConfig.share.tab26BottomSpacing : 0
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
        
        titleLabel.numberOfLines = 1
        titleLabel.text = title
        titleLabel.font = PTAppBaseConfig.share.tabNormalFont
        titleLabel.textAlignment = .center
        titleLabel.textColor = PTAppBaseConfig.share.tabNormalColor

        var subViews = [UIView]()
        if PTAppBaseConfig.share.tabSelectedMetail {
            subViews = [metailView,titleLabel,content.view]
        } else {
            subViews = [titleLabel,content.view]
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
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(PTTabBarItemView.itemImageSize())
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(content.view.snp.bottom).offset(PTAppBaseConfig.share.tabContentSpacing)
            $0.left.right.bottom.equalToSuperview()
        }
        
        if PTAppBaseConfig.share.tabSelectedMetail {
            PTGCDManager.gcdAfter(time: 0.1, block: {
                self.layoutMetailView()
            })
        }
    }
    
    private func layoutMetailView() {
        self.layoutSubviews()
        metailView.viewCorner(radius: self.frame.size.height / 2)
        glassBackgroundView.layer.cornerRadius = self.frame.size.height / 2
        glassBackgroundView.layer.cornerCurve = .continuous
    }
}

final public class PTTabBarView: UIView {

    /// 是否允许选中（可拦截）
    public var shouldSelectIndex: ((Int) -> Bool)?
    /// 即将选中
    public var willSelectIndex: ((Int) -> Void)?
    /// 已经选中
    public var didSelectIndex: ((Int) -> Void)?
    /// 中间点击
    public var didTapCenter: PTActionTask?
    /// Badge removecallback
    public var badgeDragRemoveIndex: ((Int) -> Void)?

    private var items: [PTTabBarItemView] = []
    private var currentIndex: Int = 0
    
    private let glassBackgroundView = UIVisualEffectView()
    private let leftStackView = UIStackView()
    private let rightStackView = UIStackView()
    private var centerButton = UIView()
    private var centerContent:PTTabBarItemContent?
    private let highlightLayer = CAGradientLayer()
    
    private var layoutStyle: PTTabBarLayoutStyle = .normal
    public var currentBarLayoutStyle : PTTabBarLayoutStyle {
        get {
            layoutStyle
        }
    }
    public var centerButtonSize: CGFloat = 64

    let bar26LRSpacing:CGFloat = 24.adapter
    
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
            tabContainerHeight = CGFloat.kTabbarHeight_Total - PTAppBaseConfig.share.tab26BottomSpacing
        } else {
            glassBackgroundView.effect = UIBlurEffect(style: .systemMaterial)
            tabContainerHeight = CGFloat.kTabbarHeight_Total
        }

        glassBackgroundView.clipsToBounds = true
        addSubview(glassBackgroundView)

        glassBackgroundView.snp.makeConstraints {
            $0.top.equalToSuperview()
            if PTAppBaseConfig.share.tab26Mode {
                $0.left.right.equalToSuperview().inset(self.bar26LRSpacing)
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

    private func setupStackView() {

        [leftStackView, rightStackView].forEach {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            glassBackgroundView.contentView.addSubview($0)
        }
    }

    private func setupCenterButton() {

        addSubview(centerButton)

        let effectView = UIVisualEffectView()
        if PTAppBaseConfig.share.tab26Mode {
            effectView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            effectView.effect = UIBlurEffect(style: .systemMaterial)
        }

        effectView.clipsToBounds = true
        centerButton.addSubview(effectView)
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        effectView.layer.cornerRadius = centerButtonSize / 2
        effectView.layer.cornerCurve = .continuous

        centerButton.layer.shadowColor = UIColor.black.cgColor
        centerButton.layer.shadowOpacity = 0.2
        centerButton.layer.shadowRadius = 20
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 10)

        let tap = UITapGestureRecognizer { sender in
            self.didTapCenter?()
        }
        centerButton.addGestureRecognizer(tap)
    }

    private func setupShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 30
        layer.shadowOffset = CGSize(width: 0, height: 12)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        highlightLayer.frame = glassBackgroundView.bounds
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
        items.removeAll()

        switch layoutStyle {
        case .normal:
            normalCaseStack(configs: configs)
        case .centerRaised:
            if let findBig = centerContent?.view {
                centerButton.isHidden = false
                centerButton.addSubviews([findBig])
                findBig.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
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

                centerButton.snp.remakeConstraints {
                    $0.centerX.equalToSuperview()
                    $0.centerY.equalTo(glassBackgroundView.snp.top)
                    $0.size.equalTo(centerButtonSize)
                }

                leftStackView.snp.remakeConstraints {
                    $0.left.equalToSuperview()
                    $0.top.equalToSuperview().inset(PTAppBaseConfig.share.tabTopSpacing)
                    if PTAppBaseConfig.share.tab26Mode {
                        $0.bottom.equalToSuperview().inset(PTAppBaseConfig.share.tabBottomSpacing)
                    } else {
                        $0.height.equalTo(CGFloat.kTabbarHeight)
                    }
                    $0.right.equalTo(self.centerButton.snp.left)
                }

                rightStackView.snp.remakeConstraints {
                    $0.right.equalToSuperview()
                    $0.top.equalTo(self.leftStackView)
                    $0.height.equalTo(self.leftStackView)
                    $0.left.equalTo(self.centerButton.snp.right)
                }
                
#if canImport(Lottie)
                if let bigLottie = findBig as? LottieAnimationView {
                    bigLottie.play()
                }
#endif
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
            items[index].isSelectedItem = true
            didSelectIndex?(index)
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

        return item
    }
    
    public func badge(index:Int,badgeValue:Any,badgeStyle:PTBadgeStyle = .Number,anumationType:PTBadgeAnimType = .None) {
        let item = items[index]
        var itemWidth:CGFloat = 0
        switch layoutStyle {
        case .normal:
            if PTAppBaseConfig.share.tab26Mode {
                itemWidth = (CGFloat.kSCREEN_WIDTH - self.bar26LRSpacing * 2) / CGFloat(items.count)
            } else {
                itemWidth = CGFloat.kSCREEN_WIDTH / CGFloat(items.count)
            }
        case .centerRaised:
            if PTAppBaseConfig.share.tab26Mode {
                itemWidth = (CGFloat.kSCREEN_WIDTH - self.bar26LRSpacing * 2 - centerButtonSize) / CGFloat(items.count)
            } else {
                itemWidth = (CGFloat.kSCREEN_WIDTH - centerButtonSize) / CGFloat(items.count)
            }
        }
        
        item.badgeCenterOffset = CGPointMake(itemWidth / 2 + PTTabBarItemView.itemImageSize() / 2, 7)
        item.badgeBorderLine = PTAppBaseConfig.share.tabBadgeBorderHeight
        item.badgeBorderColor = PTAppBaseConfig.share.tabBadgeBorderColor
        item.badgeFont = PTAppBaseConfig.share.tabBadgeFont
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

        if layoutStyle == .centerRaised {

            let centerPoint = convert(point, to: centerButton)
            if centerButton.bounds.contains(centerPoint) {
                return centerButton
            }
        }

        return super.hitTest(point, with: event)
    }
}
