//
//  PTCollectionLayoutTransition.swift
//  PooTools
//
// English: Runtime layout switching for PTCollectionView without rebuilding its data source.
// Español: Cambio de layout en tiempo de ejecución sin reconstruir la fuente de datos de PTCollectionView.
// 中文：PTCollectionView 运行时切换布局，不重建数据源。
//

import UIKit

@MainActor
private struct PTCollectionLayoutViewportAnchor {
    let policy: PTCollectionLayoutScrollPolicy
    let rowID: PTRowIdentifier?
    let originalIndexPath: IndexPath?
    let relativeOffset: CGFloat
    let contentOffset: CGPoint
    let selectedRowIDs: [PTRowIdentifier]
    let isHorizontal: Bool
}

@MainActor
extension PTCollectionView {
    // English: Switch the layout without rebuilding the collection view or Diffable identities.
    // Español: Cambia el layout sin reconstruir la colección ni las identidades Diffable.
    // 中文：在不重建 CollectionView 和 Diffable 身份的前提下切换布局。
    public func switchLayout(to type: PTCollectionViewType,
                             animated: Bool = true,
                             scrollPolicy: PTCollectionLayoutScrollPolicy = .firstVisibleItem,
                             completion: (@MainActor (Bool) -> Void)? = nil) {
        updateCoordinator.enqueue(name: "switchLayout", kind: .layout) { [weak self] finish in
            guard let self else {
                completion?(false)
                finish()
                return
            }
            // English: Read the latest configuration only when this queued operation starts.
            // Español: Lee la configuración más reciente solo cuando comienza esta operación en cola.
            // 中文：仅在排队操作真正开始时读取最新配置。
            let candidate = self.viewConfig.pt_runtimeCopy()
            let sourceType = candidate.viewType
            candidate.viewType = type
            self.performRuntimeLayoutTransition(candidate: candidate,
                                                sourceType: sourceType,
                                                animated: animated,
                                                scrollPolicy: scrollPolicy,
                                                completion: completion,
                                                finish: finish)
        }
    }

    // English: Mutate a copied configuration inside one serialized layout transaction.
    // Español: Modifica una copia de configuración dentro de una única transacción serializada.
    // 中文：在一个串行布局事务中修改配置，避免共享配置对象被异步污染。
    public func updateLayoutConfiguration(animated: Bool = true,
                                          scrollPolicy: PTCollectionLayoutScrollPolicy = .firstVisibleItem,
                                          completion: (@MainActor (Bool) -> Void)? = nil,
                                          _ configure: @escaping @MainActor (PTCollectionViewConfig) -> Void) {
        updateCoordinator.enqueue(name: "updateLayoutConfiguration", kind: .layout) { [weak self] finish in
            guard let self else {
                completion?(false)
                finish()
                return
            }
            let candidate = self.viewConfig.pt_runtimeCopy()
            configure(candidate)
            self.performRuntimeLayoutTransition(candidate: candidate,
                                                sourceType: self.viewConfig.viewType,
                                                animated: animated,
                                                scrollPolicy: scrollPolicy,
                                                completion: completion,
                                                finish: finish)
        }
    }

    func enqueueRuntimeLayoutTransition(candidate: PTCollectionViewConfig,
                                         sourceType: PTCollectionViewType?,
                                         animated: Bool,
                                         scrollPolicy: PTCollectionLayoutScrollPolicy,
                                         completion: (@MainActor (Bool) -> Void)?) {
        updateCoordinator.enqueue(name: "switchLayout", kind: .layout) { [weak self] finish in
            guard let self else {
                completion?(false)
                finish()
                return
            }
            self.performRuntimeLayoutTransition(candidate: candidate,
                                                sourceType: sourceType ?? self.viewConfig.viewType,
                                                animated: animated,
                                                scrollPolicy: scrollPolicy,
                                                completion: completion,
                                                finish: finish)
        }
    }

    private func performRuntimeLayoutTransition(candidate: PTCollectionViewConfig,
                                                sourceType: PTCollectionViewType,
                                                animated: Bool,
                                                scrollPolicy: PTCollectionLayoutScrollPolicy,
                                                completion: (@MainActor (Bool) -> Void)?,
                                                finish: @escaping @MainActor () -> Void) {
        guard candidate.viewType != .Custom || customerLayout != nil else {
            // English: A custom layout without a provider is rejected instead of replacing a working layout with a blank one.
            // Español: Un layout personalizado sin provider se rechaza para no reemplazar un layout válido por uno vacío.
            // 中文：自定义布局没有 Provider 时拒绝切换，避免把可用布局替换成空布局。
            PTNSLogConsole("[PTCollection] Custom layout switch ignored because customerLayout is nil")
            completion?(false)
            finish()
            return
        }

        isLayoutTransitionActive = true
        let anchor = captureViewportAnchor(policy: scrollPolicy, sourceType: sourceType)
        let shouldAnimate = animated && !UIAccessibility.isReduceMotionEnabled

        runtimeLayoutRevision &+= 1
        clearLayoutCaches()

        isApplyingRuntimeLayoutConfiguration = true
        viewConfig = candidate
        isApplyingRuntimeLayoutConfiguration = false
        applyCollectionBehavior(from: candidate)

        let newLayout = comboLayout()
        var delivered = false
        let complete: @MainActor (Bool) -> Void = { [weak self] finished in
            guard let self, !delivered else { return }
            delivered = true
            self.collectionView.layoutIfNeeded()
            self.restoreViewportAnchor(anchor)
            self.setiOS17EmptyDataView()
            self.updateSkeletonLayout()
            self.isLayoutTransitionActive = false
            completion?(finished)
            finish()
        }

        if shouldAnimate, collectionView.window != nil, !collectionView.bounds.isEmpty {
            collectionView.setCollectionViewLayout(newLayout, animated: true, completion: complete)
        } else {
            collectionView.setCollectionViewLayout(newLayout, animated: false)
            complete(true)
        }
    }

    private func captureViewportAnchor(policy: PTCollectionLayoutScrollPolicy,
                                       sourceType: PTCollectionViewType) -> PTCollectionLayoutViewportAnchor {
        let horizontal = sourceType == .Horizontal || sourceType == .HorizontalLayoutSystem
        let selected = (collectionView.indexPathsForSelectedItems ?? [])
            .compactMap { diffableDataSource.itemIdentifier(for: $0) }
        guard policy == .firstVisibleItem else {
            return PTCollectionLayoutViewportAnchor(policy: policy,
                                                    rowID: nil,
                                                    originalIndexPath: nil,
                                                    relativeOffset: 0,
                                                    contentOffset: collectionView.contentOffset,
                                                    selectedRowIDs: selected,
                                                    isHorizontal: horizontal)
        }

        let visibleBounds = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let first = collectionView.indexPathsForVisibleItems
            .compactMap { indexPath -> (IndexPath, UICollectionViewLayoutAttributes)? in
                guard let attributes = collectionView.layoutAttributesForItem(at: indexPath),
                      attributes.frame.intersects(visibleBounds) else { return nil }
                return (indexPath, attributes)
            }
            .sorted {
                horizontal ? $0.1.frame.minX < $1.1.frame.minX : $0.1.frame.minY < $1.1.frame.minY
            }
            .first
        guard let first,
              let row = diffableDataSource.itemIdentifier(for: first.0) else {
            return PTCollectionLayoutViewportAnchor(policy: policy,
                                                    rowID: nil,
                                                    originalIndexPath: nil,
                                                    relativeOffset: 0,
                                                    contentOffset: collectionView.contentOffset,
                                                    selectedRowIDs: selected,
                                                    isHorizontal: horizontal)
        }

        let relativeOffset = horizontal
            ? first.1.frame.minX - collectionView.contentOffset.x
            : first.1.frame.minY - collectionView.contentOffset.y
        return PTCollectionLayoutViewportAnchor(policy: policy,
                                                rowID: row,
                                                originalIndexPath: first.0,
                                                relativeOffset: relativeOffset,
                                                contentOffset: collectionView.contentOffset,
                                                selectedRowIDs: selected,
                                                isHorizontal: horizontal)
    }

    private func restoreViewportAnchor(_ anchor: PTCollectionLayoutViewportAnchor) {
        collectionView.layoutIfNeeded()
        let targetOffset: CGPoint
        switch anchor.policy {
        case .firstVisibleItem:
            if let rowID = anchor.rowID,
               let indexPath = diffableDataSource.indexPath(for: rowID),
               let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
                if anchor.isHorizontal {
                    targetOffset = CGPoint(x: attributes.frame.minX - anchor.relativeOffset,
                                           y: collectionView.contentOffset.y)
                } else {
                    targetOffset = CGPoint(x: collectionView.contentOffset.x,
                                           y: attributes.frame.minY - anchor.relativeOffset)
                }
            } else {
                targetOffset = fallbackAnchorOffset(for: anchor) ?? anchor.contentOffset
            }
        case .contentOffset:
            targetOffset = anchor.contentOffset
        case .top:
            targetOffset = CGPoint(x: -collectionView.adjustedContentInset.left,
                                   y: -collectionView.adjustedContentInset.top)
        case .none:
            targetOffset = collectionView.contentOffset
        }

        collectionView.setContentOffset(clampedContentOffset(targetOffset), animated: false)
        for rowID in anchor.selectedRowIDs {
            guard let indexPath = diffableDataSource.indexPath(for: rowID) else { continue }
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }

    private func fallbackAnchorOffset(for anchor: PTCollectionLayoutViewportAnchor) -> CGPoint? {
        guard let originalIndexPath = anchor.originalIndexPath else { return nil }
        let snapshot = diffableDataSource.snapshot()
        guard !snapshot.sectionIdentifiers.isEmpty else { return nil }

        let preferredSection = min(max(originalIndexPath.section, 0), snapshot.sectionIdentifiers.count - 1)
        let sectionOrder = snapshot.sectionIdentifiers.indices.sorted {
            abs($0 - preferredSection) < abs($1 - preferredSection)
        }
        for sectionIndex in sectionOrder {
            let sectionID = snapshot.sectionIdentifiers[sectionIndex]
            let itemIDs = snapshot.itemIdentifiers(inSection: sectionID)
            guard !itemIDs.isEmpty else { continue }
            let itemIndex = min(max(originalIndexPath.item, 0), itemIDs.count - 1)
            let fallbackID = itemIDs[itemIndex]
            guard let indexPath = diffableDataSource.indexPath(for: fallbackID),
                  let attributes = collectionView.layoutAttributesForItem(at: indexPath) else { continue }
            if anchor.isHorizontal {
                return CGPoint(x: attributes.frame.minX - anchor.relativeOffset,
                               y: collectionView.contentOffset.y)
            }
            return CGPoint(x: collectionView.contentOffset.x,
                           y: attributes.frame.minY - anchor.relativeOffset)
        }
        return nil
    }

    private func clampedContentOffset(_ offset: CGPoint) -> CGPoint {
        let inset = collectionView.adjustedContentInset
        let minX = -inset.left
        let minY = -inset.top
        let maxX = max(minX, collectionView.contentSize.width - collectionView.bounds.width + inset.right)
        let maxY = max(minY, collectionView.contentSize.height - collectionView.bounds.height + inset.bottom)
        return CGPoint(x: min(max(offset.x, minX), maxX),
                       y: min(max(offset.y, minY), maxY))
    }

    func applyCollectionBehavior(from config: PTCollectionViewConfig) {
        let view = collectionView
        view.showsVerticalScrollIndicator = config.showsVerticalScrollIndicator
        view.showsHorizontalScrollIndicator = config.showsHorizontalScrollIndicator
        view.contentInsetAdjustmentBehavior = config.contentInsetAdjustmentBehavior
        view.contentOffSetZero = config.contentOffSetZero
        view.dragInteractionEnabled = config.canMoveItem
        view.prefetchDataSource = config.viewForPhoto ? self : nil

        switch config.viewType {
        case .Normal, .Gird, .WaterFall, .Tag:
            view.alwaysBounceHorizontal = false
            view.alwaysBounceVertical = true
        case .Custom:
            view.alwaysBounceHorizontal = config.alwaysBounceHorizontal
            view.alwaysBounceVertical = config.alwaysBounceVertical
        case .Horizontal, .HorizontalLayoutSystem:
            view.alwaysBounceHorizontal = true
            view.alwaysBounceVertical = false
        }

        if config.canMoveItem {
            view.allowsMoveItem()
        }
        refreshCoordinator.configure(view,
                                     config: config,
                                     onHeader: { [weak self] in
                                         PTGCDManager.shared.runOnMain {
                                             self?.headerRefreshTask?()
                                         }
                                     },
                                     onFooter: { [weak self] in
                                         PTGCDManager.shared.runOnMain {
                                             self?.footRefreshTask?()
                                         }
                                     })
        setIndexViews()
        if isSkeletonVisible { updateSkeletonLayout() }
    }
}

@MainActor
extension PTCollectionViewConfig {
    // English: Clone every public configuration field before a queued transaction mutates it.
    // Español: Clona todos los campos públicos antes de que una transacción encolada los modifique.
    // 中文：排队事务修改配置前，先复制所有公开配置字段。
    func pt_runtimeCopy() -> PTCollectionViewConfig {
        let copy = PTCollectionViewConfig()
        copy.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        copy.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        copy.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
        copy.viewType = viewType
        copy.rowCount = rowCount
        copy.itemHeight = itemHeight
        copy.itemWidth = itemWidth
        copy.itemOriginalX = itemOriginalX
        copy.contentTopSpace = contentTopSpace
        copy.contentBottomSpace = contentBottomSpace
        copy.cellLeadingSpace = cellLeadingSpace
        copy.cellTrailingSpace = cellTrailingSpace
        copy.tagCellContentSpace = tagCellContentSpace
        copy.topRefresh = topRefresh
        copy.footerRefresh = footerRefresh
        copy.footerRefreshTextColor = footerRefreshTextColor
        copy.footerRefreshTextFont = footerRefreshTextFont
        copy.footerRefreshIdle = footerRefreshIdle
        copy.footerRefreshPulling = footerRefreshPulling
        copy.footerRefreshRefreshing = footerRefreshRefreshing
        copy.footerRefreshWillRefresh = footerRefreshWillRefresh
        copy.footerRefreshNoMoreData = footerRefreshNoMoreData
        copy.triggerAutomaticallyRefreshPercent = triggerAutomaticallyRefreshPercent
        copy.isAutomaticallyRefresh = isAutomaticallyRefresh
        copy.ignoredScrollViewContentInsetBottom = ignoredScrollViewContentInsetBottom
        copy.sectionEdges = sectionEdges
        copy.headerWidthOffset = headerWidthOffset
        copy.footerWidthOffset = footerWidthOffset
        copy.showEmptyAlert = showEmptyAlert
        copy.emptyViewConfig = emptyViewConfig
        copy.emptyShowType = emptyShowType
        copy.decorationItemsType = decorationItemsType
        copy.decorationItemsEdges = decorationItemsEdges
        copy.decorationModel = decorationModel?.map { model in
            let item = PTDecorationItemModel()
            item.decorationClass = model.decorationClass
            item.decorationID = model.decorationID
            return item
        }
        copy.collectionViewBehavior = collectionViewBehavior
        copy.customReuseViews = customReuseViews
        copy.refreshWithoutAnimation = refreshWithoutAnimation
        copy.structureUpdateAnimationEnabled = structureUpdateAnimationEnabled
        copy.contentUpdateAnimationEnabled = contentUpdateAnimationEnabled
        copy.sideIndexTitles = sideIndexTitles
        if let indexConfig {
            let indexCopy = PTCollectionIndexViewConfiguration()
            indexCopy.itemSize = indexConfig.itemSize
            indexCopy.itemSpacing = indexConfig.itemSpacing
            indexCopy.itemBackgroundColor = indexConfig.itemBackgroundColor
            indexCopy.itemTextColor = indexConfig.itemTextColor
            indexCopy.itemSelectedBackgroundColor = indexConfig.itemSelectedBackgroundColor
            indexCopy.itemSelectedTextColor = indexConfig.itemSelectedTextColor
            indexCopy.indicatorRadius = indexConfig.indicatorRadius
            indexCopy.indicatorBackgroundColor = indexConfig.indicatorBackgroundColor
            indexCopy.indicatorTextColor = indexConfig.indicatorTextColor
            indexCopy.indexViewBackgroundColor = indexConfig.indexViewBackgroundColor
            indexCopy.indexViewFont = indexConfig.indexViewFont
            indexCopy.indexViewHudFont = indexConfig.indexViewHudFont
            indexCopy.containerTopOffset = indexConfig.containerTopOffset
            indexCopy.containerBottomOffset = indexConfig.containerBottomOffset
            indexCopy.indexContainerRightOffset = indexConfig.indexContainerRightOffset
            copy.indexConfig = indexCopy
        }
        copy.canMoveItem = canMoveItem
        copy.alwaysBounceHorizontal = alwaysBounceHorizontal
        copy.alwaysBounceVertical = alwaysBounceVertical
        copy.contentOffSetZero = contentOffSetZero
        copy.viewForPhoto = viewForPhoto
        copy.previewImageSize = previewImageSize
        copy.pinHeaderToVisibleBounds = pinHeaderToVisibleBounds
        copy.pinFooterToVisibleBounds = pinFooterToVisibleBounds
        copy.enableSmartPrefetch = enableSmartPrefetch
        copy.prefetchThreshold = prefetchThreshold
        copy.skeletonItemCount = skeletonItemCount
        copy.skeletonCornerRadius = skeletonCornerRadius
        return copy
    }
}
