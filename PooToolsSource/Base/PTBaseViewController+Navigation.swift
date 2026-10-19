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

// English: The title container participates in navigation-bar layout on MainActor.
// Español: El contenedor del título participa en el layout de navegación dentro de MainActor.
// 中文：标题容器参与导航栏布局，固定在 MainActor 上执行。
@MainActor
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

    // English: Cache only the value signature and weak view identity used by the title adapters.
    // Español: Guarda solo la firma de valores y la identidad débil de la vista usada por los adaptadores.
    // 中文：只缓存标题适配器使用的值签名和弱引用视图身份。
    var titleLayoutSignature: PTNavigationTitleLayoutInput?
    weak var titleLayoutView: UIView?
    var titleLayoutMode: PTNavigationTitleLayoutMode?
    var titleLayoutUpdateHandler: (() -> Void)?
    private var isUpdatingTitleLayout = false
    
    let topBarContainer = UIView()   // ← 放 left/right/title
    let largeTitleContainer = UIView() // ← 单独一层
    let largeTitleLabel = UILabel()
    let largeTitleHeight: CGFloat = PTAppBaseConfig.share.navLargeTitleBarHeight

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([backgroundView,contentView])
        contentView.addSubviews([topBarContainer, largeTitleContainer])
        topBarContainer.addSubviews([leftContainer, rightContainer, titleContainer])
        largeTitleContainer.addSubview(largeTitleLabel)
        clipsToBounds = false
        backgroundView.isUserInteractionEnabled = false
        contentView.backgroundColor = .clear
        topBarContainer.backgroundColor = .clear
        largeTitleContainer.backgroundColor = .clear
        topBarContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            if let findCurrent = PTUtils.getCurrentVC(), let sheet = findCurrent.sheetViewController {
                let offset = sheet.options.useFullScreenMode ? 0 : sheet.options.pullBarHeight
                make.top.equalToSuperview().offset(-offset)
            } else {
                make.top.equalToSuperview()
            }
            make.height.equalTo(CGFloat.kNavBarHeight)
        }

        titleContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(0)
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
        
        PTUIAccessibility.applyDynamicType(to: largeTitleLabel,
                                           font: PTAppBaseConfig.share.navLargeTitleFont)
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

    // English: Expose only local host geometry to PTNavBar; never infer layout from a global status-bar constant.
    // Español: Expone solo la geometría local al PTNavBar; nunca infiere el layout desde una constante global.
    // 中文：只向 PTNavBar 提供当前宿主几何，不再使用全局状态栏常量推算布局。
    var navigationHostTopInset: CGFloat {
        guard let navigationController = ownerNavigationController else {
            return max(0, safeAreaInsets.top)
        }
        let navigationBar = navigationController.navigationBar
        let convertedTop = navigationBar.convert(.zero, to: navigationController.view).y
        return max(0, convertedTop)
    }
    
    public func apply(style: PTNavigationBarStyle) {
        // English: Commit the settled style so later layout updates do not reuse an old transition pair.
        // Español: Confirma el estilo estable para que las actualizaciones posteriores no reutilicen un par de transición antiguo.
        // 中文：提交当前稳定样式，避免后续布局更新继续使用旧的转场样式对。
        fromStyle = style
        toStyle = style
        renderedProgress = 1
        backgroundAlpha = 1
        backgroundView.alpha = 1
        largeTitleContainer.alpha = 1
        render(from: style, to: style, progress: 1)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateBackgroundFrame()
        requestTitleLayoutUpdate()
    }
}

extension PTNavigationBarContainer {
    // English: Resolve the usable title region from the navigation host's local bounds and safe regions.
    // Español: Resuelve la región utilizable del título desde los bounds y regiones seguras locales del host.
    // 中文：根据导航宿主的局部 bounds 和安全区域解析标题可用范围。
    func navigationTitleVisibleRect() -> CGRect {
        guard !topBarContainer.bounds.isEmpty else { return .zero }
        let context = PTAdaptiveBarLayoutContext.make(for: topBarContainer)
        let region = PTAdaptiveVisibleRegionResolver.region(for: context)
        let visible = region.visibleRect.intersection(topBarContainer.bounds)
        return visible.isEmpty ? topBarContainer.bounds : visible
    }

    // English: Share one measurement input between the system-container and standalone-bar adapters.
    // Español: Comparte una única entrada de medición entre el contenedor del sistema y la barra independiente.
    // 中文：让系统容器和独立导航栏适配器共用同一套测量输入。
    func navigationTitleLayout(for view: UIView,
                               mode: PTNavigationTitleLayoutMode,
                               visibleRect: CGRect,
                               availableHeight: CGFloat? = nil,
                               fixedWidth: CGFloat? = nil) -> (input: PTNavigationTitleLayoutInput,
                                                               result: PTNavigationTitleLayoutResult) {
        let height = availableHeight ?? visibleRect.height
        let desiredSize = PTNavigationTitleSizeResolver.resolve(view: view,
                                                                availableHeight: height,
                                                                fixedWidth: fixedWidth)
        let input = PTNavigationTitleLayoutResolver.makeInput(
            visibleRect: visibleRect,
            leftWidth: leftContainerWidth,
            rightWidth: rightContainerWidth,
            desiredTitleSize: desiredSize,
            minimumEdgeInset: PTAppBaseConfig.share.defaultViewSpace,
            itemSpacing: PTAppBaseConfig.share.navContainerSpacing,
            mode: mode
        )
        return (input, PTNavigationTitleLayoutResolver.resolve(input))
    }

    // English: Re-enter an adapter only once per layout pass so geometry changes cannot create a layout loop.
    // Español: Entra en el adaptador una sola vez por pasada para evitar bucles de layout por cambios geométricos.
    // 中文：每次布局只进入一次适配器，避免几何变化造成布局循环。
    private func requestTitleLayoutUpdate() {
        guard !isUpdatingTitleLayout, titleLayoutUpdateHandler != nil else { return }
        isUpdatingTitleLayout = true
        titleLayoutUpdateHandler?()
        isUpdatingTitleLayout = false
    }

    // English: Remove the title view and collapse its owner constraints when the renderer changes or title becomes nil.
    // Español: Elimina el título y colapsa sus restricciones cuando cambia el renderer o el título pasa a nil.
    // 中文：渲染器切换或标题为空时，移除标题并收拢其所属约束。
    func clearTitleLayout(removeView: Bool = true) {
        let hasTitleState = titleLayoutSignature != nil ||
            titleLayoutView != nil ||
            titleLayoutMode != nil ||
            !titleContainer.isHidden ||
            !titleContainer.subviews.isEmpty
        guard hasTitleState else { return }
        if removeView {
            titleContainer.subviews.forEach {
                // English: Remove adapter-owned constraints before changing the view hierarchy.
                // Español: Elimina las restricciones del adaptador antes de cambiar la jerarquía de vistas.
                // 中文：切换视图层级前，先移除适配器拥有的约束。
                $0.snp.removeConstraints()
                $0.removeFromSuperview()
            }
        }
        titleLayoutSignature = nil
        titleLayoutView = nil
        titleLayoutMode = nil
        titleContainer.isHidden = true
        titleContainer.isUserInteractionEnabled = false
        titleContainer.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(0)
        }
    }

    // English: Snapshot custom item sizes before reparenting them into a navigation stack.
    // Español: Captura el tamaño de cada elemento antes de cambiarlo a la jerarquía de la barra.
    // 中文：在把自定义按钮重新加入导航栏层级前，先快照它们的尺寸。
    func navigationBarItemSize(for view: UIView) -> CGSize {
        let boundsSize = view.bounds.size
        let frameSize = view.frame.size
        let intrinsicSize = view.intrinsicContentSize
        let defaultSize = PTAppBaseConfig.share.navBarButtonSize
        let fallbackSize = view is UISwitch ? CGSize(width: 51, height: 31) : CGSize(width: defaultSize, height: defaultSize)

        func resolvedDimension(bounds: CGFloat,
                               frame: CGFloat,
                               intrinsic: CGFloat,
                               fallback: CGFloat) -> CGFloat {
            if bounds.isFinite, bounds > 0 { return bounds }
            if frame.isFinite, frame > 0 { return frame }
            if intrinsic.isFinite, intrinsic > 0 { return intrinsic }
            return fallback
        }

        return CGSize(width: resolvedDimension(bounds: boundsSize.width,
                                               frame: frameSize.width,
                                               intrinsic: intrinsicSize.width,
                                               fallback: fallbackSize.width),
                      height: resolvedDimension(bounds: boundsSize.height,
                                                frame: frameSize.height,
                                                intrinsic: intrinsicSize.height,
                                                fallback: fallbackSize.height))
    }

    // English: Apply one deterministic item layout to both native navigation content and PTNavBar.
    // Español: Aplica un único layout determinista a los contenidos nativos y a PTNavBar.
    // 中文：让系统导航栏内容和 PTNavBar 共用同一套确定性布局。
    @discardableResult
    func configureNavigationBarItems(_ views: [UIView],
                                    in stack: UIStackView,
                                    spacing: CGFloat) -> CGFloat {
        let measuredViews = views.map { ($0, navigationBarItemSize(for: $0)) }

        stack.spacing = max(0, spacing)
        stack.alignment = .center
        stack.distribution = .fill
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.isHidden = measuredViews.isEmpty

        for (view, size) in measuredViews {
            stack.addArrangedSubview(view)
            view.snp.remakeConstraints { make in
                make.width.equalTo(size.width)
                make.height.equalTo(size.height)
            }
        }

        return measuredViews.reduce(0) { partialResult, element in
            partialResult + element.1.width
        } + CGFloat(max(0, measuredViews.count - 1)) * stack.spacing
    }

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
            return max(0, safeAreaInsets.top)
        }

        let navigationBar = navigationController.navigationBar
        let topInNavigationView = navigationBar.convert(.zero, to: navigationController.view).y
        if topInNavigationView > 0 {
            return topInNavigationView
        }

        return max(0, navigationController.view.safeAreaInsets.top)
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
        
        PTUIAccessibility.applyDynamicType(to: largeTitleLabel,
                                           font: UIFont.systemFont(ofSize: fontSize, weight: weight))
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
            .font: PTUIAccessibility.scaledFont(PTAppBaseConfig.share.navTitleFont),
            .foregroundColor: PTAppBaseConfig.share.navTitleTextColor
        ]
        appearance.largeTitleTextAttributes = [
            .font: PTUIAccessibility.scaledFont(PTAppBaseConfig.share.navLargeTitleFont),
            .foregroundColor: PTAppBaseConfig.share.navTitleTextColor
        ]

        // English: The custom surface is the only color renderer; UIKit receives a transparent appearance.
        // Español: La superficie personalizada es el único renderizador de color; UIKit recibe una apariencia transparente.
        // 中文：自定义背景层作为唯一颜色渲染源，UIKit 外观保持透明，避免重复绘制。
        backgroundView.backgroundColor = appearance.backgroundColor ?? .clear
        backgroundView.layer.contentsGravity = .resize
        backgroundView.layer.contents = appearance.backgroundImage?.cgImage
        backgroundView.alpha = backgroundAlpha

        if PTUIAccessibility.reduceTransparencyEnabled,
           styleNeedsOpaqueFallback(from) || styleNeedsOpaqueFallback(to) {
            backgroundView.layer.contents = nil
            backgroundView.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
                .resolvedColor(with: traitCollection)
            backgroundView.alpha = 1
        }

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

    private func styleNeedsOpaqueFallback(_ style: PTNavigationBarStyle) -> Bool {
        switch style {
        case .transparent:
            return true
        case .solid(let color):
            return color.resolvedColor(with: traitCollection).cgColor.alpha < 0.999
        case .gradient:
            return false
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
