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
    private weak var ownerNavigationController: UINavigationController?
    private var backgroundAlpha: CGFloat = 1
    private var largeTitleBackgroundVisible = false
    private var largeTitleBackgroundHeight: CGFloat = 0
    private var renderedProgress: CGFloat = 1

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
        clipsToBounds = false
        backgroundView.isUserInteractionEnabled = false
        contentView.backgroundColor = .clear
        topBarContainer.backgroundColor = .clear
        largeTitleContainer.backgroundColor = .clear
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

    // English: Bind the container to its navigation stack so multiple stacks cannot share a render target.
    // Español: Vincula el contenedor con su pila de navegación para que varias pilas no compartan el destino de renderizado.
    // 中文：将容器绑定到所属导航栈，避免多个导航栈共用错误的渲染目标。
    func bind(to navigationController: UINavigationController) {
        ownerNavigationController = navigationController
        navigationController.navigationBar.clipsToBounds = false
        setNeedsLayout()
    }
    
    public func apply(style: PTNavigationBarStyle) {
        // English: Render a settled style without replacing an active transition pair.
        // Español: Renderiza un estilo estable sin reemplazar un par de transición activo.
        // 中文：直接渲染稳定样式，但不覆盖正在进行的转场样式对。
        renderedProgress = 1
        backgroundAlpha = 1
        backgroundView.alpha = 1
        largeTitleContainer.alpha = 1
        render(from: style, to: style, progress: 1)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateBackgroundFrame()
    }
}

extension PTNavigationBarContainer {
    // English: Keep one background surface continuous through the status bar and navigation bar.
    // Español: Mantiene una única superficie de fondo continua entre la barra de estado y la barra de navegación.
    // 中文：让同一个背景层连续覆盖状态栏和导航栏，避免渐变重新起算。
    private func updateBackgroundFrame() {
        let topExtension = navigationBarTopExtension
        let largeTitleBottom: CGFloat
        if largeTitleBackgroundVisible {
            let laidOutBottom = largeTitleContainer.frame.maxY
            let expectedBottom = max(topBarContainer.frame.maxY, 0) + largeTitleBackgroundHeight
            largeTitleBottom = max(laidOutBottom, expectedBottom)
        } else {
            largeTitleBottom = 0
        }
        let visibleContentHeight = max(bounds.height, largeTitleBottom)
        backgroundView.frame = CGRect(
            x: 0,
            y: -topExtension,
            width: bounds.width,
            height: visibleContentHeight + topExtension
        )
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    private var navigationBarTopExtension: CGFloat {
        guard let navigationController = ownerNavigationController else {
            return CGFloat.statusBarHeight()
        }

        let navigationBar = navigationController.navigationBar
        let topInNavigationView = navigationBar.convert(.zero, to: navigationController.view).y
        if topInNavigationView > 0 {
            return topInNavigationView
        }

        let safeAreaTop = navigationController.view.safeAreaInsets.top
        return safeAreaTop > 0 ? safeAreaTop : CGFloat.statusBarHeight()
    }

    private var backgroundRenderSize: CGSize {
        updateBackgroundFrame()
        return CGSize(width: max(backgroundView.bounds.width, 1),
                      height: max(backgroundView.bounds.height, 1))
    }

    func setBackgroundAlpha(_ alpha: CGFloat) {
        backgroundAlpha = min(max(alpha, 0), 1)
        backgroundView.alpha = backgroundAlpha
    }

    // English: Keep the background extension synchronized with the large-title visibility state.
    // Español: Mantiene la extensión del fondo sincronizada con el estado de visibilidad del título grande.
    // 中文：让背景扩展区域与大标题的显示状态保持同步。
    func setLargeTitleBackgroundVisible(_ visible: Bool) {
        largeTitleBackgroundVisible = visible
        largeTitleBackgroundHeight = visible ? largeTitleHeight : 0
        largeTitleContainer.isHidden = !visible
        updateBackgroundLayout()
    }

    // English: Re-layout the custom surface after a title constraint changes without rebuilding the data hierarchy.
    // Español: Reorganiza la superficie personalizada después de cambiar las restricciones del título sin reconstruir la jerarquía de datos.
    // 中文：大标题约束变化后只重新布局自定义背景，不重建数据层级。
    func updateBackgroundLayout() {
        setNeedsLayout()
        layoutIfNeeded()
        updateBackgroundFrame()
    }

    // English: Re-render the current style after the large-title area changes size.
    // Español: Vuelve a renderizar el estilo actual después de cambiar el tamaño del área del título grande.
    // 中文：大标题区域尺寸变化后，按当前样式重新渲染背景。
    func rerenderCurrentStyle() {
        updateBackgroundLayout()
        guard let fromStyle, let toStyle else { return }
        render(from: fromStyle, to: toStyle, progress: renderedProgress)
    }

    func updateLargeTitle(progress: CGFloat) {
        // 大标题高度收缩
        let maxHeight: CGFloat = largeTitleHeight
        // ===== 1. Stretch（下拉放大）=====
        if progress < 0 {
            let stretch = abs(progress)
            let height = maxHeight + stretch * 40   // 拉伸幅度
            
            largeTitleContainer.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            largeTitleBackgroundHeight = height
            
            // 字体轻微放大（系统类似效果）
            let scale = 1 + stretch * 0.08
            largeTitleLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            // 始终显示大标题
            largeTitleLabel.alpha = 1
            titleContainer.alpha = 0
            updateBackgroundLayout()
            
            return
        }

        let p = min(1, max(0, progress))
        
        // ===== 正常收缩 =====
        let height = maxHeight * (1 - p)
        
        largeTitleContainer.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        largeTitleBackgroundHeight = height
        
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
        updateBackgroundLayout()

    }
}

extension PTNavigationBarContainer {
    func prepareTransition(from: PTNavigationBarStyle, to: PTNavigationBarStyle) {
        self.fromStyle = from
        self.toStyle = to
        
        // English: Render the starting state without replacing the from/to pair.
        // Español: Renderiza el estado inicial sin reemplazar el par from/to.
        // 中文：渲染起始状态，但不要覆盖当前的 from/to 样式对。
        updateTransition(progress: 0)
    }

    /// 核心：根据 progress 渐变
    func updateTransition(progress: CGFloat) {
        guard let from = fromStyle, let to = toStyle else { return }
        renderedProgress = min(max(progress, 0), 1)
        render(from: from, to: to, progress: renderedProgress)
    }

    // English: Render both the custom surfaces and the UIKit appearance from one style pair.
    // Español: Renderiza las superficies personalizadas y la apariencia de UIKit desde un único par de estilos.
    // 中文：使用同一组样式同时渲染自定义背景和 UIKit 导航栏外观。
    private func render(from: PTNavigationBarStyle,
                       to: PTNavigationBarStyle,
                       progress: CGFloat) {
        let progress = min(max(progress, 0), 1)
        let nav = ownerNavigationController
        let backgroundSize = backgroundRenderSize

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
            let image = makeTransitionGradientImage(fromType: type1, fromColors: colors1, toType: type2, toColors: colors2, boundsSize: backgroundSize, progress: progress)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        case let (.gradient(type, colors), .solid(color)):// MARK: - Gradient -> Solid
            let gradientColors = colors.map { $0 }
            let transitionColors = gradientColors.map {
                $0.interpolate(to: color, progress: progress)
            }

            let image = UIImage.gradient(colors: transitionColors, size: backgroundSize, direction: type)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        case let ( .solid(color), .gradient(type, colors)):// MARK: - Solid -> Gradient
            let gradientColors = colors.map { $0 }
            let transitionColors = gradientColors.map {
                color.interpolate(to: $0, progress: progress)
            }

            let image = UIImage.gradient(colors: transitionColors, size: backgroundSize, direction: type)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        case let (.gradient(type, colors), .transparent):// MARK: - Gradient -> Transparent
            let transitionColors = colors.map {
                $0.withAlphaComponent(1 - progress)
            }

            let image = UIImage.gradient(colors: transitionColors, size: backgroundSize, direction: type)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        case let (.transparent, .gradient(type, colors)):// MARK: - Transparent -> Gradient
            let transitionColors = colors.map {
                $0.withAlphaComponent(progress)
            }

            let image = UIImage.gradient(colors: transitionColors, size: backgroundSize, direction: type)
            appearance.backgroundColor = .clear
            appearance.backgroundImage = image
        }

        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        appearance.titleTextAttributes = [
            .font: PTAppBaseConfig.share.navTitleFont,
            .foregroundColor: PTAppBaseConfig.share.navTitleTextColor
        ]
        appearance.largeTitleTextAttributes = [
            .font: PTAppBaseConfig.share.navLargeTitleFont,
            .foregroundColor: PTAppBaseConfig.share.navTitleTextColor
        ]

        // English: The custom surface is the only color renderer; UIKit receives a transparent appearance.
        // Español: La superficie personalizada es el único renderizador de color; UIKit recibe una apariencia transparente.
        // 中文：自定义背景层作为唯一颜色渲染源，UIKit 外观保持透明，避免重复绘制。
        backgroundView.backgroundColor = .clear
        backgroundView.layer.contentsGravity = .resize
        backgroundView.layer.contents = appearance.backgroundImage?.cgImage
        backgroundView.alpha = backgroundAlpha
        largeTitleContainer.backgroundColor = .clear
        largeTitleContainer.layer.contents = nil

        appearance.backgroundColor = .clear
        appearance.backgroundImage = nil

        guard let nav else { return }
        
        nav.navigationBar.compactScrollEdgeAppearance = appearance
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
        // English: Clear legacy UIKit colors as well as appearances so `.solid(.clear)` stays transparent.
        // Español: Limpia también los colores UIKit heredados para que `.solid(.clear)` permanezca transparente.
        // 中文：同时清理 UIKit 旧式颜色，确保 `.solid(.clear)` 始终保持透明。
        nav.navigationBar.backgroundColor = .clear
        nav.navigationBar.barTintColor = .clear
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
