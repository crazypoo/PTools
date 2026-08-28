//
//  PTBaseViewController+Navigation.swift
//  PooTools
//
// English: Navigation container implementation is isolated from the base controller behavior.
// Español: La implementación del contenedor de navegación está aislada del comportamiento del controlador base.
// 中文：导航栏容器实现与基础控制器行为分离。
//

import UIKit
import SnapKit
import SwifterSwift

open class PTNavTitleContainer: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) { fatalError() }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: PTAppBaseConfig.share.bavTitleContainerHeight) // 保持标准高度
    }
}

@MainActor
open class PTNavigationBarContainer: UIView {
    
    private var fromStyle: PTNavigationBarStyle?
    private var toStyle: PTNavigationBarStyle?

    let backgroundView = UIView()
    let contentView = UIView()
        
    public var leftContainerWidth: CGFloat = 0
    public var rightContainerWidth: CGFloat = 0
    
    // ✅ 新增三块区域
    public lazy var leftContainer:UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        return view
    }()
    public let rightContainer:UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        return view
    }()
    
    public let titleContainer = UIView()
    
    let topBarContainer = UIView()   // ← 放 left/right/title
    let largeTitleContainer = UIView() // ← 单独一层
    let largeTitleLabel = UILabel()
    let largeTitleHeight: CGFloat = PTAppBaseConfig.share.navLargeTitleBarHeight

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([backgroundView,contentView])
        contentView.addSubviews([topBarContainer, largeTitleContainer])
        topBarContainer.addSubviews([leftContainer, rightContainer, titleContainer])
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        largeTitleContainer.addSubview(largeTitleLabel)
        topBarContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            if let findCurrent = PTUtils.getCurrentVC(),let sheet = findCurrent.sheetViewController {
                let offset = sheet.options.useFullScreenMode ? CGFloat.statusBarHeight() : sheet.options.pullBarHeight
                make.top.equalToSuperview().offset(-offset)
            } else {
                make.top.equalToSuperview()
            }
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
        
        largeTitleContainer.snp.makeConstraints { make in
            make.top.equalTo(topBarContainer.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0) // LargeTitle 高度
        }
        largeTitleContainer.isHidden = true
        leftContainer.isHidden = true
        rightContainer.isHidden = true
        titleContainer.isHidden = true
        
        backgroundView.frame = bounds
        contentView.frame = bounds
        
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        largeTitleLabel.font = PTAppBaseConfig.share.navLargeTitleFont
        largeTitleLabel.textColor = PTAppBaseConfig.share.navTitleTextColor
        largeTitleLabel.numberOfLines = 0
        largeTitleLabel.lineBreakMode = .byTruncatingTail
        largeTitleLabel.alpha = 0
        largeTitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.bottom.top.equalToSuperview()
        }
    }
    
    public required init?(coder: NSCoder) { fatalError() }
    
    public func apply(style: PTNavigationBarStyle) {
        backgroundView.alpha = 1.0
        largeTitleContainer.alpha = 1.0
//        switch style {
//        case .gradient(let type, let colors):
//            backgroundView.backgroundGradient(type: type, colors: colors)
//            largeTitleContainer.backgroundGradient(type: type, colors: colors)
//        case .solid(let color):
//            backgroundView.backgroundColor = color
//            largeTitleContainer.backgroundColor = color
//        case .transparent:
//            backgroundView.backgroundColor = .clear
//            largeTitleContainer.backgroundColor = .clear
//        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension PTNavigationBarContainer {
    func updateLargeTitle(progress: CGFloat) {
        let p = min(1, max(0, progress))
        // 大标题高度收缩
        let maxHeight: CGFloat = largeTitleHeight
        // ===== 1. Stretch（下拉放大）=====
        if p < 0 {
            let stretch = abs(p)
            let height = maxHeight + stretch * 40   // 拉伸幅度
            
            largeTitleContainer.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            
            // 字体轻微放大（系统类似效果）
            let scale = 1 + stretch * 0.08
            largeTitleLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            // 始终显示大标题
            largeTitleLabel.alpha = 1
            titleContainer.alpha = 0
            
            return
        }
        
        // ===== 正常收缩 =====
        let height = maxHeight * (1 - p)
        
        largeTitleContainer.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        
        // ===== alpha 渐变 =====
        largeTitleLabel.alpha = 1 - p
        titleContainer.alpha = p
        
        // ===== scale（系统 subtle 动画）=====
        let scale = 1 - 0.05 * p
        largeTitleLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        // ===== 字重动态变化（🔥重点）=====
        let baseFont = PTAppBaseConfig.share.navLargeTitleFont
        let fontSize = baseFont.pointSize
        
        let weight: UIFont.Weight = p > 0.5 ? .semibold : .bold
        
        largeTitleLabel.font = UIFont.systemFont(ofSize: fontSize, weight: weight)

    }
}

extension PTNavigationBarContainer {
    func prepareTransition(from: PTNavigationBarStyle, to: PTNavigationBarStyle) {
        self.fromStyle = from
        self.toStyle = to
        
        // 先应用 from
        apply(style: from)
    }

    /// 核心：根据 progress 渐变
    func updateTransition(progress: CGFloat) {
        guard let from = fromStyle, let to = toStyle,let nav = PTNavigationBarManager.shared.currentNav else { return }
        let progress = min(max(progress, 0), 1)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil   // ❗关键（去 blur）

        switch (from, to) {
        case let (.solid(c1), .solid(c2)):// MARK: - Solid -> Solid
            appearance.backgroundColor = c1.interpolate(to: c2, progress: progress)
            appearance.backgroundImage = UIImage()
        case let (.transparent, .solid(c)):// MARK: - Transparent -> Solid
            appearance.backgroundColor = c.withAlphaComponent(progress)
            appearance.backgroundImage = UIImage()
        case let (.solid(c), .transparent):// MARK: - Solid -> Transparent
            appearance.backgroundColor = c.withAlphaComponent(1 - progress)
            appearance.backgroundImage = UIImage()
        case (.transparent, .transparent):// MARK: - Transparent -> Transparent
            appearance.backgroundColor = .clear
            appearance.backgroundImage = UIImage()
        case let (.gradient(type1, colors1),.gradient(type2, colors2)):// MARK: - Gradient -> Gradient
            let image = makeTransitionGradientImage(fromType: type1, fromColors: colors1, toType: type2, toColors: colors2, boundsSize:nav.navigationBar.bounds.size, progress: progress)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        case let (.gradient(type, colors), .solid(color)):// MARK: - Gradient -> Solid
            let gradientColors = colors.map { $0 }
            let transitionColors = gradientColors.map {
                $0.interpolate(to: color, progress: progress)
            }

            let image = UIImage.gradient(colors: transitionColors, size: nav.navigationBar.bounds.size, direction: type)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        case let ( .solid(color), .gradient(type, colors)):// MARK: - Solid -> Gradient
            let gradientColors = colors.map { $0 }
            let transitionColors = gradientColors.map {
                color.interpolate(to: $0, progress: progress)
            }

            let image = UIImage.gradient(colors: transitionColors, size: nav.navigationBar.bounds.size, direction: type)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        case let (.gradient(type, colors), .transparent):// MARK: - Gradient -> Transparent
            let transitionColors = colors.map {
                $0.withAlphaComponent(1 - progress)
            }

            let image = UIImage.gradient(colors: transitionColors, size: nav.navigationBar.bounds.size, direction: type)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        case let (.transparent, .gradient(type, colors)):// MARK: - Transparent -> Gradient
            let transitionColors = colors.map {
                $0.withAlphaComponent(progress)
            }

            let image = UIImage.gradient(colors: transitionColors, size: nav.navigationBar.bounds.size, direction: type)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        }
        
        nav.navigationBar.compactScrollEdgeAppearance = appearance
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
        nav.navigationBar.isTranslucent = true
        nav.navigationBar.subviews.forEach {
            if NSStringFromClass(type(of: $0)).contains("UIBarBackground") {
                $0.isHidden = true
                $0.isUserInteractionEnabled = false
                $0.alpha = 0
            }
        }
    }
    
    private func makeTransitionGradientImage(fromType: Imagegradien,
                                             fromColors: [DynamicColor],
                                             toType: Imagegradien,
                                             toColors: [DynamicColor],
                                             boundsSize:CGSize,
                                             progress: CGFloat) -> UIImage? {

        let direction: Imagegradien = progress < 0.5 ? fromType : toType

        let colors = interpolateGradientColors(from: fromColors, to: toColors, progress: progress)

        return UIImage.gradient(colors: colors, size: boundsSize,direction: direction)
    }
    
    private func interpolateGradientColors(from: [DynamicColor], to: [DynamicColor], progress: CGFloat) -> [UIColor] {
        
        guard !from.isEmpty else {
            return to.map( {$0.withAlphaComponent(progress)} )
        }
        
        guard !to.isEmpty else {
            return from.map( { $0.withAlphaComponent(progress)} )
        }
        
        let count = min(from.count, to.count)
        
        return (0..<count).map { index in
            from[index].interpolate(to: to[index], progress: progress)
        }
    }
}
