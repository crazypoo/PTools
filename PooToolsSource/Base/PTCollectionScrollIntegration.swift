//
//  PTCollectionScrollIntegration.swift
//  PooTools
//
// English: Public scrolling APIs and the logical-to-physical presentation bridge.
// Español: API públicas de desplazamiento y puente de presentación lógico-físico.
// 中文：公开滚动 API 与逻辑身份到物理身份的展示桥接。
//

import UIKit

@MainActor
extension PTCollectionView {
    // English: Keep indicator visibility on the canonical scroll host so layout updates cannot re-enable it accidentally.
    // Español: Mantiene la visibilidad de los indicadores en el host canónico para que los cambios de layout no los reactiven por accidente.
    // 中文：将滚动条可见性收口到统一滚动宿主，避免布局更新时意外重新显示。
    @nonobjc public func setScrollIndicatorsHidden(_ hidden: Bool) {
        collectionView.showsHorizontalScrollIndicator = !hidden && viewConfig.showsHorizontalScrollIndicator
        collectionView.showsVerticalScrollIndicator = !hidden && viewConfig.showsVerticalScrollIndicator
    }

    // English: Expose a small compatibility bridge for legacy banner controls.
    // Español: Expone un pequeño puente de compatibilidad para los controles heredados del banner.
    // 中文：为旧版 Banner 控制入口提供轻量兼容桥接。
    func pauseAutomaticScroll() {
        autoScrollCoordinator.pause()
    }

    func resumeAutomaticScroll() {
        autoScrollCoordinator.resume()
    }

    func stopAutomaticScroll() {
        autoScrollCoordinator.stop()
    }

    func emitDragLifecycle(phase: PTCollectionDragPhase,
                           outcome: PTCollectionDragOutcome,
                           proposed: IndexPath?,
                           final: IndexPath?) {
        guard let sessionID = dragCoordinator.sessionID else { return }
        let context = PTCollectionDragContext(sessionID: sessionID,
                                              phase: phase,
                                              outcome: outcome,
                                              sourceRowIDs: dragCoordinator.sourceRowIDs,
                                              sourceLogicalIndexPaths: dragCoordinator.sourceIndexPaths.map(logicalIndexPath(for:)),
                                              proposedDestination: proposed,
                                              finalDestination: final,
                                              isLocalSession: dragCoordinator.isLocalSession)
        onDragLifecycle?(context)
    }

    // English: Apply a scroll contract atomically before changing UIKit layout state.
    // Español: Aplica el contrato de desplazamiento de forma atómica antes de cambiar el layout de UIKit.
    // 中文：在修改 UIKit 布局前原子化应用滚动契约。
    @discardableResult
    func applyScrollConfiguration(_ configuration: PTCollectionScrollConfiguration,
                                  rebuildLayout: Bool) -> Result<Void, PTCollectionScrollError> {
        guard let error = PTCollectionScrollValidator.validate(configuration, viewConfig: viewConfig) else {
            requestedScrollConfiguration = configuration
            effectiveScrollStyle = effectiveStyle(for: configuration,
                                                  itemCount: modelStore.sectionIdentifiers().count == 1
                                                    ? modelStore.rowIdentifiers(in: modelStore.sectionIdentifiers()[0]).count
                                                    : 0)
            lastScrollError = nil
            totalPages = pageCount(for: configuration,
                                   sections: modelStore.resolvedSections(modelStore.sectionIdentifiers()))
            autoScrollCoordinator.configure(configuration.autoScroll) { [weak self] in
                self?.nextPage(animated: true)
            }
            if rebuildLayout, self.collectionView.superview != nil {
                runtimeLayoutRevision &+= 1
                clearLayoutCaches()
                self.collectionView.setCollectionViewLayout(self.comboLayout(), animated: false)
                collectionView.layoutIfNeeded()
                updatePageGeometry(reason: .geometryChanged)
            }
            return .success(())
        }

        lastScrollError = error
        effectiveScrollStyle = .normal
        autoScrollCoordinator.stop()
        return .failure(error)
    }

    @discardableResult
    public func updateScrollConfiguration(_ configuration: PTCollectionScrollConfiguration,
                                          animated: Bool = false) -> Result<Void, PTCollectionScrollError> {
        guard !isLayoutTransitionActive else {
            lastScrollError = .transitionInProgress
            return .failure(.transitionInProgress)
        }
        let result = applyScrollConfiguration(configuration, rebuildLayout: false)
        guard case .success = result else { return result }
        viewConfig.scrollConfiguration = configuration
        runtimeLayoutRevision &+= 1
        clearLayoutCaches()
        let layout = comboLayout()
        if animated {
            collectionView.setCollectionViewLayout(layout, animated: true) { [weak self] _ in
                self?.updatePageGeometry(reason: .geometryChanged)
            }
        } else {
            collectionView.setCollectionViewLayout(layout, animated: false)
            updatePageGeometry(reason: .geometryChanged)
        }
        return .success(())
    }

    @discardableResult
    public func setScrollStyle(_ style: PTCollectionScrollStyle,
                               animated: Bool = false) -> Result<Void, PTCollectionScrollError> {
        var configuration = viewConfig.scrollConfiguration
        configuration.style = style
        return updateScrollConfiguration(configuration, animated: animated)
    }

    @discardableResult
    func configurePresentation(for sections: [PTSection]) -> PTCollectionIDSnapshot {
        let configuration = viewConfig.scrollConfiguration
        requestedScrollConfiguration = configuration
        let itemCount = sections.count == 1 ? sections.first?.rows?.count ?? 0 : 0
        if let validationError = PTCollectionScrollValidator.validate(configuration, viewConfig: viewConfig) {
            lastScrollError = validationError
            effectiveScrollStyle = .normal
            presentationAdapter.reset()
            totalPages = pageCount(for: configuration, sections: sections)
            return normalSnapshot(for: sections)
        }

        if configuration.style.isInfinite, cellInCollectionV2 == nil, cellInCollection != nil {
            let error = PTCollectionScrollError.legacyProviderNotLoopSafe
            lastScrollError = error
            effectiveScrollStyle = .normal
            presentationAdapter.reset()
            totalPages = pageCount(for: configuration, sections: sections)
            return normalSnapshot(for: sections)
        }

        switch presentationAdapter.configure(sections: sections, configuration: configuration) {
        case .success(let snapshot):
            effectiveScrollStyle = effectiveStyle(for: configuration, itemCount: itemCount)
            lastScrollError = presentationAdapter.lastError
            totalPages = pageCount(for: configuration, sections: sections)
            didSetInitialPage = false
            autoScrollCoordinator.configure(configuration.autoScroll) { [weak self] in
                self?.nextPage(animated: true)
            }
            return snapshot
        case .failure(let error):
            lastScrollError = error
            effectiveScrollStyle = .normal
            presentationAdapter.reset()
            totalPages = pageCount(for: configuration, sections: sections)
            return normalSnapshot(for: sections)
        }
    }

    // English: A zero/one-item infinite request keeps its intent but uses a finite presentation until looping is meaningful.
    // Español: Una solicitud infinita con cero o un elemento conserva su intención, pero usa una presentación finita hasta que el ciclo sea posible.
    // 中文：无限配置在 0/1 条数据时保留配置意图，但在循环具备意义前使用普通分页展示。
    private func effectiveStyle(for configuration: PTCollectionScrollConfiguration,
                               itemCount: Int) -> PTCollectionScrollStyle {
        guard configuration.style.isInfinite, itemCount < 2 else { return configuration.style }
        return configuration.style.isHorizontal ? .horizontalPaging : .verticalPaging
    }

    private func pageCount(for configuration: PTCollectionScrollConfiguration,
                           sections: [PTSection]) -> Int {
        guard configuration.style != .normal else { return 0 }
        if configuration.paging.snapMode == .item && !configuration.style.isInfinite {
            return sections.reduce(0) { $0 + ($1.rows?.count ?? 0) }
        }
        return sections.count == 1 ? sections.first?.rows?.count ?? 0 : 0
    }

    func normalSnapshot(for sections: [PTSection]) -> PTCollectionIDSnapshot {
        var snapshot = PTCollectionIDSnapshot()
        snapshot.appendSections(sections)
        for section in sections {
            if let rows = section.rows, !rows.isEmpty {
                snapshot.appendItems(rows, toSection: section)
            }
        }
        return snapshot
    }

    func presentationSnapshotFromModelStore() -> PTCollectionIDSnapshot {
        let sections = modelStore.resolvedSections(modelStore.sectionIdentifiers())
        return presentationAdapter.isActive
            ? presentationAdapter.snapshot(for: sections)
            : normalSnapshot(for: sections)
    }

    func logicalRowIdentifier(for identifier: PTRowIdentifier) -> PTRowIdentifier {
        presentationAdapter.logicalID(for: identifier)
    }

    func logicalIndexPath(for physicalIndexPath: IndexPath) -> IndexPath {
        guard presentationAdapter.isActive,
              let logicalIndex = presentationAdapter.logicalIndex(for: diffableDataSource.itemIdentifier(for: physicalIndexPath) ?? PTRowIdentifier("")) else {
            return physicalIndexPath
        }
        return IndexPath(item: logicalIndex, section: physicalIndexPath.section)
    }

    func applyInitialPageIfNeeded() {
        guard !didSetInitialPage,
              effectiveScrollStyle.isPaging || effectiveScrollStyle.isInfinite,
              totalPages > 0 else { return }
        let targetIndex = presentationAdapter.isActive
            ? presentationAdapter.initialPhysicalIndex
            : max(0, min(viewConfig.scrollConfiguration.paging.initialPage, max(0, totalPages - 1)))
        if isItemSnap {
            guard let point = itemContentOffset(forPage: targetIndex) else { return }
            collectionView.setContentOffset(point, animated: false)
            didSetInitialPage = true
            updatePageGeometry(reason: .initial)
            return
        }
        guard let extent = pageExtent, extent > 0 else { return }
        let offset = extent * CGFloat(targetIndex)
        if effectiveScrollStyle.isHorizontal {
            collectionView.setContentOffset(CGPoint(x: offset - collectionView.adjustedContentInset.left,
                                                     y: collectionView.contentOffset.y), animated: false)
        } else {
            collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x,
                                                     y: offset - collectionView.adjustedContentInset.top), animated: false)
        }
        didSetInitialPage = true
        updatePageGeometry(reason: .initial)
    }

    @discardableResult
    public func scrollToPage(index: Int, animated: Bool = true) -> Bool {
        guard totalPages > 0 else { return false }
        if !effectiveScrollStyle.isInfinite, !(0..<totalPages).contains(index) {
            lastScrollError = .invalidPageGeometry
            return false
        }
        guard let target = physicalPageIndex(for: index) else {
            lastScrollError = .invalidPageGeometry
            return false
        }
        if isItemSnap {
            guard let point = itemContentOffset(forPage: target) else {
                lastScrollError = .invalidPageGeometry
                return false
            }
            if !animated {
                collectionView.setContentOffset(point, animated: false)
                updatePageGeometry(reason: .programmatic)
            } else {
                collectionView.setContentOffset(point, animated: true)
            }
            return true
        }
        guard let extent = pageExtent, extent > 0 else {
            lastScrollError = .invalidPageGeometry
            return false
        }
        let offset = CGFloat(target) * extent
        let point = effectiveScrollStyle.isHorizontal
            ? CGPoint(x: offset - collectionView.adjustedContentInset.left, y: collectionView.contentOffset.y)
            : CGPoint(x: collectionView.contentOffset.x, y: offset - collectionView.adjustedContentInset.top)
        if !animated {
            collectionView.setContentOffset(point, animated: false)
            updatePageGeometry(reason: .programmatic)
        } else {
            collectionView.setContentOffset(point, animated: true)
        }
        return true
    }

    @discardableResult
    public func scrollToPage(at page: Int, animated: Bool = true) -> Bool {
        scrollToPage(index: page, animated: animated)
    }

    @discardableResult
    public func nextPage(animated: Bool = true) -> Bool {
        guard totalPages > 0 else { return false }
        if effectiveScrollStyle.isInfinite {
            return scrollToPage(index: (currentPage + 1) % totalPages, animated: animated)
        } else {
            return scrollToPage(index: min(currentPage + 1, totalPages - 1), animated: animated)
        }
    }

    @discardableResult
    public func previousPage(animated: Bool = true) -> Bool {
        guard totalPages > 0 else { return false }
        if effectiveScrollStyle.isInfinite {
            return scrollToPage(index: (currentPage - 1 + totalPages) % totalPages, animated: animated)
        } else {
            return scrollToPage(index: max(currentPage - 1, 0), animated: animated)
        }
    }

    // English: Apply a mutation to a copied configuration and report one atomic result.
    // Español: Aplica una mutación a una copia de la configuración y devuelve un único resultado atómico.
    // 中文：先修改配置副本，再以一次原子事务返回结果。
    @discardableResult
    public func updateScrollConfiguration(
        animated: Bool = false,
        _ mutate: @MainActor (inout PTCollectionScrollConfiguration) -> Void,
        completion: (@MainActor (Result<Void, PTCollectionScrollError>) -> Void)? = nil
    ) -> Result<Void, PTCollectionScrollError> {
        var configuration = viewConfig.scrollConfiguration
        mutate(&configuration)
        let result = updateScrollConfiguration(configuration, animated: animated)
        completion?(result)
        return result
    }

    @discardableResult
    public func setScrollStyle(
        _ style: PTCollectionScrollStyle,
        animated: Bool = false,
        completion: (@MainActor (Result<Void, PTCollectionScrollError>) -> Void)? = nil
    ) -> Result<Void, PTCollectionScrollError> {
        var configuration = viewConfig.scrollConfiguration
        configuration.style = style
        let result = updateScrollConfiguration(configuration, animated: animated)
        completion?(result)
        return result
    }

    func updatePageGeometry(reason: PTCollectionPageChangeReason) {
        guard effectiveScrollStyle.isPaging || effectiveScrollStyle.isInfinite,
              totalPages > 0 else { return }
        let rawOffset = effectiveScrollStyle.isHorizontal
            ? collectionView.contentOffset.x + collectionView.adjustedContentInset.left
            : collectionView.contentOffset.y + collectionView.adjustedContentInset.top
        guard rawOffset.isFinite else { return }
        let physicalIndex: Int
        let logicalPage: Int?
        let physicalIndexPath: IndexPath?
        if isItemSnap {
            guard let nearest = nearestItemPage(for: rawOffset) else { return }
            physicalIndex = nearest.physicalIndex
            logicalPage = nearest.logicalPage
            physicalIndexPath = nearest.indexPath
        } else {
            guard let extent = pageExtent,
                  extent.isFinite,
                  extent > 0 else { return }
            physicalIndex = max(0, Int(round(rawOffset / extent)))
            logicalPage = presentationAdapter.isActive
                ? presentationAdapter.logicalPage(for: min(physicalIndex, max(0, presentationAdapter.physicalRows.count - 1)))
                : min(physicalIndex, totalPages - 1)
            physicalIndexPath = nil
        }
        guard let logicalPage else { return }
        let changed = logicalPage != currentPage
        currentPage = logicalPage
        if let entry = pageEntry(for: logicalPage) {
            let sectionID = entry.sectionID
            let rowID = entry.rowID
            let displayedRowID: PTRowIdentifier
            if presentationAdapter.isActive {
                guard presentationAdapter.physicalRows.indices.contains(physicalIndex) else { return }
                displayedRowID = presentationAdapter.physicalRows[physicalIndex]
            } else {
                displayedRowID = rowID
            }
            let resolvedPhysicalIndexPath = physicalIndexPath
                ?? diffableDataSource.indexPath(for: displayedRowID)
            guard let resolvedPhysicalIndexPath else { return }
            let context = PTCollectionPageContext(page: logicalPage,
                                                   pageCount: totalPages,
                                                   sectionID: sectionID,
                                                   rowID: rowID,
                                                   logicalIndexPath: entry.indexPath,
                                                   reason: reason)
            currentPageContext = context
            if changed || reason == .initial || reason == .programmatic {
                onPageChanged?(context)
            }
        }

        if presentationAdapter.shouldRebind(physicalIndex: physicalIndex),
           presentationAdapter.rebind(around: logicalPage, configuration: requestedScrollConfiguration) {
            let sections = modelStore.resolvedSections(modelStore.sectionIdentifiers())
            let snapshot = presentationAdapter.snapshot(for: sections)
            didSetInitialPage = false
            applySnapshot(snapshot, animatingDifferences: false) { [weak self] in
                self?.applyInitialPageIfNeeded()
            }
        }
    }

    var isItemSnap: Bool {
        viewConfig.scrollConfiguration.paging.snapMode == .item
            && !effectiveScrollStyle.isInfinite
    }

    private func pageEntry(for page: Int) -> (sectionID: PTSectionIdentifier,
                                               rowID: PTRowIdentifier,
                                               indexPath: IndexPath)? {
        guard page >= 0 else { return nil }
        var offset = 0
        for sectionID in modelStore.sectionIdentifiers() {
            let rows = modelStore.rowIdentifiers(in: sectionID)
            if page < offset + rows.count {
                let item = page - offset
                return (sectionID, rows[item], IndexPath(item: item, section: modelStore.sectionIdentifiers().firstIndex(of: sectionID) ?? 0))
            }
            offset += rows.count
        }
        return nil
    }

    func itemContentOffset(forPage page: Int) -> CGPoint? {
        guard let entry = pageEntry(for: page),
              let attributes = collectionView.layoutAttributesForItem(at: entry.indexPath) else { return nil }
        let alignment = viewConfig.scrollConfiguration.paging.itemAlignment
        if effectiveScrollStyle.isHorizontal {
            let coordinate: CGFloat = alignment == .center
                ? attributes.center.x - collectionView.bounds.width / 2
                : attributes.frame.minX
            return CGPoint(x: coordinate - collectionView.adjustedContentInset.left,
                           y: collectionView.contentOffset.y)
        }
        let coordinate: CGFloat = alignment == .center
            ? attributes.center.y - collectionView.bounds.height / 2
            : attributes.frame.minY
        return CGPoint(x: collectionView.contentOffset.x,
                       y: coordinate - collectionView.adjustedContentInset.top)
    }

    func nearestItemPage(for rawOffset: CGFloat) -> (logicalPage: Int,
                                                     physicalIndex: Int,
                                                     indexPath: IndexPath)? {
        let target: CGFloat
        if viewConfig.scrollConfiguration.paging.itemAlignment == .center {
            target = rawOffset + (effectiveScrollStyle.isHorizontal ? collectionView.bounds.width : collectionView.bounds.height) / 2
        } else {
            target = rawOffset
        }
        var page = 0
        var nearest: (distance: CGFloat, logicalPage: Int, indexPath: IndexPath)?
        for sectionIndex in modelStore.sectionIdentifiers().indices {
            let sectionID = modelStore.sectionIdentifiers()[sectionIndex]
            for item in modelStore.rowIdentifiers(in: sectionID).indices {
                let indexPath = IndexPath(item: item, section: sectionIndex)
                guard let attributes = collectionView.layoutAttributesForItem(at: indexPath) else {
                    page += 1
                    continue
                }
                let coordinate = viewConfig.scrollConfiguration.paging.itemAlignment == .center
                    ? (effectiveScrollStyle.isHorizontal ? attributes.center.x : attributes.center.y)
                    : (effectiveScrollStyle.isHorizontal ? attributes.frame.minX : attributes.frame.minY)
                let distance = abs(coordinate - target)
                if let current = nearest {
                    if distance < current.distance {
                        nearest = (distance, page, indexPath)
                    }
                } else {
                    nearest = (distance, page, indexPath)
                }
                page += 1
            }
        }
        guard let nearest else { return nil }
        return (nearest.logicalPage, nearest.indexPath.item, nearest.indexPath)
    }

    var pageExtent: CGFloat? {
        let value = effectiveScrollStyle.isHorizontal ? collectionView.bounds.width : collectionView.bounds.height
        return value.isFinite && value > 0 ? value : nil
    }

    private func physicalPageIndex(for logicalPage: Int) -> Int? {
        guard totalPages > 0 else { return nil }
        let normalized = effectiveScrollStyle.isInfinite
            ? ((logicalPage % totalPages) + totalPages) % totalPages
            : max(0, min(logicalPage, totalPages - 1))
        if presentationAdapter.isActive {
            return presentationAdapter.physicalIndex(for: normalized)
        }
        return normalized
    }
}
