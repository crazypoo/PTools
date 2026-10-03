// English: Owns loaded page views, lifecycle callbacks and stable-ID cache policy.
// Español: Gestiona vistas cargadas, callbacks de ciclo de vida y caché por ID estable.
// 中文：负责已加载页面、生命周期回调和稳定 ID 缓存策略。

import UIKit

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
    func addSelectionObserver(_ observer: @escaping (PTPageSelectionEvent) -> Void) {
        selectionObservers.append(observer)
    }

    /// English: Adds an internal transition observer without replacing the public transition callback.
    /// Español: Añade un observador interno de transición sin reemplazar el callback público。
    /// 中文：增加内部过渡观察者，不覆盖业务公开过渡回调。
    func addTransitionObserver(_ observer: @escaping (PTPageTransition) -> Void) {
        transitionObservers.append(observer)
    }
}
