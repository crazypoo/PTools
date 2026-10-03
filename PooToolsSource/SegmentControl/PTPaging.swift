// English: Native horizontal paging, header layout, nested scrolling and integration contracts.
// Español: Contratos nativos de paginación horizontal, diseño de cabecera, desplazamiento anidado e integración.
// 中文：原生横向分页、Header 布局、嵌套滚动和联动契约。

import UIKit

/// English: A page transition emitted by PTPageContainer.
/// Español: Una transición de página emitida por PTPageContainer.
/// 中文：PTPageContainer 发出的页面过渡事件。
@MainActor
public struct PTPageTransition {
    public let fromID: AnyHashable
    public let toID: AnyHashable
    public let progress: CGFloat
    public let direction: PTPageDirection

    public init(fromID: AnyHashable,
                toID: AnyHashable,
                progress: CGFloat,
                direction: PTPageDirection) {
        self.fromID = fromID
        self.toID = toID
        self.progress = min(max(progress, 0), 1)
        self.direction = direction
    }
}

/// English: Selection event emitted by the page container.
/// Español: Evento de selección emitido por el contenedor de páginas.
/// 中文：页面容器发出的选择事件。
@MainActor
public struct PTPageSelectionEvent {
    public let oldID: AnyHashable?
    public let newID: AnyHashable
    public let origin: PTSegmentSelectionOrigin
}

/// English: Direction resolver shared by horizontal paging, header carousels and navigation gestures.
/// Español: Resolutor de dirección compartido por paginación, carruseles y gestos de navegación.
/// 中文：横向分页、Header 轮播和导航手势共用的方向解析器。
@MainActor
public struct PTGestureDirectionResolver {
    public var threshold: CGFloat

    public init(threshold: CGFloat = 1.15) {
        self.threshold = max(1, threshold)
    }

    public func resolve(velocity: CGPoint) -> PTGestureDirection {
        guard velocity != .zero else { return .undetermined }
        if abs(velocity.x) > abs(velocity.y) * threshold { return .horizontal }
        if abs(velocity.y) > abs(velocity.x) * threshold { return .vertical }
        return .undetermined
    }
}

/// English: Gesture direction result.
/// Español: Resultado de dirección del gesto.
/// 中文：手势方向结果。
@MainActor
public enum PTGestureDirection {
    case horizontal
    case vertical
    case undetermined
}

/// English: Lightweight gesture arena policy for paging surfaces.
/// Español: Política ligera de arena de gestos para superficies paginadas.
/// 中文：分页表面的轻量手势仲裁策略。
@MainActor
public final class PTGestureArena {
    public var resolver = PTGestureDirectionResolver()
    public var allowsSimultaneousNavigationPop = true
    /// English: Keep unrelated pan gestures independent so table-cell swipe actions keep priority.
    /// Español: Mantiene independientes los gestos de paneo no relacionados para que las acciones de las celdas con deslizamiento tengan prioridad.
    /// 中文：让无关的 Pan 手势保持独立，确保列表 Cell 的侧滑操作优先响应。
    public var allowsSimultaneousPanGestures = false
    public weak var navigationController: UINavigationController?
    public weak var outerScrollView: UIScrollView?
    public weak var innerScrollView: UIScrollView?
    public weak var horizontalScrollView: UIScrollView?

    public init() {}

    public func shouldRecognizeSimultaneously(_ first: UIGestureRecognizer,
                                              _ second: UIGestureRecognizer) -> Bool {
        if allowsSimultaneousNavigationPop {
            let popGesture = navigationController?.interactivePopGestureRecognizer
            if first === popGesture || second === popGesture {
                return true
            }
        }

        let firstIsOuter = first === outerScrollView?.panGestureRecognizer
        let secondIsOuter = second === outerScrollView?.panGestureRecognizer
        let firstIsInner = first === innerScrollView?.panGestureRecognizer
        let secondIsInner = second === innerScrollView?.panGestureRecognizer
        let firstIsHorizontal = first === horizontalScrollView?.panGestureRecognizer
        let secondIsHorizontal = second === horizontalScrollView?.panGestureRecognizer
        let isNestedScrollPair = (firstIsOuter && secondIsInner) || (firstIsInner && secondIsOuter)
        let isKnownPagingPair = isNestedScrollPair || (firstIsOuter && secondIsHorizontal) || (firstIsHorizontal && secondIsOuter)
        if isKnownPagingPair {
            return true
        }

        let bothArePan = first is UIPanGestureRecognizer && second is UIPanGestureRecognizer
        return allowsSimultaneousPanGestures && bothArePan
    }
}

/// English: Generic adapter for an interactive pop gesture without depending on a third-party library.
/// Español: Adaptador genérico para el gesto pop interactivo sin depender de una biblioteca externa.
/// 中文：不依赖第三方库的通用交互式返回手势适配器。
@MainActor
public final class PTNavigationGestureAdapter {
    public weak var navigationController: UINavigationController?
    public var isEnabledAtFirstPage = true

    public init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    public func shouldBegin(pageIndex: Int) -> Bool {
        guard let navigationController else { return false }
        if navigationController.viewControllers.count <= 1 { return false }
        return pageIndex == 0 ? isEnabledAtFirstPage : true
    }
}

/// English: Header, pinned header and page host with basic smooth nested-scroll handoff.
/// Español: Cabecera, cabecera fijada y host de páginas con transferencia básica de scroll suave.
/// 中文：包含 Header、固定 Header 和页面容器的基础平滑嵌套滚动 View。
@MainActor
open class PTPagingView: UIView, UIScrollViewDelegate {
    public let outerScrollView = UIScrollView()
    public let pageContainer: PTPageContainer
    /// English: Compatibility name for callers migrating from a list-container property.
    /// Español: Nombre compatible para llamadas que migran desde una propiedad de contenedor de listas.
    /// 中文：兼容旧列表容器属性的命名入口。
    public var listContainerView: PTPageContainer { pageContainer }
    /// English: Compatibility name for the outer paging scroll view.
    /// Español: Nombre compatible para el scroll exterior de paginación.
    /// 中文：外层分页 ScrollView 的兼容命名入口。
    public var mainScrollView: UIScrollView { outerScrollView }
    public weak var hostViewController: UIViewController? {
        didSet {
            pageContainer.hostViewController = hostViewController
            gestureArena.navigationController = hostViewController?.navigationController
        }
    }
    /// English: Forwards the native refresh control to the outer scroll view.
    /// Español: Reenvía el control de refresco nativo al scroll exterior.
    /// 中文：将原生刷新控件转发到外层 ScrollView。
    public var refreshControl: UIRefreshControl? {
        get { outerScrollView.refreshControl }
        set { outerScrollView.refreshControl = newValue }
    }
    /// English: Controls horizontal page scrolling without exposing a third-party list container.
    /// Español: Controla el desplazamiento horizontal sin exponer un contenedor de terceros.
    /// 中文：控制横向页面滚动，不暴露第三方列表容器。
    public var isListHorizontalScrollEnabled: Bool {
        get { pageContainer.isListHorizontalScrollEnabled }
        set { pageContainer.isListHorizontalScrollEnabled = newValue }
    }
    public let headerHost = UIView()
    public let pinnedHeaderHost = UIView()
    public let nestedScrollCoordinator = PTNestedScrollCoordinator()
    public let gestureArena = PTGestureArena()
    public var refreshPolicy: PTPagingRefreshPolicy = .perPage
    public var collapseProgress: CGFloat { currentCollapseProgress }
    public var onCollapseProgress: ((CGFloat) -> Void)?
    public var onStretchProgress: ((CGFloat) -> Void)?

    private var headerConfiguration: PTPagingHeader?
    private var pinnedConfiguration: PTPagingPinnedHeader?
    private var headerHeight: CGFloat = 0
    private var currentCollapseProgress: CGFloat = 0
    private var isUpdatingLayout = false

    public init(pageContainer: PTPageContainer = PTPageContainer(frame: .zero)) {
        self.pageContainer = pageContainer
        super.init(frame: .zero)
        configureView()
    }

    public override init(frame: CGRect) {
        self.pageContainer = PTPageContainer(frame: .zero)
        super.init(frame: frame)
        configureView()
    }

    public required init?(coder: NSCoder) {
        self.pageContainer = PTPageContainer(frame: .zero)
        super.init(coder: coder)
        configureView()
    }

    private func configureView() {
        clipsToBounds = true
        outerScrollView.delegate = self
        outerScrollView.alwaysBounceVertical = true
        outerScrollView.alwaysBounceHorizontal = false
        outerScrollView.showsVerticalScrollIndicator = false
        outerScrollView.contentInsetAdjustmentBehavior = .never
        outerScrollView.scrollsToTop = true
        gestureArena.outerScrollView = outerScrollView
        gestureArena.horizontalScrollView = pageContainer.scrollView
        addSubview(outerScrollView)
        outerScrollView.addSubview(headerHost)
        outerScrollView.addSubview(pageContainer)
        addSubview(pinnedHeaderHost)
        pinnedHeaderHost.isHidden = true
        pageContainer.addSelectionObserver { [weak self] _ in self?.bindCurrentPageScroll() }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard !isUpdatingLayout else { return }
        isUpdatingLayout = true
        outerScrollView.frame = bounds
        headerHeight = resolvedHeaderHeight()
        let pinnedHeight = pinnedConfiguration?.height ?? 0
        headerHost.frame = CGRect(x: 0, y: 0, width: bounds.width, height: headerHeight)
        headerHost.subviews.first?.frame = headerHost.bounds
        pageContainer.frame = CGRect(x: 0,
                                     y: headerHeight + pinnedHeight,
                                     width: bounds.width,
                                     height: bounds.height)
        outerScrollView.contentSize = CGSize(width: bounds.width,
                                             height: headerHeight + pinnedHeight + bounds.height)
        pinnedHeaderHost.frame = CGRect(x: 0,
                                        y: safeAreaInsets.top,
                                        width: bounds.width,
                                        height: pinnedHeight)
        pinnedHeaderHost.subviews.first?.frame = pinnedHeaderHost.bounds
        nestedScrollCoordinator.collapseLimit = headerHeight
        updatePinnedVisibility()
        isUpdatingLayout = false
    }

    /// English: Installs a header and invalidates its measured height.
    /// Español: Instala una cabecera e invalida su altura medida.
    /// 中文：安装 Header 并让其自动高度重新计算。
    public func setHeader(_ header: PTPagingHeader?) {
        headerHost.subviews.forEach { $0.removeFromSuperview() }
        headerConfiguration = header
        if let header {
            let view = header.viewProvider()
            headerHost.addSubview(view)
            view.frame = headerHost.bounds
        }
        invalidateHeaderLayout()
    }

    /// English: Installs a pinned header without coupling it to PTSegmentedView.
    /// Español: Instala una cabecera fijada sin acoplarla a PTSegmentedView.
    /// 中文：安装固定 Header，不强制与 PTSegmentedView 耦合。
    public func setPinnedHeader(_ header: PTPagingPinnedHeader?) {
        pinnedHeaderHost.subviews.forEach { $0.removeFromSuperview() }
        pinnedConfiguration = header
        if let header {
            let view = header.viewProvider()
            pinnedHeaderHost.addSubview(view)
            view.frame = pinnedHeaderHost.bounds
        }
        setNeedsLayout()
        layoutIfNeeded()
    }

    /// English: Re-measures an automatic header after asynchronous content changes.
    /// Español: Vuelve a medir una cabecera automática tras cambios de contenido asíncronos.
    /// 中文：异步内容变化后重新测量自动 Header。
    public func invalidateHeaderLayout(animated: Bool = false) {
        let update = { [weak self] in
            guard let self else { return }
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: update)
        } else {
            update()
        }
    }

    private func resolvedHeaderHeight() -> CGFloat {
        guard let header = headerConfiguration else { return 0 }
        switch header.height {
        case .fixed(let height):
            return max(0, height)
        case .custom(let resolver):
            return max(0, resolver(bounds.width))
        case .automatic:
            let fitting = headerHost.systemLayoutSizeFitting(CGSize(width: bounds.width,
                                                                    height: UIView.layoutFittingCompressedSize.height),
                                                             withHorizontalFittingPriority: .required,
                                                             verticalFittingPriority: .fittingSizeLevel)
            return max(0, fitting.height > 0 ? fitting.height : headerHost.subviews.first?.bounds.height ?? 0)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === outerScrollView else { return }
        nestedScrollCoordinator.handleOuterScroll(scrollView)
        updatePinnedVisibility()
        let logicalOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        if logicalOffset < 0, headerHeight > 0 {
            onStretchProgress?(min(1, abs(logicalOffset) / headerHeight))
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { nestedScrollCoordinator.settle() }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        nestedScrollCoordinator.settle()
    }

    private func updatePinnedVisibility() {
        let logicalOffset = outerScrollView.contentOffset.y + outerScrollView.adjustedContentInset.top
        let clampedOffset = max(0, logicalOffset)
        let progress = headerHeight == 0 ? 1 : min(1, max(0, clampedOffset / headerHeight))
        currentCollapseProgress = progress
        guard pinnedConfiguration != nil else {
            pinnedHeaderHost.isHidden = true
            onCollapseProgress?(progress)
            return
        }
        pinnedHeaderHost.isHidden = false
        pinnedHeaderHost.alpha = 1
        let pinnedHeight = pinnedConfiguration?.height ?? 0
        // 初始：Header 下方
        // Header 收起后：固定在顶部
        let y = safeAreaInsets.top + max(0, headerHeight - clampedOffset)
        pinnedHeaderHost.frame = CGRect(x: 0, y: y, width: bounds.width, height: pinnedHeight)
        pinnedHeaderHost.subviews.first?.frame = pinnedHeaderHost.bounds
        onCollapseProgress?(progress)
    }

    private func bindCurrentPageScroll() {
        guard let page = pageContainer.currentPage else { return }
        let scrollView: UIScrollView?
        if let scrollable = page as? PTScrollablePage {
            scrollView = scrollable.pageScrollView
        } else if let viewControllerPage = page as? PTViewControllerPage {
            scrollView = findScrollView(in: viewControllerPage.pageView)
        } else {
            scrollView = findScrollView(in: page.pageView)
        }
        scrollView?.scrollsToTop = false
        gestureArena.innerScrollView = scrollView
        nestedScrollCoordinator.bind(outer: outerScrollView,
                                     inner: scrollView,
                                     pageID: pageContainer.selectedID,
                                     collapseLimit: headerHeight)
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        for subview in view.subviews.reversed() {
            if let scrollView = findScrollView(in: subview) { return scrollView }
        }
        return nil
    }

    /// English: Scrolls the outer header and the active list to their top positions.
    /// Español: Desplaza la cabecera exterior y la lista activa hasta sus posiciones superiores.
    /// 中文：将外层 Header 和当前列表滚动到顶部。
    public func scrollCurrentPageToTop(animated: Bool = true) {
        let outerY = -outerScrollView.adjustedContentInset.top
        outerScrollView.setContentOffset(CGPoint(x: outerScrollView.contentOffset.x, y: outerY), animated: animated)
        if let innerScrollView = pageContainer.currentPageScrollView {
            let innerY = -innerScrollView.adjustedContentInset.top
            innerScrollView.setContentOffset(CGPoint(x: innerScrollView.contentOffset.x, y: innerY), animated: animated)
        }
    }

    /// English: Host-facing gesture policy for nested paging and navigation-pop gestures.
    /// Español: Política de gestos expuesta al host para paginación anidada y retorno de navegación.
    /// 中文：提供给宿主的嵌套分页和导航返回手势协作策略。
    public func shouldRecognizeSimultaneously(_ first: UIGestureRecognizer,
                                               _ second: UIGestureRecognizer) -> Bool {
        gestureArena.shouldRecognizeSimultaneously(first, second)
    }
}

/// English: Connects one segmented view and one page container without mutual strong ownership.
/// Español: Conecta una vista segmentada y un contenedor de páginas sin propiedad fuerte mutua.
/// 中文：连接分段 View 和页面容器，避免两者相互强持有。
@MainActor
public final class PTSegmentedPagingCoordinator {
    public weak var segmentedView: PTSegmentedView?
    public weak var pageContainer: PTPageContainer?
    private var isSynchronizing = false

    public init(segmentedView: PTSegmentedView, pageContainer: PTPageContainer) {
        self.segmentedView = segmentedView
        self.pageContainer = pageContainer
        segmentedView.addSelectionObserver { [weak self] event in
            guard let self, !self.isSynchronizing, let id = event.newSelection.selectedID else { return }
            self.isSynchronizing = true
            self.pageContainer?.select(id: id, animated: true, origin: event.origin)
            self.isSynchronizing = false
        }
        pageContainer.addSelectionObserver { [weak self] event in
            guard let self, !self.isSynchronizing else { return }
            self.isSynchronizing = true
            self.segmentedView?.select(id: event.newID, animated: true, origin: event.origin == .programmatic ? .programmatic : .swipe)
            self.isSynchronizing = false
        }
        pageContainer.addTransitionObserver { [weak self] transition in
            guard let self,
                  let segmentedView = self.segmentedView else { return }
            segmentedView.update(transition: PTSegmentTransition(fromID: transition.fromID,
                                                                 toID: transition.toID,
                                                                 progress: transition.progress,
                                                                 direction: transition.direction))
        }
    }

    /// English: Applies matching stable-ID items and pages in one transaction.
    /// Español: Aplica elementos y páginas con los mismos IDs en una sola transacción.
    /// 中文：在一次事务中应用具有相同稳定 ID 的分段项和页面。
    public func apply(items: [PTSegmentItem], pages: [PTPageDescriptor], animated: Bool = true) {
        let pageIDs = Set(pages.map(\.id))
        let safeItems = items.filter { pageIDs.contains($0.id) }
        let preferredID = segmentedView?.selectionState.selectedID ?? pageContainer?.selectedID ?? safeItems.first?.id
        segmentedView?.apply(items: safeItems, animatingDifferences: animated)
        pageContainer?.apply(pages: pages, selectedID: preferredID, animated: animated)
    }
}
