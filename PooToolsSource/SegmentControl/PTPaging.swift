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

@MainActor
private final class PTLoadedPage {
    let descriptor: PTPageDescriptor
    let page: any PTPage
    var didAppear = false

    init(descriptor: PTPageDescriptor, page: any PTPage) {
        self.descriptor = descriptor
        self.page = page
    }
}

/// English: A lazy, stable-ID horizontal page container that owns page lifecycle and cache policy.
/// Español: Contenedor horizontal perezoso con IDs estables que gestiona ciclo de vida y política de caché.
/// 中文：基于稳定 ID 的懒加载横向页面容器，统一负责生命周期和缓存策略。
@MainActor
open class PTPageContainer: UIView, UIScrollViewDelegate {
    public let scrollView = UIScrollView()
    public weak var hostViewController: UIViewController? {
        didSet { attachLoadedViewControllers() }
    }
    public var cachePolicy: PTPageCachePolicy = .adjacent(radius: 1) {
        didSet { updateLoadedPages() }
    }
    public private(set) var descriptors: [PTPageDescriptor] = []
    public private(set) var selectedID: AnyHashable?
    public private(set) var currentPage: (any PTPage)?
    public var onSelectionChanged: ((PTPageSelectionEvent) -> Void)?
    public var onTransition: ((PTPageTransition) -> Void)?
    public var onLifecycle: ((AnyHashable, PTPageLifecycle) -> Void)?
    /// English: Mirrors the old list-container switch while keeping the native scroll view public.
    /// Español: Equivale al interruptor antiguo del contenedor y mantiene público el scroll nativo.
    /// 中文：提供旧列表容器的横向滚动开关，同时保留原生 ScrollView 的公开访问。
    public var isListHorizontalScrollEnabled: Bool {
        get { scrollView.isScrollEnabled }
        set { scrollView.isScrollEnabled = newValue }
    }

    private var loadedPages: [AnyHashable: PTLoadedPage] = [:]
    private var isApplyingOffset = false
    private var isApplyingDescriptors = false
    private var selectionObservers = [((PTPageSelectionEvent) -> Void)]()
    private var transitionObservers = [((PTPageTransition) -> Void)]()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    private func configureView() {
        clipsToBounds = true
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.delegate = self
        addSubview(scrollView)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        scrollView.contentSize = CGSize(width: bounds.width * CGFloat(descriptors.count), height: bounds.height)
        for loaded in loadedPages.values {
            layout(loaded)
        }
        if let selectedID,
           let index = descriptors.firstIndex(where: { $0.id == selectedID }),
           !isApplyingOffset {
            let expected = CGFloat(index) * bounds.width
            if abs(scrollView.contentOffset.x - expected) > 0.5 {
                isApplyingOffset = true
                scrollView.setContentOffset(CGPoint(x: expected, y: 0), animated: false)
                isApplyingOffset = false
            }
        }
    }

    /// English: Applies page descriptors while preserving a stable selected identifier.
    /// Español: Aplica descriptores de página preservando el identificador seleccionado estable.
    /// 中文：应用页面描述，同时保留稳定的选中 ID。
    public func apply(pages newPages: [PTPageDescriptor],
                      selectedID preferredID: AnyHashable? = nil,
                      animated: Bool = false,
                      completion: (() -> Void)? = nil) {
        let oldID = selectedID
        var seen = Set<AnyHashable>()
        let nextDescriptors = newPages.filter { seen.insert($0.id).inserted }
        let nextIDs = Set(nextDescriptors.map(\.id))
        let nextID = preferredID.flatMap { id in nextIDs.contains(id) ? id : nil }
            ?? (oldID.flatMap { id in nextIDs.contains(id) ? id : nil })
            ?? nextDescriptors.first?.id

        if let oldID, oldID != nextID {
            sendLifecycle(.willDisappear, for: oldID)
            sendLifecycle(.didDisappear, for: oldID)
        }
        for id in Array(loadedPages.keys) where !nextIDs.contains(id) {
            unload(id: id)
        }

        descriptors = nextDescriptors
        isApplyingDescriptors = true
        if let nextID, nextID == oldID {
            selectedID = nextID
            currentPage = loadedPages[nextID]?.page
            updateLoadedPages()
        } else {
            selectedID = nil
            currentPage = nil
        }
        setNeedsLayout()
        layoutIfNeeded()
        if let nextID, nextID != oldID {
            select(id: nextID,
                   animated: animated,
                   origin: oldID == nil ? .restoration : .programmatic,
                   notify: true)
        }
        isApplyingDescriptors = false
        completion?()
    }

    /// English: Selects a page by stable identifier.
    /// Español: Selecciona una página mediante su identificador estable.
    /// 中文：通过稳定 ID 选择页面。
    public func select(id: AnyHashable,
                       animated: Bool = true,
                       origin: PTSegmentSelectionOrigin = .programmatic) {
        select(id: id, animated: animated, origin: origin, notify: true)
    }

    /// English: Selects a page by index while preserving the stable identifier as the source of truth.
    /// Español: Selecciona una página por índice conservando el identificador estable como fuente de verdad.
    /// 中文：按索引选择页面，但仍以稳定 ID 作为唯一状态来源。
    public func select(index: Int,
                       animated: Bool = true,
                       origin: PTSegmentSelectionOrigin = .programmatic) {
        guard descriptors.indices.contains(index) else { return }
        select(id: descriptors[index].id, animated: animated, origin: origin)
    }

    private func select(id: AnyHashable,
                        animated: Bool,
                        origin: PTSegmentSelectionOrigin,
                        notify: Bool) {
        guard let index = descriptors.firstIndex(where: { $0.id == id }) else { return }
        let oldID = selectedID
        let didChange = oldID != id
        if didChange, let oldID {
            sendLifecycle(.willDisappear, for: oldID)
            sendLifecycle(.didDisappear, for: oldID)
        }
        selectedID = id
        load(id: id)
        updateLoadedPages()
        let point = CGPoint(x: CGFloat(index) * bounds.width, y: 0)
        if bounds.width > 0 {
            isApplyingOffset = animated
            scrollView.setContentOffset(point, animated: animated)
            if !animated { isApplyingOffset = false }
        }
        currentPage = loadedPages[id]?.page
        if didChange {
            sendLifecycle(.willAppear, for: id)
            sendLifecycle(.didAppear, for: id)
        }
        if didChange || notify {
            let event = PTPageSelectionEvent(oldID: oldID, newID: id, origin: origin)
            onSelectionChanged?(event)
            selectionObservers.forEach { $0(event) }
        }
        if !animated { isApplyingOffset = false }
    }

    /// English: The current selected page index, if a descriptor exists.
    /// Español: Índice de la página seleccionada actual, si existe un descriptor.
    /// 中文：当前选中页面的索引，没有对应描述时返回 nil。
    public var selectedIndex: Int? {
        guard let selectedID else { return nil }
        return descriptors.firstIndex(where: { $0.id == selectedID })
    }

    /// English: Returns the current page's scroll view for status-bar taps and refresh coordination.
    /// Español: Devuelve el scroll de la página actual para el toque de la barra de estado y el refresco.
    /// 中文：返回当前页面的 ScrollView，供状态栏回顶和刷新协调使用。
    public var currentPageScrollView: UIScrollView? {
        guard let page = currentPage else { return nil }
        if let scrollable = page as? PTScrollablePage {
            return scrollable.pageScrollView
        }
        return firstScrollView(in: page.pageView)
    }

    // MARK: - Loaded Page Queries

    /// English: Returns cached page IDs in descriptor order without creating unloaded pages.
    /// Español: Devuelve los IDs de las páginas almacenadas en el orden de los descriptores sin crear páginas no cargadas.
    /// 中文：按描述顺序返回当前缓存中的页面 ID，不会创建尚未加载的页面。
    public var loadedPageIDs: [AnyHashable] {
        descriptors.compactMap { descriptor in
            loadedPages[descriptor.id] == nil ? nil : descriptor.id
        }
    }

    /// English: Returns whether a page is currently held by the container cache.
    /// Español: Indica si la caché del contenedor conserva actualmente una página.
    /// 中文：判断页面是否仍由容器缓存持有。
    public func isPageLoaded(id: AnyHashable) -> Bool {
        loadedPages[id] != nil
    }

    /// English: Returns a cached page without triggering loading or lifecycle callbacks.
    /// Español: Devuelve una página almacenada sin activar la carga ni callbacks del ciclo de vida.
    /// 中文：读取已缓存页面，不触发加载或生命周期回调；未加载时返回 nil。
    public func loadedPage(for id: AnyHashable) -> (any PTPage)? {
        loadedPages[id]?.page
    }

    /// English: Returns a cached page cast to the requested type without triggering loading.
    /// Español: Devuelve una página almacenada convertida al tipo solicitado sin activar la carga.
    /// 中文：将已缓存页面安全转换为指定类型，不触发加载；类型不匹配时返回 nil。
    public func loadedPage<Page: PTPage>(for id: AnyHashable, as type: Page.Type) -> Page? {
        loadedPage(for: id) as? Page
    }

    /// English: Returns the cached view controller for a controller-backed page without loading it.
    /// Español: Devuelve el controlador de una página respaldada por controlador sin cargarla.
    /// 中文：返回基于控制器页面的已缓存 ViewController，不会触发页面加载。
    public func loadedViewController(for id: AnyHashable) -> UIViewController? {
        (loadedPage(for: id) as? PTViewControllerPage)?.viewController
    }

    /// English: Returns the cached view controller cast to the requested type without loading it.
    /// Español: Devuelve el controlador almacenado convertido al tipo solicitado sin cargarlo.
    /// 中文：将已缓存 ViewController 安全转换为指定类型，不触发加载；类型不匹配时返回 nil。
    public func loadedViewController<T: UIViewController>(for id: AnyHashable, as type: T.Type) -> T? {
        loadedViewController(for: id) as? T
    }

    /// English: Returns cached view controllers in descriptor order without creating pages.
    /// Español: Devuelve los controladores almacenados en el orden de los descriptores sin crear páginas.
    /// 中文：按描述顺序返回已缓存的 ViewController，不会创建尚未加载的页面。
    public var loadedViewControllers: [UIViewController] {
        loadedPageIDs.compactMap { loadedViewController(for: $0) }
    }

    /// English: Returns cached view controllers of the requested type without triggering loading.
    /// Español: Devuelve los controladores almacenados del tipo solicitado sin activar la carga.
    /// 中文：按类型返回已缓存的 ViewController，不触发页面加载。
    public func loadedViewControllers<T: UIViewController>(of type: T.Type) -> [T] {
        loadedViewControllers.compactMap { $0 as? T }
    }

    /// English: Returns the cached view controller for the selected page without triggering loading.
    /// Español: Devuelve el controlador almacenado de la página seleccionada sin activar la carga.
    /// 中文：返回当前选中页面的已缓存 ViewController，不触发页面加载。
    public var currentViewController: UIViewController? {
        guard let selectedID else { return nil }
        return loadedViewController(for: selectedID)
    }

    /// English: Returns the selected cached view controller cast to the requested type.
    /// Español: Devuelve el controlador seleccionado almacenado convertido al tipo solicitado.
    /// 中文：将当前选中的已缓存 ViewController 安全转换为指定类型。
    public func currentViewController<T: UIViewController>(as type: T.Type) -> T? {
        currentViewController as? T
    }

    private func load(id: AnyHashable) {
        guard loadedPages[id] == nil,
              let descriptor = descriptors.first(where: { $0.id == id }) else { return }
        let page = descriptor.makePage()
        let loaded = PTLoadedPage(descriptor: descriptor, page: page)
        loadedPages[id] = loaded
        scrollView.addSubview(page.pageView)
        if let pageController = page as? PTViewControllerPage,
           let hostViewController {
            hostViewController.addChild(pageController.viewController)
            pageController.viewController.didMove(toParent: hostViewController)
        }
        layout(loaded)
        sendLifecycle(.willLoad, for: id)
        sendLifecycle(.didLoad, for: id)
    }

    private func layout(_ loaded: PTLoadedPage) {
        guard let index = descriptors.firstIndex(where: { $0.id == loaded.descriptor.id }) else { return }
        loaded.page.pageView.frame = CGRect(x: CGFloat(index) * bounds.width,
                                            y: 0,
                                            width: bounds.width,
                                            height: bounds.height)
    }

    private func updateLoadedPages() {
        guard let selectedIndex else { return }
        let wanted: Set<Int>
        switch cachePolicy {
        case .keepAllLoaded:
            wanted = Set(descriptors.indices)
        case .adjacent(let radius):
            let safeRadius = max(0, radius)
            wanted = Set(descriptors.indices.filter { abs($0 - selectedIndex) <= safeRadius })
        case .limit(let limit):
            let count = max(1, limit)
            wanted = Set(descriptors.indices.sorted { abs($0 - selectedIndex) < abs($1 - selectedIndex) }.prefix(count))
        case .discardOffscreen:
            wanted = [selectedIndex]
        }
        for index in wanted where descriptors.indices.contains(index) {
            load(id: descriptors[index].id)
        }
        let keepIDs = Set(wanted.compactMap { descriptors.indices.contains($0) ? descriptors[$0].id : nil })
        for id in Array(loadedPages.keys) where !keepIDs.contains(id) {
            unload(id: id)
        }
    }

    private func unload(id: AnyHashable) {
        guard let loaded = loadedPages.removeValue(forKey: id) else { return }
        if let pageController = loaded.page as? PTViewControllerPage,
           pageController.viewController.parent === hostViewController {
            pageController.viewController.willMove(toParent: nil)
            pageController.pageView.removeFromSuperview()
            pageController.viewController.removeFromParent()
        } else {
            loaded.page.pageView.removeFromSuperview()
        }
        sendLifecycle(.didUnload, for: id, page: loaded.page)
    }

    private func attachLoadedViewControllers() {
        guard let hostViewController else { return }
        for loaded in loadedPages.values {
            guard let pageController = loaded.page as? PTViewControllerPage,
                  pageController.viewController.parent == nil else { continue }
            hostViewController.addChild(pageController.viewController)
            pageController.viewController.didMove(toParent: hostViewController)
        }
    }

    private func sendLifecycle(_ lifecycle: PTPageLifecycle, for id: AnyHashable) {
        sendLifecycle(lifecycle, for: id, page: nil)
    }

    private func sendLifecycle(_ lifecycle: PTPageLifecycle,
                               for id: AnyHashable,
                               page explicitPage: (any PTPage)?) {
        guard let page = explicitPage ?? loadedPages[id]?.page else { return }
        if let observing = page as? PTPageLifecycleObserving {
            observing.pageContainer(self, didChange: lifecycle)
        }
        onLifecycle?(id, lifecycle)
    }

    private func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        for subview in view.subviews.reversed() {
            if let scrollView = firstScrollView(in: subview) { return scrollView }
        }
        return nil
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isApplyingOffset,
              !isApplyingDescriptors,
              let selectedIndex,
              bounds.width > 0,
              descriptors.indices.contains(selectedIndex),
              descriptors.count > 1 else { return }
        let raw = max(0, min(CGFloat(max(0, descriptors.count - 1)), scrollView.contentOffset.x / bounds.width))
        let lowerIndex = min(descriptors.count - 1, max(0, Int(floor(raw))))
        let upperIndex = min(descriptors.count - 1, max(0, Int(ceil(raw))))
        guard lowerIndex != upperIndex else { return }

        let fromIndex: Int
        let toIndex: Int
        let progress: CGFloat
        let direction: PTPageDirection
        if selectedIndex == lowerIndex {
            fromIndex = lowerIndex
            toIndex = upperIndex
            progress = raw - CGFloat(lowerIndex)
            direction = .forward
        } else if selectedIndex == upperIndex {
            fromIndex = upperIndex
            toIndex = lowerIndex
            progress = CGFloat(upperIndex) - raw
            direction = .backward
        } else {
            return
        }
        let transition = PTPageTransition(fromID: descriptors[fromIndex].id,
                                           toID: descriptors[toIndex].id,
                                           progress: progress,
                                           direction: direction)
        onTransition?(transition)
        transitionObservers.forEach { $0(transition) }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        commitScrollSelection(origin: .swipe)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isApplyingOffset = false
        commitScrollSelection(origin: .programmatic)
    }

    private func commitScrollSelection(origin: PTSegmentSelectionOrigin) {
        guard bounds.width > 0,
              !descriptors.isEmpty else { return }
        let rawIndex = Int((scrollView.contentOffset.x / bounds.width).rounded())
        guard descriptors.indices.contains(rawIndex) else { return }
        let index = rawIndex
        select(id: descriptors[index].id, animated: false, origin: origin, notify: true)
    }

    /// English: Adds an internal observer used by paging hosts without replacing the public callback.
    /// Español: Añade un observador interno para hosts de paginación sin reemplazar el callback público.
    /// 中文：增加供分页宿主使用的内部观察者，不覆盖业务公开回调。
    fileprivate func addSelectionObserver(_ observer: @escaping (PTPageSelectionEvent) -> Void) {
        selectionObservers.append(observer)
    }

    /// English: Adds an internal transition observer without replacing the public transition callback.
    /// Español: Añade un observador interno de transición sin reemplazar el callback público。
    /// 中文：增加内部过渡观察者，不覆盖业务公开过渡回调。
    fileprivate func addTransitionObserver(_ observer: @escaping (PTPageTransition) -> Void) {
        transitionObservers.append(observer)
    }
}

/// English: Dimension model for fixed or Auto Layout measured headers.
/// Español: Modelo de dimensión para cabeceras fijas o medidas por Auto Layout.
/// 中文：支持固定高度和 Auto Layout 自动测量的 Header 尺寸模型。
@MainActor
public enum PTPagingDimension {
    case fixed(CGFloat)
    case automatic
    case custom(@MainActor (CGFloat) -> CGFloat)
}

/// English: Header configuration used by PTPagingView.
/// Español: Configuración de cabecera usada por PTPagingView.
/// 中文：PTPagingView 使用的 Header 配置。
@MainActor
public struct PTPagingHeader {
    public let viewProvider: @MainActor () -> UIView
    public var height: PTPagingDimension

    public init(height: PTPagingDimension = .automatic,
                viewProvider: @escaping @MainActor () -> UIView) {
        self.height = height
        self.viewProvider = viewProvider
    }
}

/// English: Pinned header configuration.
/// Español: Configuración de cabecera fijada.
/// 中文：固定 Header 配置。
@MainActor
public struct PTPagingPinnedHeader {
    public let viewProvider: @MainActor () -> UIView
    public var height: CGFloat

    public init(height: CGFloat = 44,
                viewProvider: @escaping @MainActor () -> UIView) {
        self.height = height
        self.viewProvider = viewProvider
    }
}

/// English: Single layout calculation point for safe-area-aware paging geometry.
/// Español: Punto único de cálculo para la geometría de paginación consciente del área segura.
/// 中文：集中计算安全区相关分页几何尺寸。
@MainActor
public struct PTPagingLayoutEngine {
    public var safeAreaTop: CGFloat
    public var headerHeight: CGFloat
    public var pinnedHeight: CGFloat
    public var pageHeight: CGFloat

    public init(safeAreaTop: CGFloat = 0,
                headerHeight: CGFloat = 0,
                pinnedHeight: CGFloat = 0,
                pageHeight: CGFloat = 0) {
        self.safeAreaTop = safeAreaTop
        self.headerHeight = headerHeight
        self.pinnedHeight = pinnedHeight
        self.pageHeight = pageHeight
    }

    public var contentHeight: CGFloat { headerHeight + pinnedHeight + pageHeight }
    public var collapseLimit: CGFloat { max(0, headerHeight) }
}

/// English: Scroll ownership states used to prevent outer and inner scroll views fighting each other.
/// Español: Estados de propiedad usados para evitar conflictos entre scroll externo e interno.
/// 中文：防止外层和内层滚动互相抢占的滚动所有权状态。
@MainActor
public enum PTScrollOwnership {
    case outer
    case inner(pageID: AnyHashable)
    case transitioning
}

/// English: Refresh ownership policy for outer and page scroll views.
/// Español: Política de propiedad de refresco para el scroll externo y las páginas.
/// 中文：外层和页面滚动视图的刷新所有权策略。
@MainActor
public enum PTPagingRefreshPolicy {
    case outerOnly
    case innerOnly
    case perPage
    case custom
}

/// English: Refresh adapter keeps paging independent from any refresh library.
/// Español: El adaptador mantiene la paginación independiente de cualquier biblioteca de refresco.
/// 中文：刷新适配器让分页组件不依赖具体刷新库。
@MainActor
public protocol PTRefreshAdapter: AnyObject {
    var isRefreshing: Bool { get }
    func beginRefreshing()
    func endRefreshing()
}

/// English: Basic UIRefreshControl adapter.
/// Español: Adaptador básico para UIRefreshControl.
/// 中文：UIRefreshControl 的基础适配器。
@MainActor
public final class PTUIRefreshAdapter: PTRefreshAdapter {
    public let control: UIRefreshControl

    public init(control: UIRefreshControl = UIRefreshControl()) {
        self.control = control
    }

    public var isRefreshing: Bool { control.isRefreshing }
    public func beginRefreshing() { control.beginRefreshing() }
    public func endRefreshing() { control.endRefreshing() }
}

/// English: Main-actor nested scroll coordinator with deterministic offset normalization.
/// Español: Coordinador de scroll anidado en MainActor con normalización determinista de offsets.
/// 中文：在 MainActor 上运行、具备确定性偏移归一化的嵌套滚动协调器。
@MainActor
open class PTNestedScrollCoordinator {
    public private(set) var ownership: PTScrollOwnership = .outer
    public private(set) var isTransferringMomentum = false
    public var collapseLimit: CGFloat = 0
    public var onCollapseProgress: ((CGFloat) -> Void)?

    public weak var outerScrollView: UIScrollView?
    public weak var innerScrollView: UIScrollView?
    public var activePageID: AnyHashable?

    private var isApplyingCorrection = false
    private var innerProxy: PTScrollDelegateProxy?

    public init() {}

    public func bind(outer: UIScrollView,
                     inner: UIScrollView?,
                     pageID: AnyHashable? = nil,
                     collapseLimit: CGFloat) {
        innerProxy?.detach()
        outerScrollView = outer
        innerScrollView = inner
        activePageID = pageID
        self.collapseLimit = max(0, collapseLimit)
        ownership = .outer
        if let inner {
            let proxy = PTScrollDelegateProxy(scrollView: inner, original: inner.delegate)
            proxy.onDidScroll = { [weak self] scrollView in
                self?.handleInnerScroll(scrollView)
            }
            proxy.onDidEndDragging = { [weak self] _, decelerate in
                if !decelerate { self?.settle() }
            }
            proxy.onDidEndDecelerating = { [weak self] _ in
                self?.settle()
            }
            inner.delegate = proxy
            innerProxy = proxy
        }
        normalize()
    }

    public func handleOuterScroll(_ scrollView: UIScrollView) {
        guard !isApplyingCorrection else { return }
        let topInset = scrollView.adjustedContentInset.top
        let y = max(0, scrollView.contentOffset.y + topInset)
        let progress = collapseLimit == 0 ? 1 : min(1, y / collapseLimit)
        onCollapseProgress?(progress)
        if let innerScrollView,
           innerScrollView.contentOffset.y + innerScrollView.adjustedContentInset.top > 0,
           y < collapseLimit {
            isApplyingCorrection = true
            scrollView.contentOffset.y = collapseLimit - topInset
            isApplyingCorrection = false
            ownership = .inner(pageID: activePageID ?? AnyHashable(""))
        } else if y < collapseLimit {
            ownership = .outer
        }
        normalize()
    }

    public func handleInnerScroll(_ scrollView: UIScrollView) {
        guard !isApplyingCorrection else { return }
        let y = max(0, scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        if y > 0 {
            ownership = .inner(pageID: activePageID ?? AnyHashable(""))
            if let outerScrollView,
               outerScrollView.contentOffset.y + outerScrollView.adjustedContentInset.top < collapseLimit {
                isApplyingCorrection = true
                outerScrollView.contentOffset.y = collapseLimit - outerScrollView.adjustedContentInset.top
                scrollView.contentOffset.y = -scrollView.adjustedContentInset.top
                isApplyingCorrection = false
            }
        } else if let outerScrollView,
                  outerScrollView.contentOffset.y + outerScrollView.adjustedContentInset.top > 0 {
            ownership = .transitioning
            isApplyingCorrection = true
            let outerTopInset = outerScrollView.adjustedContentInset.top
            let outerY = max(0, outerScrollView.contentOffset.y + outerTopInset)
            let nextY = max(0, outerY - abs(scrollView.panGestureRecognizer.velocity(in: scrollView).y) * 0.001)
            outerScrollView.contentOffset.y = nextY - outerTopInset
            isApplyingCorrection = false
            isTransferringMomentum = true
        } else {
            ownership = .outer
        }
        normalize()
    }

    public func settle() {
        isTransferringMomentum = false
        ownership = .outer
        normalize()
    }

    private func normalize() {
        guard let outerScrollView else { return }
        let topInset = outerScrollView.adjustedContentInset.top
        let currentY = outerScrollView.contentOffset.y + topInset
        let y = min(max(0, currentY), collapseLimit)
        let normalizedOffset = y - topInset
        if abs(outerScrollView.contentOffset.y - normalizedOffset) > 0.5, !isApplyingCorrection {
            isApplyingCorrection = true
            outerScrollView.contentOffset.y = normalizedOffset
            isApplyingCorrection = false
        }
        let progress = collapseLimit == 0 ? 1 : min(1, y / collapseLimit)
        onCollapseProgress?(progress)
    }
}

@MainActor
private final class PTScrollDelegateProxy: NSObject, UIScrollViewDelegate {
    weak var scrollView: UIScrollView?
    weak var original: UIScrollViewDelegate?
    var onDidScroll: ((UIScrollView) -> Void)?
    var onDidEndDragging: ((UIScrollView, Bool) -> Void)?
    var onDidEndDecelerating: ((UIScrollView) -> Void)?

    init(scrollView: UIScrollView, original: UIScrollViewDelegate?) {
        self.scrollView = scrollView
        self.original = original
    }

    func detach() {
        if scrollView?.delegate === self {
            scrollView?.delegate = original
        }
        onDidScroll = nil
        onDidEndDragging = nil
        onDidEndDecelerating = nil
        scrollView = nil
        original = nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onDidScroll?(scrollView)
        original?.scrollViewDidScroll?(scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        original?.scrollViewWillBeginDragging?(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        onDidEndDragging?(scrollView, decelerate)
        original?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        original?.scrollViewWillEndDragging?(scrollView,
                                              withVelocity: velocity,
                                              targetContentOffset: targetContentOffset)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        original?.scrollViewWillBeginDecelerating?(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        onDidEndDecelerating?(scrollView)
        original?.scrollViewDidEndDecelerating?(scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        original?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        original?.viewForZooming?(in: scrollView)
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        original?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView,
                                 with view: UIView?,
                                 atScale scale: CGFloat) {
        original?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        original?.scrollViewDidZoom?(scrollView)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        original?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        original?.scrollViewDidScrollToTop?(scrollView)
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        original?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
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
        let progress = headerHeight == 0 ? 1 : min(1, max(0, logicalOffset / headerHeight))
        currentCollapseProgress = progress
        pinnedHeaderHost.isHidden = pinnedConfiguration == nil || progress == 0
        pinnedHeaderHost.alpha = progress
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
