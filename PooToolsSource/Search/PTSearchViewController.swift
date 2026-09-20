//
//  PTSearchViewController.swift
//  PooTools
//
// English: A reusable search container built on PTBaseViewController, PTListViewController, PTCollectionView, and PTSearchBar.
// Español: Un contenedor de búsqueda reutilizable basado en PTBaseViewController, PTListViewController, PTCollectionView y PTSearchBar.
// 中文：基于 PTBaseViewController、PTListViewController、PTCollectionView 和 PTSearchBar 的可复用搜索容器。
//

import UIKit
import AttributedString

#if SWIFT_PACKAGE
import ptools
import PooToolsSearchBar
#endif

@MainActor
private final class PTSearchItemBox<Value: Sendable>: NSObject {
    let value: Value

    init(value: Value) {
        self.value = value
        super.init()
    }
}

@MainActor
private final class PTSearchTextBox: NSObject {
    let value: String

    init(value: String) {
        self.value = value
        super.init()
    }
}

@MainActor
private final class PTSearchDefaultCell: UICollectionViewCell {
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .label
        PTUIAccessibility.applyDynamicType(to: titleLabel, font: .preferredFont(forTextStyle: .body))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(text: String) {
        titleLabel.text = text
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}

@MainActor
open class PTSearchViewController<Item: Sendable>: PTListViewController {
    public let searchConfiguration: PTSearchConfiguration
    public private(set) lazy var searchBar: PTSearchBar = makeSearchBar()
    public var collectionView: PTCollectionView { listView }

    public private(set) var state: PTSearchState = .idle
    public private(set) var items: [Item] = []
    public private(set) var keyword = ""

    open var searchMode: PTSearchMode
    public var historyProvider: (any PTSearchHistoryProvider)?

    public var searchStateDidChange: (@MainActor (PTSearchState) -> Void)?
    public var keywordDidChange: (@MainActor (String) -> Void)?
    public var resultDidSelect: (@MainActor (Item) -> Void)?

    private let taskCoordinator = PTSearchTaskCoordinator()
    private var resultProviderHandler: (@Sendable (String) async throws -> [Item])?
    private var suggestionProviderHandler: (@Sendable (String) async throws -> [String])?
    private var localProviderHandler: (@Sendable (String) async throws -> [Item])?
    private var remoteProviderHandler: (@Sendable (String) async throws -> [Item])?
    private var currentSnapshot: PTSearchSnapshot?
    private var currentSuggestions: [String] = []
    private var currentHistory: [String] = []
    private var pagination: PTSearchPagination
    private var isSearchActive = false
    private var presentationContext: PTSearchPresentationContext?
    private var languageObserver: NSObjectProtocol?

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.setTitle("Cancel".localized(), for: .normal)
        button.accessibilityIdentifier = "PooTools.Search.Cancel"
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    public init(configuration: PTSearchConfiguration = .standard) {
        self.searchConfiguration = configuration
        self.searchMode = configuration.mode
        self.historyProvider = PTUserDefaultsSearchHistoryProvider(maximumCount: configuration.historyMaximumCount)
        self.pagination = PTSearchPagination(pageSize: configuration.paginationPageSize)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        let configuration = PTSearchConfiguration.standard
        self.searchConfiguration = configuration
        self.searchMode = configuration.mode
        self.historyProvider = PTUserDefaultsSearchHistoryProvider(maximumCount: configuration.historyMaximumCount)
        self.pagination = PTSearchPagination(pageSize: configuration.paginationPageSize)
        super.init(coder: coder)
    }

    deinit {
        MainActor.gcdRunUnsafely {
            if let languageObserver {
                NotificationCenter.default.removeObserver(languageObserver)
            }
        }
        // English: PTSearchTaskCoordinator cancels its owned tasks during deinitialization.
        // Español: PTSearchTaskCoordinator cancela sus tareas durante la desinicialización.
        // 中文：PTSearchTaskCoordinator 会在销毁时取消自己持有的任务。
    }

    // English: A list-style configuration keeps layout ownership in PTCollectionView.
    // Español: La configuración de lista mantiene la propiedad del layout en PTCollectionView.
    // 中文：列表配置继续把布局职责交给 PTCollectionView。
    open override func makeListViewConfiguration() -> PTCollectionViewConfig {
        let configuration = super.makeListViewConfiguration()
        configuration.topRefresh = searchConfiguration.enablesRefresh
        configuration.enableSmartPrefetch = searchConfiguration.enablesPagination
        configuration.prefetchThreshold = 3
        configuration.refreshWithoutAnimation = false
        return configuration
    }

    open override func configureListView(_ listView: PTCollectionView) {
        super.configureListView(listView)
        configureSearchList(listView)
    }

    open override func prepareListViewLayout(_ listView: PTCollectionView) {
        super.prepareListViewLayout(listView)
        configureSearchBarHandlers()

        switch searchConfiguration.placement {
        case .contentTop, .navigationBarExpanded:
            guard searchBar.superview == nil else { return }
            view.addSubview(searchBar)
            searchBar.translatesAutoresizingMaskIntoConstraints = false
        case .navigationBar:
            break
        case .custom:
            installCustomSearchBar(searchBar)
        }
    }

    open override func installListViewConstraints(_ listView: PTCollectionView) {
        switch searchConfiguration.placement {
        case .contentTop, .navigationBarExpanded:
            let safeArea = view.safeAreaLayoutGuide
            listView.translatesAutoresizingMaskIntoConstraints = false
            var constraints = [
                searchBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
                searchBar.topAnchor.constraint(equalTo: safeArea.topAnchor),
                searchBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
                listView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
                listView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
                listView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
                listView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8)
            ]
            if searchConfiguration.showsCancelButton {
                cancelButton.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(cancelButton)
                constraints.append(contentsOf: [
                    searchBar.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -8),
                    cancelButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
                    cancelButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor)
                ])
            } else {
                constraints.append(searchBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor))
                cancelButton.isHidden = true
            }
            NSLayoutConstraint.activate(constraints)
        case .navigationBar, .custom:
            super.installListViewConstraints(listView)
        }
    }

    open override func prefersLargeTitle() -> Bool {
        if searchConfiguration.placement == .navigationBarExpanded {
            return true
        }
        return super.prefersLargeTitle()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchBarHandlers()
        collectionView.contentCollectionView.register(PTSearchDefaultCell.self,
                                                      forCellWithReuseIdentifier: String(describing: PTSearchDefaultCell.self))

        languageObserver = NotificationCenter.default.addObserver(forName: LanguageDidChangedKey,
                                                                  object: nil,
                                                                  queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadLocalization()
            }
        }

        if searchConfiguration.automaticallyShowsHistory {
            loadHistory()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true else { return }
        deactivateSearch()
    }

    // English: Register a typed provider without exposing an existential with an associated type to callers.
    // Español: Registra un provider tipado sin exponer a los clientes un existential con tipo asociado.
    // 中文：注册类型安全的 Provider，同时不要求调用方处理带关联类型的 existential。
    public func setResultProvider<Provider: PTSearchResultProvider>(_ provider: Provider) where Provider.Item == Item {
        resultProviderHandler = { keyword in
            try await provider.search(keyword: keyword)
        }
    }

    public func setSuggestionProvider<Provider: PTSearchSuggestionProvider>(_ provider: Provider) where Provider.Suggestion == String {
        suggestionProviderHandler = { keyword in
            try await provider.suggestions(for: keyword)
        }
    }

    public func setLocalProvider<Provider: PTSearchResultProvider>(_ provider: Provider) where Provider.Item == Item {
        localProviderHandler = { keyword in
            try await provider.search(keyword: keyword)
        }
    }

    public func setRemoteProvider<Provider: PTSearchResultProvider>(_ provider: Provider) where Provider.Item == Item {
        remoteProviderHandler = { keyword in
            try await provider.search(keyword: keyword)
        }
    }

    // English: Activate only presentation and focus; data requests still follow the state machine.
    // Español: La activación solo cambia la presentación y el foco; las solicitudes siguen la máquina de estados.
    // 中文：激活只处理展示和焦点，数据请求仍统一经过状态机。
    public func activateSearch() {
        loadViewIfNeeded()
        guard !isSearchActive else {
            focusSearchBar()
            return
        }

        isSearchActive = true
        if searchConfiguration.placement == .navigationBar {
            presentationContext = PTSearchPresentationContext(viewController: self)
            setCustomTitleView(searchBar, fillSpace: true)
            setCustomRightButtons(buttons: searchConfiguration.showsCancelButton ? [cancelButton] : [])
        }
        searchWillActivate()
        if keyword.isEmpty {
            transition(to: currentHistory.isEmpty ? .focused : .history)
        } else {
            transition(to: .typing(keyword))
        }
        searchDidActivate()
        searchBar.focusSearchField()
    }

    public func deactivateSearch() {
        guard isSearchActive || presentationContext != nil else { return }
        isSearchActive = false
        searchBar.resignSearchField()
        presentationContext?.restore()
        presentationContext = nil
        searchDidDeactivate()
    }

    public func focusSearchBar() {
        loadViewIfNeeded()
        if !isSearchActive {
            activateSearch()
        } else {
            searchBar.focusSearchField()
        }
    }

    public func dismissSearchKeyboard() {
        searchBar.resignSearchField()
    }

    public func cancelSearch() {
        searchWillCancel()
        taskCoordinator.cancelAll()
        currentSnapshot = nil
        currentSuggestions.removeAll(keepingCapacity: true)
        pagination.reset(pageSize: searchConfiguration.paginationPageSize)

        if searchConfiguration.clearOnCancel {
            keyword = ""
            searchBar.setSearchText(nil, notify: false)
            applyResults([], stateKeyword: "", animated: false)
        }

        deactivateSearch()
        transition(to: searchConfiguration.automaticallyShowsHistory && !currentHistory.isEmpty ? .history : .idle)
        searchDidCancel()
    }

    public func refreshSearch() {
        guard !keyword.isEmpty else { return }
        startSearch(keyword: keyword, refreshing: true)
    }

    public func retryCurrentSearch() {
        guard !keyword.isEmpty else { return }
        startSearch(keyword: keyword, refreshing: false)
    }

    // English: Retry only the failed next page without restarting the current search.
    // Español: Reintenta solo la página siguiente fallida sin reiniciar la búsqueda actual.
    // 中文：只重试失败的下一页，不重新启动当前搜索。
    public func retryPagination() {
        loadMoreIfNeeded()
    }

    // English: Replace the canonical result array and render through PTCollectionView's diffable API.
    // Español: Reemplaza el array canónico y renderiza mediante la API diffable de PTCollectionView.
    // 中文：替换规范结果数组，并通过 PTCollectionView 的 Diffable API 渲染。
    public func setResults(_ results: [Item], animated: Bool = true) {
        invalidateRunningRequests()
        applyResults(results, stateKeyword: keyword, animated: animated)
    }

    public func appendResults(_ results: [Item], animated: Bool = true) {
        invalidateRunningRequests()
        applyResults(items + results, stateKeyword: keyword, animated: animated)
    }

    public func prependResults(_ results: [Item], animated: Bool = true) {
        invalidateRunningRequests()
        applyResults(results + items, stateKeyword: keyword, animated: animated)
    }

    public func removeResult(at index: Int, animated: Bool = true) {
        guard items.indices.contains(index) else { return }
        var updated = items
        updated.remove(at: index)
        setResults(updated, animated: animated)
    }

    public func replaceResult(at index: Int, with item: Item, animated: Bool = true) {
        guard items.indices.contains(index) else { return }
        var updated = items
        updated[index] = item
        setResults(updated, animated: animated)
    }

    public func clearResults(animated: Bool = true) {
        invalidateRunningRequests()
        applyResults([], stateKeyword: keyword, animated: animated)
    }

    public func reloadResults() {
        collectionView.reloadAllData(animated: !PTUIAccessibility.reduceMotionEnabled)
    }

    // English: The default hook delegates to a registered provider; subclasses can override it directly.
    // Español: El hook predeterminado delega en el provider registrado; las subclases pueden sobrescribirlo.
    // 中文：默认 hook 调用已注册的 Provider，子类也可以直接重写。
    open func search(keyword: String) async throws -> [Item] {
        guard let resultProviderHandler else { throw PTSearchError.providerUnavailable }
        return try await resultProviderHandler(keyword)
    }

    open func localSearch(keyword: String) async throws -> [Item] {
        guard let localProviderHandler else { return [] }
        return try await localProviderHandler(keyword)
    }

    open func remoteSearch(keyword: String) async throws -> [Item] {
        if let remoteProviderHandler {
            return try await remoteProviderHandler(keyword)
        }
        return try await search(keyword: keyword)
    }

    open func merge(local: [Item], remote: [Item]) -> [Item] {
        local + remote
    }

    open func loadMore(keyword: String, page: Int) async throws -> [Item] {
        throw PTSearchError.paginationUnavailable
    }

    open func makeResultSections(for items: [Item]) -> [PTSection] {
        let rows = items.enumerated().map { index, item in
            let row = PTRows(title: String(describing: item),
                             ID: String(describing: PTSearchDefaultCell.self),
                             diffId: "PTSearch.result.\(index)",
                             dataModel: PTSearchItemBox(value: item))
            row.cellClass = PTSearchDefaultCell.self
            return row
        }
        return [PTSection(identifier: "PTSearch.results", rows: rows)]
    }

    open func makeResultCell(collectionView: UICollectionView,
                             item: Item,
                             indexPath: IndexPath) -> UICollectionViewCell? {
        nil
    }

    open func configureResultCell(_ cell: UICollectionViewCell,
                                  item: Item,
                                  indexPath: IndexPath) {
        (cell as? PTSearchDefaultCell)?.configure(text: String(describing: item))
    }

    open func itemForResult(at indexPath: IndexPath) -> Item? {
        items.indices.contains(indexPath.item) ? items[indexPath.item] : nil
    }

    open func emptyConfiguration(for keyword: String) -> PTSearchEmptyConfiguration {
        PTSearchEmptyConfiguration()
    }

    open func errorConfiguration(for keyword: String, error: Error) -> PTSearchErrorConfiguration {
        PTSearchErrorConfiguration(retryAction: { [weak self] in
            self?.retryCurrentSearch()
        })
    }

    open func searchWillActivate() {}
    open func searchDidActivate() {}
    open func searchTextDidChange(_ keyword: String) {}
    open func searchWillBegin(keyword: String) {}
    open func searchDidFinish(keyword: String, results: [Item]) {}
    open func searchDidFail(keyword: String, error: Error) {}
    open func searchWillCancel() {}
    open func searchDidCancel() {}
    open func searchDidDeactivate() {}
    open func searchWillRefresh(keyword: String) {}
    open func searchDidRefresh(keyword: String) {}
    open func didSelect(item: Item, at indexPath: IndexPath) {}

    public func clearSearchHistory() {
        guard let historyProvider else { return }
        let task = Task { @MainActor [weak self] in
            await historyProvider.clear()
            guard let self else { return }
            self.currentHistory.removeAll(keepingCapacity: true)
            if self.keyword.isEmpty { self.transition(to: .idle) }
        }
        taskCoordinator.replace(task, for: .history)
    }

    public func deleteSearchHistory(keyword: String) {
        guard let historyProvider else { return }
        let task = Task { @MainActor [weak self] in
            await historyProvider.delete(keyword: keyword)
            guard let self else { return }
            self.currentHistory.removeAll { $0.caseInsensitiveCompare(keyword) == .orderedSame }
            if self.keyword.isEmpty { self.renderTextRows(self.currentHistory, kind: "history") }
        }
        taskCoordinator.replace(task, for: .history)
    }

    open func reloadLocalization() {
        searchBar.refreshLocalizedText()
        cancelButton.setTitle("Cancel".localized(), for: .normal)
        switch state {
        case .empty(let value):
            renderEmpty(keyword: value)
        case .failure(let value, let error):
            renderFailure(keyword: value, error: error)
        default:
            break
        }
    }

    open func installCustomSearchBar(_ searchBar: PTSearchBar) {}

    private func makeSearchBar() -> PTSearchBar {
        let bar = PTSearchBar(frame: .zero)
        bar.searchDebounceInterval = searchConfiguration.debounceTimeInterval
        bar.visualStyle = searchConfiguration.visualStyle
        bar.accessibilityLabel = "Search".localized()
        return bar
    }

    private func configureSearchBarHandlers() {
        searchBar.searchDebounceInterval = searchConfiguration.debounceTimeInterval
        searchBar.visualStyle = searchConfiguration.visualStyle
        searchBar.textChangeHandler = { [weak self] text in
            self?.handleTextChanged(text)
        }
        searchBar.returnHandler = { [weak self] text in
            guard let self, self.searchConfiguration.searchOnReturn else { return }
            self.handleReturn(text)
        }
        searchBar.editingBeganHandler = { [weak self] in
            guard let self else { return }
            if self.keyword.isEmpty { self.transition(to: self.currentHistory.isEmpty ? .focused : .history) }
        }
        searchBar.editingEndedHandler = { [weak self] in
            guard let self, self.searchConfiguration.dismissKeyboardOnScroll == false else { return }
            _ = self
        }
    }

    private func configureSearchList(_ listView: PTCollectionView) {
        listView.collectionDidSelect = { [weak self] collectionView, section, indexPath in
            self?.handleSelection(collectionView: collectionView, section: section, indexPath: indexPath)
        }
        listView.collectionWillReachBottomTask = { [weak self] in
            Task { @MainActor [weak self] in
                self?.loadMoreIfNeeded()
            }
        }
        listView.headerRefreshTask = { [weak self] in
            Task { @MainActor [weak self] in
                self?.refreshSearch()
            }
        }
        listView.collectionViewDidScroll = { [weak self] collectionView in
            guard let self else { return }
            if self.searchConfiguration.dismissKeyboardOnScroll,
               collectionView.isDragging || collectionView.isDecelerating {
                self.dismissSearchKeyboard()
            }
        }
        listView.cellInCollection = { [weak self] collectionView, _, indexPath in
            guard let self, let row = self.collectionView.getRow(at: indexPath) else { return nil }
            if let textBox = row.dataModel as? PTSearchTextBox {
                let reuseID = String(describing: PTSearchDefaultCell.self)
                collectionView.register(PTSearchDefaultCell.self, forCellWithReuseIdentifier: reuseID)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseID, for: indexPath)
                (cell as? PTSearchDefaultCell)?.configure(text: textBox.value)
                return cell
            }
            guard let itemBox = row.dataModel as? PTSearchItemBox<Item> else { return nil }
            let cell = self.makeResultCell(collectionView: collectionView,
                                           item: itemBox.value,
                                           indexPath: indexPath)
                ?? collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PTSearchDefaultCell.self),
                                                       for: indexPath)
            self.configureResultCell(cell, item: itemBox.value, indexPath: indexPath)
            return cell
        }
    }

    private func handleTextChanged(_ text: String) {
        let nextKeyword = text.trimmingCharacters(in: .whitespacesAndNewlines)
        keyword = nextKeyword
        keywordDidChange?(nextKeyword)
        searchTextDidChange(nextKeyword)
        taskCoordinator.cancel([.debounce, .suggestion, .search, .pagination, .refresh])
        currentSnapshot = PTSearchSnapshot(keyword: nextKeyword)
        pagination.reset(pageSize: searchConfiguration.paginationPageSize)

        guard !nextKeyword.isEmpty else {
            currentSuggestions.removeAll(keepingCapacity: true)
            if searchConfiguration.clearOnEmptyKeyword { applyResults([], stateKeyword: "", animated: false) }
            if searchConfiguration.automaticallyShowsHistory {
                transition(to: currentHistory.isEmpty ? .focused : .history)
            } else {
                transition(to: .idle)
            }
            if searchConfiguration.automaticallyShowsHistory { loadHistory() }
            return
        }

        guard nextKeyword.count >= searchConfiguration.minimumCharacters else {
            transition(to: .typing(nextKeyword))
            return
        }

        transition(to: .typing(nextKeyword))
        scheduleSuggestions(for: nextKeyword)
        if searchConfiguration.searchWhileTyping {
            scheduleSearch(for: nextKeyword)
        }
    }

    private func handleReturn(_ text: String) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= searchConfiguration.minimumCharacters else { return }
        if keyword != value {
            keyword = value
            keywordDidChange?(value)
        }
        startSearch(keyword: value, refreshing: false)
    }

    private func scheduleSearch(for keyword: String) {
        guard let snapshot = currentSnapshot, snapshot.keyword == keyword else { return }
        taskCoordinator.cancel(.debounce)
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: self.searchConfiguration.debounceInterval)
            } catch {
                return
            }
            guard !Task.isCancelled, self.currentSnapshot == snapshot else { return }
            self.startSearch(keyword: keyword, refreshing: false)
        }
        taskCoordinator.replace(task, for: .debounce)
    }

    private func scheduleSuggestions(for keyword: String) {
        guard searchConfiguration.automaticallyShowsSuggestions,
              let suggestionProviderHandler,
              let snapshot = currentSnapshot else { return }
        taskCoordinator.cancel(.suggestion)
        let task = Task { @MainActor [weak self] in
            do {
                let suggestions = try await suggestionProviderHandler(keyword)
                guard let self, !Task.isCancelled, self.currentSnapshot == snapshot else { return }
                self.currentSuggestions = suggestions
                if !suggestions.isEmpty,
                   self.searchConfiguration.searchWhileTyping == false {
                    self.transition(to: .suggestions(keyword))
                }
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
        taskCoordinator.replace(task, for: .suggestion)
    }

    private func startSearch(keyword: String, refreshing: Bool) {
        let value = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= searchConfiguration.minimumCharacters else { return }

        taskCoordinator.cancel([.debounce, .search, .suggestion, .pagination, .refresh])
        let snapshot = PTSearchSnapshot(keyword: value)
        currentSnapshot = snapshot
        pagination.reset(pageSize: searchConfiguration.paginationPageSize)
        searchWillBegin(keyword: value)
        if refreshing { searchWillRefresh(keyword: value) }
        transition(to: refreshing ? .refreshing(value) : .searching(value))

        if let historyProvider {
            let historyTask = Task { @MainActor in
                await historyProvider.save(keyword: value)
            }
            taskCoordinator.replace(historyTask, for: .history)
        }

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let results = try await self.performSearch(keyword: value, snapshot: snapshot)
                guard !Task.isCancelled, self.currentSnapshot == snapshot else { return }
                self.applyResults(results, stateKeyword: value, animated: true)
                self.searchDidFinish(keyword: value, results: results)
                if refreshing { self.searchDidRefresh(keyword: value) }
                self.announceResults(results.count)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, self.currentSnapshot == snapshot else { return }
                self.renderFailure(keyword: value, error: error)
                self.searchDidFail(keyword: value, error: error)
            }
        }
        taskCoordinator.replace(task, for: refreshing ? .refresh : .search)
    }

    private func performSearch(keyword: String, snapshot: PTSearchSnapshot) async throws -> [Item] {
        guard currentSnapshot == snapshot else { throw CancellationError() }
        switch searchMode {
        case .local:
            return try await localSearch(keyword: keyword)
        case .remote:
            return try await remoteSearch(keyword: keyword)
        case .custom:
            return try await search(keyword: keyword)
        case .hybrid:
            let local = try await localSearch(keyword: keyword)
            guard !Task.isCancelled, currentSnapshot == snapshot else { throw CancellationError() }
            if !local.isEmpty {
                applyResults(local, stateKeyword: keyword, animated: false)
            }
            let remote = try await remoteSearch(keyword: keyword)
            guard !Task.isCancelled, currentSnapshot == snapshot else { throw CancellationError() }
            return merge(local: local, remote: remote)
        }
    }

    private func loadHistory() {
        guard let historyProvider else { return }
        taskCoordinator.cancel(.history)
        let task = Task { @MainActor [weak self] in
            let history = await historyProvider.loadHistory()
            guard let self, !Task.isCancelled else { return }
            self.currentHistory = Array(history.prefix(self.searchConfiguration.historyMaximumCount))
            if self.keyword.isEmpty, self.isSearchActive {
                self.transition(to: self.currentHistory.isEmpty ? .focused : .history)
            }
        }
        taskCoordinator.replace(task, for: .history)
    }

    private func loadMoreIfNeeded() {
        guard searchConfiguration.enablesPagination,
              !keyword.isEmpty,
              let page = pagination.beginLoading() else { return }
        let value = keyword
        guard let snapshot = currentSnapshot else {
            pagination.reset(pageSize: searchConfiguration.paginationPageSize)
            return
        }
        transition(to: .loadingMore(value))
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let newItems = try await self.loadMore(keyword: value, page: page)
                guard !Task.isCancelled, self.currentSnapshot == snapshot else { return }
                self.pagination.finish(hasMore: newItems.count >= self.pagination.pageSize)
                self.applyResults(self.items + newItems, stateKeyword: value, animated: true)
            } catch is CancellationError {
                return
            } catch {
                guard self.currentSnapshot == snapshot else { return }
                self.pagination.fail(error)
                self.transition(to: .results(value, count: self.items.count))
            }
        }
        taskCoordinator.replace(task, for: .pagination)
    }

    private func applyResults(_ results: [Item], stateKeyword: String, animated: Bool) {
        items = results
        if results.isEmpty {
            transition(to: .empty(stateKeyword))
            return
        }
        let sections = makeResultSections(for: results)
        collectionView.showCollectionDetail(collectionData: sections, animated: animated)
        PTUnavailableManager.render(.content, in: collectionView)
        transitionWithoutRendering(to: .results(stateKeyword, count: results.count))
    }

    private func invalidateRunningRequests() {
        taskCoordinator.cancel([.debounce, .search, .suggestion, .pagination, .refresh])
        currentSnapshot = nil
        pagination.reset(pageSize: searchConfiguration.paginationPageSize)
    }

    private func transition(to nextState: PTSearchState) {
        state = nextState
        searchStateDidChange?(nextState)
        render(nextState)
    }

    private func transitionWithoutRendering(to nextState: PTSearchState) {
        state = nextState
        searchStateDidChange?(nextState)
    }

    private func render(_ state: PTSearchState) {
        guard isViewLoaded else { return }
        switch state {
        case .idle, .focused:
            PTUnavailableManager.render(.content, in: collectionView)
        case .history:
            renderTextRows(currentHistory, kind: "history")
        case .suggestions:
            renderTextRows(currentSuggestions, kind: "suggestions")
        case .typing:
            if items.isEmpty { PTUnavailableManager.render(.content, in: collectionView) }
        case .searching, .refreshing:
            if searchConfiguration.keepsPreviousResultsWhileLoading, !items.isEmpty {
                PTUnavailableManager.render(.content, in: collectionView)
            } else {
                collectionView.clearAllData()
                PTUnavailableManager.render(.loading, in: collectionView)
            }
        case .results:
            PTUnavailableManager.render(.content, in: collectionView)
        case .loadingMore:
            PTUnavailableManager.render(.content, in: collectionView)
        case .empty(let value):
            renderEmpty(keyword: value)
        case .failure(let value, let error):
            renderFailure(keyword: value, error: error)
        }
    }

    private func renderTextRows(_ values: [String], kind: String) {
        guard !values.isEmpty else {
            collectionView.clearAllData()
            PTUnavailableManager.render(.content, in: collectionView)
            return
        }
        let rows = values.enumerated().map { index, value in
            let row = PTRows(title: value,
                             ID: String(describing: PTSearchDefaultCell.self),
                             diffId: "PTSearch.\(kind).\(index).\(value)",
                             dataModel: PTSearchTextBox(value: value))
            row.cellClass = PTSearchDefaultCell.self
            return row
        }
        collectionView.showCollectionDetail(collectionData: [PTSection(identifier: "PTSearch.\(kind)", rows: rows)], animated: false)
        PTUnavailableManager.render(.content, in: collectionView)
    }

    private func renderEmpty(keyword: String) {
        collectionView.clearAllData()
        let model = emptyConfiguration(for: keyword)
        let config = PTEmptyDataViewConfig()
        config.image = model.image
        config.mainTitleAtt = ASAttributedString(string: model.title)
        config.secondaryEmptyAtt = ASAttributedString(string: model.message)
        config.buttonTitle = model.actionTitle
        PTUnavailableManager.render(.empty, in: collectionView, config: config, action: model.action)
    }

    private func renderFailure(keyword: String, error: Error) {
        let model = errorConfiguration(for: keyword, error: error)
        let config = PTEmptyDataViewConfig()
        config.image = model.image
        config.mainTitleAtt = ASAttributedString(string: model.title)
        config.secondaryEmptyAtt = ASAttributedString(string: model.message)
        config.buttonTitle = model.retryTitle
        PTUnavailableManager.render(.error, in: collectionView, config: config, action: model.retryAction)
        transitionWithoutRendering(to: .failure(keyword, error))
    }

    private func handleSelection(collectionView: UICollectionView,
                                 section: PTSection,
                                 indexPath: IndexPath) {
        guard let row = self.collectionView.getRow(at: indexPath) else { return }
        if let textBox = row.dataModel as? PTSearchTextBox {
            searchBar.setSearchText(textBox.value, notify: false)
            keyword = textBox.value
            keywordDidChange?(keyword)
            startSearch(keyword: keyword, refreshing: false)
            return
        }
        guard let item = (row.dataModel as? PTSearchItemBox<Item>)?.value ?? itemForResult(at: indexPath) else { return }
        if searchConfiguration.dismissKeyboardOnSelection { dismissSearchKeyboard() }
        resultDidSelect?(item)
        didSelect(item: item, at: indexPath)
        _ = section
        _ = collectionView
    }

    private func announceResults(_ count: Int) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement,
                              argument: String(format: "Found %d results".localized(), count))
    }

    @objc private func cancelButtonTapped() {
        cancelSearch()
    }
}
