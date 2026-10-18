//
//  PTNavBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/9/30.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
import SnapKit

@MainActor
open class PTNavBar: PTNavigationBarContainer {
    
    fileprivate func navOffset() -> CGFloat {
        guard let current = PTUtils.getCurrentVC(), let sheet = current.sheetViewController else { return 0 }
        return sheet.options.useFullScreenMode ? 0 : max(0, sheet.options.pullBarHeight)
    }
    
    // English: Mark this instance as a standalone view that does not own the system status bar.
    // Español: Marca esta instancia como una vista independiente que no controla la barra de estado del sistema.
    // 中文：标记当前实例为独立 View，不接管系统状态栏。
    public var isFakeNav: Bool = false {
        didSet {
            // English: Rebuild the host constraints immediately when the rendering mode changes.
            // Español: Reconstruye inmediatamente las restricciones del host cuando cambia el modo.
            // 中文：模式变化后立即重建外层容器约束。
            updateTopBarContainerConstraints()
            
            // English: Reapply the cached item sizes after the host geometry changes.
            // Español: Vuelve a aplicar los tamaños guardados después de cambiar la geometría del host.
            // 中文：宿主几何变化后重新应用已缓存的按钮尺寸。
            if !leftContainer.arrangedSubviews.isEmpty {
                setLeftButtons(leftContainer.arrangedSubviews)
            }
            if !rightContainer.arrangedSubviews.isEmpty {
                setRightButtons(rightContainer.arrangedSubviews)
            }
        }
    }

    private struct WidthLayoutSignature: Equatable {
        let containerWidth: CGFloat
        let leftWidth: CGFloat
        let rightWidth: CGFloat
        let navigationSpacing: CGFloat
        let defaultSpace: CGFloat
        let visibleRect: CGRect
    }

    private var lastWidthLayoutSignature: WidthLayoutSignature?
    private var lastVisibleLayoutRect: CGRect = .null
    
    fileprivate var titleViewMAxWidth: CGFloat = 0 {
        didSet {
            switch titleViewMode {
            case .auto:
                if let view = titleView {
                    let targetWidth = max(view.intrinsicContentSize.width, view.bounds.width)
                    view.ptLayout.remakeConstraints { make in
                        make.centerX.centerY.equalToSuperview()
                        make.height.equalToSuperview()
                        make.width.equalTo(min(targetWidth, titleViewMAxWidth))
                    }
                }
            case .fixed(let width):
                if let view = titleView {
                    view.ptLayout.remakeConstraints { make in
                        make.center.equalToSuperview()
                        make.width.equalTo(min(width, titleViewMAxWidth))
                        make.height.equalToSuperview()
                    }
                }
            default:
                break
            }
        }
    }
    
    public enum PTTitleViewMode: Sendable {
        case auto
        case fixed(CGFloat)
        case fill
    }

    public var titleViewMode: PTTitleViewMode = .fill {
        didSet {
            if let view = titleView { applyTitleViewConstraints(view) }
        }
    }

    public var titleView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
                        
            guard let newView = titleView else {
                // English: Hide the title container when no title view is installed.
                // Español: Oculta el contenedor cuando no hay una vista de título instalada.
                // 中文：没有标题视图时隐藏标题容器。
                titleContainer.isHidden = true
                return
            }
            
            // English: Keep the title container visible for the new title view.
            // Español: Mantiene visible el contenedor para la nueva vista de título.
            // 中文：为新的标题视图保持标题容器可见。
            titleContainer.isHidden = false

            titleContainer.addSubview(newView)
            // English: Keep titleContainer constraints under calculateMaxWidth so the title stays centered in the full bar.
            // Español: Mantiene las restricciones de titleContainer en calculateMaxWidth para centrar el título en toda la barra.
            // 中文：将 titleContainer 的约束统一交给 calculateMaxWidth，保证标题相对整条导航栏居中。
            applyTitleViewConstraints(newView)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        let visibleRect = adaptiveVisibleRect()
        if visibleRect != lastVisibleLayoutRect {
            lastVisibleLayoutRect = visibleRect
            updateContainerConstraints(leftContainer, isLeft: true)
            updateContainerConstraints(rightContainer, isLeft: false)
        }
        calculateMaxWidth()
    }
    
    private func setupUI() {
        [leftContainer, rightContainer].forEach {
            $0.spacing = PTAppBaseConfig.share.navBarButtonSpacing
        }
        
        // 初始化外层
        updateTopBarContainerConstraints()
        
        // 初始化内层
        updateContainerConstraints(leftContainer, isLeft: true)
        updateContainerConstraints(rightContainer, isLeft: false)
        
        titleContainer.ptLayout.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftContainer.ptLayout.right).offset(PTAppBaseConfig.share.navContainerSpacing)
            make.right.lessThanOrEqualTo(rightContainer.ptLayout.left).offset(-PTAppBaseConfig.share.navContainerSpacing)
            make.height.equalTo(34)
        }
    }
    
    // 🔥 核心逻辑 1：接管并重构父类 topBarContainer 的约束
    private func updateTopBarContainerConstraints() {
        // topBarContainer 是父类 PTNavigationBarContainer 里的属性
        topBarContainer.ptLayout.remakeConstraints { make in
            make.left.right.equalToSuperview()
            
            if isFakeNav {
                // English: A standalone bar must occupy exactly the height supplied by its host view.
                // Español: Una barra independiente debe ocupar exactamente la altura de su vista anfitriona.
                // 中文：伪导航栏必须严格使用宿主 View 提供的实际高度。
                make.top.bottom.equalToSuperview()
            } else {
                // English: Use the navigation host's local safe-area position and sheet pull distance.
                // Español: Usa la posición local del área segura del host y la distancia de la hoja.
                // 中文：使用导航宿主的局部安全区位置和 Sheet 拉手距离。
                let sheetOffset = navOffset()
                let hostTopInset = navigationHostTopInset
                make.top.equalToSuperview().offset(-sheetOffset)
                make.height.equalTo(hostTopInset + sheetOffset + CGFloat.kNavBarHeight)
            }
        }
    }

    // 🔥 核心逻辑 2：调整内部按钮组相对于 topBarContainer 的 Y 轴布局
    private func updateContainerConstraints(_ container: UIStackView, isLeft: Bool) {
        let widthTotal = stackTotalWidth(container)
        let visibleRect = adaptiveVisibleRect()
        let fallbackRect = bounds.isEmpty ? CGRect(x: 0, y: 0, width: 0, height: 0) : bounds
        let layoutRect = visibleRect.isEmpty ? fallbackRect : visibleRect
        let leadingInset = layoutRect.minX + PTAppBaseConfig.share.defaultViewSpace
        let trailingInset = max(0, bounds.width - layoutRect.maxX) + PTAppBaseConfig.share.defaultViewSpace
        
        container.ptLayout.remakeConstraints { make in
            if isLeft {
                make.left.equalToSuperview().offset(leadingInset)
            } else {
                make.right.equalToSuperview().inset(trailingInset)
            }
            
            if isFakeNav {
                // English: Center standalone controls in the bar's own content row.
                // Español: Centra los controles independientes en la fila de contenido de la barra.
                // 中文：让伪导航栏按钮在自身内容行内垂直居中。
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
            } else {
                // English: Keep button groups inside the local host geometry.
                // Español: Mantiene los grupos de botones dentro de la geometría local del host.
                // 中文：让按钮组始终落在当前宿主的局部几何区域内。
                make.top.equalToSuperview().inset(navigationHostTopInset + navOffset())
                make.bottom.equalToSuperview()
            }
            
            make.width.equalTo(widthTotal)
        }
    }

    // English: Resolve button and title positions from the bar's own visible pane, not the full Duo host width.
    // Español: Resuelve los botones y el título desde el panel visible de la barra, no desde todo el ancho del host Duo.
    // 中文：根据导航栏自身的可视面板布局按钮和标题，不再使用 Duo 宿主的完整宽度。
    private func adaptiveVisibleRect() -> CGRect {
        guard !bounds.isEmpty else { return .zero }
        let context = PTAdaptiveBarLayoutContext.make(for: self)
        let localInsets = isFakeNav
            ? UIEdgeInsets(top: 0,
                           left: context.safeAreaInsets.left,
                           bottom: 0,
                           right: context.safeAreaInsets.right)
            : context.safeAreaInsets
        let localContext = PTAdaptiveBarLayoutContext(bounds: context.bounds,
                                                       safeAreaInsets: localInsets,
                                                       verticalBarEdge: context.verticalBarEdge,
                                                       reservedRegions: context.reservedRegions,
                                                       layoutDirection: context.layoutDirection,
                                                       isHorizontalRegular: context.isHorizontalRegular,
                                                       isVerticalRegular: context.isVerticalRegular)
        let region = PTAdaptiveVisibleRegionResolver.region(for: localContext)
        let visible = region.visibleRect.intersection(bounds)
        return visible.isEmpty ? bounds : visible
    }

    private func applyTitleViewConstraints(_ view: UIView) {
        view.ptLayout.remakeConstraints { make in
            switch titleViewMode {
            case .auto:
                let targetWidth = max(view.intrinsicContentSize.width, view.bounds.width)
                let width = min(targetWidth, titleViewMAxWidth)
                make.centerX.centerY.equalToSuperview()
                make.height.equalToSuperview()
                make.width.equalTo(width)
            case .fixed(let width):
                make.center.equalToSuperview()
                make.width.equalTo(min(width, titleViewMAxWidth))
                make.height.equalToSuperview()
            case .fill:
                make.edges.equalToSuperview()
            }
        }
    }

    // MARK: - Public API
    
    public func setLeftButtons(_ buttons: [UIView]) {
        // English: Measure before reparenting so custom bounds remain the source of truth.
        // Español: Mide antes de cambiar la supervista para conservar los bounds personalizados.
        // 中文：在重新挂载按钮前完成测量，确保自定义 bounds 是唯一尺寸依据。
        self.leftContainerWidth = configureNavigationBarItems(buttons,
                                                               in: leftContainer,
                                                               spacing: PTAppBaseConfig.share.navBarButtonSpacing)
        updateContainerConstraints(leftContainer, isLeft: true)
        calculateMaxWidth()
    }
    
    public func setRightButtons(_ buttons: [UIView]) {
        // English: Use the same measured layout path as the system navigation container.
        // Español: Usa la misma ruta de layout medido que el contenedor de navegación del sistema.
        // 中文：复用系统导航容器使用的统一测量布局路径。
        self.rightContainerWidth = configureNavigationBarItems(buttons,
                                                                in: rightContainer,
                                                                spacing: PTAppBaseConfig.share.navBarButtonSpacing)
        updateContainerConstraints(rightContainer, isLeft: false)
        calculateMaxWidth()
    }
    
    private func stackTotalWidth(_ stack: UIStackView) -> CGFloat {
        if stack === leftContainer { return leftContainerWidth }
        if stack === rightContainer { return rightContainerWidth }
        return stack.arrangedSubviews.reduce(0) { partialResult, view in
            partialResult + navigationBarItemSize(for: view).width
        } + CGFloat(max(0, stack.arrangedSubviews.count - 1)) * stack.spacing
    }
    
    private func calculateMaxWidth() {
        let rightWidthTotal: CGFloat = stackTotalWidth(rightContainer)
        let leftWidthTotal: CGFloat = stackTotalWidth(leftContainer)

        let visibleRect = adaptiveVisibleRect()
        let containerWidth = visibleRect.width > 0 ? visibleRect.width : bounds.width
        let navigationSpacing = PTAppBaseConfig.share.navContainerSpacing
        let defaultSpace = PTAppBaseConfig.share.defaultViewSpace
        // English: Use the wider button group on both sides so a centered title never conflicts with an edge button.
        // Español: Usa el grupo de botones más ancho en ambos lados para que el título centrado nunca choque con un botón.
        // 中文：两侧都按较宽的按钮组计算，保证居中标题不会与边缘按钮产生约束冲突。
        let widestButtonGroup = max(leftWidthTotal, rightWidthTotal)
        let availableWidth = max(0, containerWidth - defaultSpace * 2 - navigationSpacing * 2 - widestButtonGroup * 2)
        let signature = WidthLayoutSignature(containerWidth: containerWidth,
                                              leftWidth: leftWidthTotal,
                                              rightWidth: rightWidthTotal,
                                              navigationSpacing: navigationSpacing,
                                              defaultSpace: defaultSpace,
                                              visibleRect: visibleRect)
        guard lastWidthLayoutSignature != signature else { return }
        lastWidthLayoutSignature = signature

        titleContainer.ptLayout.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(visibleRect.midX - bounds.midX)
            make.left.greaterThanOrEqualTo(leftContainer.ptLayout.right).offset(navigationSpacing)
            make.right.lessThanOrEqualTo(rightContainer.ptLayout.left).offset(-navigationSpacing)
            // English: Give the title container an explicit width so Auto Layout cannot reuse an old ambiguous frame.
            // Español: Define un ancho explícito para que Auto Layout no reutilice un frame antiguo y ambiguo.
            // 中文：为标题容器设置明确宽度，避免 Auto Layout 复用旧的模糊 frame。
            make.width.equalTo(availableWidth)
            make.height.equalTo(34)
        }

        let newWidth = availableWidth
        if newWidth != titleViewMAxWidth {
            titleViewMAxWidth = newWidth
        }
    }
}
