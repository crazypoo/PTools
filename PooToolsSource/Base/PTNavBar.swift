//
//  PTNavBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/9/30.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

@MainActor
open class PTNavBar: PTNavigationBarContainer {

    // English: Resolve the standalone bar row from its own bounds and safe area.
    // Español: Resuelve la fila de la barra independiente desde sus propios bounds y área segura.
    // 中文：根据独立导航栏自身的 bounds 和安全区解析内容行。
    private func navigationContentRow() -> CGRect {
        guard !bounds.isEmpty else { return .zero }
        let hostBounds = CGRect(origin: .zero, size: bounds.size)
        let safeInsets = UIEdgeInsets(top: max(0, safeAreaInsets.top),
                                      left: max(0, safeAreaInsets.left),
                                      bottom: max(0, safeAreaInsets.bottom),
                                      right: max(0, safeAreaInsets.right))
        let insetRect = hostBounds.inset(by: safeInsets)
        let safeRect = insetRect.isEmpty ? hostBounds : insetRect
        let input = PTNavigationContentRowInput(hostBounds: hostBounds,
                                                hostSafeRect: safeRect,
                                                fallbackRowRect: safeRect,
                                                evidence: .fallback)
        return PTNavigationContentRowResolver.resolve(input)?.contentRect ?? safeRect
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
    
    fileprivate var titleViewMAxWidth: CGFloat = 0
    
    public enum PTTitleViewMode: Sendable {
        case auto
        case fixed(CGFloat)
        case fill
    }

    public var titleViewMode: PTTitleViewMode = .fill {
        didSet {
            setNeedsLayout()
        }
    }

    public var titleView: UIView? {
        didSet {
            if oldValue === titleView {
                setNeedsLayout()
                return
            }

            oldValue?.snp.removeConstraints()
            oldValue?.removeFromSuperview()
            guard let newView = titleView else {
                clearTitleLayout()
                return
            }

            newView.snp.removeConstraints()
            newView.removeFromSuperview()
            // English: Keep the title container visible for the new title view.
            // Español: Mantiene visible el contenedor para la nueva vista de título.
            // 中文：为新的标题视图保持标题容器可见。
            titleContainer.isHidden = false
            titleContainer.addSubview(newView)
            titleContainer.isUserInteractionEnabled = true
            setNeedsLayout()
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
        
        titleContainer.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(0)
        }
    }
    
    // 🔥 核心逻辑 1：接管并重构父类 topBarContainer 的约束
    private func updateTopBarContainerConstraints() {
        // topBarContainer 是父类 PTNavigationBarContainer 里的属性
        topBarContainer.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            
            if isFakeNav {
                // English: A standalone bar must occupy exactly the height supplied by its host view.
                // Español: Una barra independiente debe ocupar exactamente la altura de su vista anfitriona.
                // 中文：伪导航栏必须严格使用宿主 View 提供的实际高度。
                make.top.bottom.equalToSuperview()
            } else {
                // English: Use the resolved local content row instead of a global bar-height estimate.
                // Español: Usa la fila local resuelta en vez de una estimación global de altura.
                // 中文：使用解析出的局部内容行，不再依赖全局导航栏高度估算。
                let row = navigationContentRow()
                make.top.equalToSuperview().offset(row.minY)
                make.height.equalTo(row.height)
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
        
        container.snp.remakeConstraints { make in
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
                // English: Align both button groups to the same resolved local content row.
                // Español: Alinea ambos grupos de botones con la misma fila local resuelta.
                // 中文：让左右按钮组共同对齐到同一个局部内容行。
                let row = navigationContentRow()
                make.top.equalToSuperview().offset(row.minY)
                make.height.equalTo(row.height)
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
        let navigationSpacing = PTAppBaseConfig.share.navContainerSpacing
        let defaultSpace = PTAppBaseConfig.share.defaultViewSpace
        let containerWidth = visibleRect.width > 0 ? visibleRect.width : bounds.width
        let signature = WidthLayoutSignature(containerWidth: containerWidth,
                                              leftWidth: leftWidthTotal,
                                              rightWidth: rightWidthTotal,
                                              navigationSpacing: navigationSpacing,
                                              defaultSpace: defaultSpace,
                                              visibleRect: visibleRect)
        if lastWidthLayoutSignature != signature {
            lastWidthLayoutSignature = signature
        }

        guard let view = titleView else {
            if titleLayoutSignature != nil || !titleContainer.isHidden {
                clearTitleLayout()
            }
            return
        }

        let mode: PTNavigationTitleLayoutMode
        let fixedWidth: CGFloat?
        switch titleViewMode {
        case .auto:
            mode = .centerMeasured
            fixedWidth = nil
        case .fixed(let width):
            mode = .centerFixed(width)
            fixedWidth = width
        case .fill:
            mode = .fillAvailable
            fixedWidth = nil
        }

        // English: Keep the fake-navigation content row stable while resolving dynamic title sizes.
        // Español: Mantiene estable la fila de contenido de la barra falsa al medir títulos dinámicos.
        // 中文：解析动态标题尺寸时，保持伪导航栏内容行高度稳定。
        let contentRowHeight = min(34, max(0, visibleRect.height))
        let layout = navigationTitleLayout(for: view,
                                           mode: mode,
                                           visibleRect: visibleRect,
                                           availableHeight: contentRowHeight,
                                           fixedWidth: fixedWidth)
        titleViewMAxWidth = layout.result.titleFrame.width
        titleLayoutMode = mode

        let needsUpdate = titleLayoutSignature != layout.input || titleLayoutView !== view
        titleLayoutView = view
        guard needsUpdate else {
            titleContainer.isHidden = !layout.result.shouldDisplay
            return
        }

        titleLayoutSignature = layout.input
        if !layout.result.shouldDisplay {
            titleContainer.isHidden = true
            titleContainer.isUserInteractionEnabled = false
            titleContainer.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(0)
            }
            view.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            return
        }

        titleContainer.isHidden = false
        titleContainer.isUserInteractionEnabled = true
        let frame = layout.result.titleFrame
        titleContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(frame.minX)
            make.top.equalToSuperview().offset(frame.minY)
            make.width.equalTo(frame.width)
            make.height.equalTo(frame.height)
        }
        view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
