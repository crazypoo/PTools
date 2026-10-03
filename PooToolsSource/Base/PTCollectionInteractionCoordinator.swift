//
//  PTCollectionInteractionCoordinator.swift
//  PooTools
//
// English: Keep selection, scrolling, drag and drop behavior separate from list data construction.
// Español: Mantiene la selección, el desplazamiento, arrastrar y soltar separados de la construcción de datos.
// 中文：将选择、滚动、拖放行为与列表数据构建分离。
//

import UIKit

//MARK: UICollectionViewDelegate
extension PTCollectionView:UICollectionViewDelegate,UIScrollViewDelegate {
    private func getSafeSectionModel(at index: Int) -> PTSection? {
        let snapshot = self.diffableDataSource.snapshot()
        return dataCoordinator.section(at: index, in: snapshot)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        collectionDidSelect?(collectionView,itemSec,indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        collectionDidEndDisplay?(collectionView, cell, itemSec, indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        
        // 1. 抛出原有的正常展示回调
        collectionWillDisplay?(collectionView, cell, itemSec, indexPath)
        
        // 🌟 修复注入：无感知触底预加载验证逻辑
        if viewConfig.enableSmartPrefetch, let collectionWillReachBottomTask = collectionWillReachBottomTask {
            let snapshot = diffableDataSource.snapshot()
            let totalItems = snapshot.numberOfItems
            let threshold = max(0, viewConfig.prefetchThreshold)
            
            guard totalItems > threshold else { return }

            if let currentItem = diffableDataSource.itemIdentifier(for: indexPath),
               let currentIndex = snapshot.indexOfItem(currentItem) {
                if (totalItems - 1) - currentIndex <= threshold {
                    guard lastPrefetchItemCount != totalItems else { return }
                    lastPrefetchItemCount = totalItems
                    collectionWillReachBottomTask()
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        switch viewConfig.decorationItemsType {
        case .Custom:
            decorationViewReset?(collectionView,view,elementKind,indexPath,itemSec)
        case .Normal,.Corner:
            if let decorationView = view as? PTBaseDecorationView {
                decorationView.configure(
                    backgroundColor: itemSec.decorationBackgroundColor ?? PTAppBaseConfig.share.decorationBackgroundColor,
                    cornerRadius: viewConfig.decorationItemsType == .Normal ? 0 : itemSec.decorationCornerRadius,
                    shadowOpacity: itemSec.decorationShadowOpacity,
                    backgroundImage: itemSec.decorationBackgroundImage
                )
            }
        default:break
        }
    }
        
    // MARK: 移动cell结束
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        itemMoveTo?(collectionView,sourceIndexPath,destinationIndexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return nil }
        if let preView = self.forceController?(collectionView,indexPath,itemSec),let actions = self.forceActions?(collectionView,indexPath,itemSec) {
            return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: {
                return preView
            }, actionProvider: { suggestedActions in
                return UIMenu(title: "", children: actions)
            })
        } else {
            return nil
        }
    }
            
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionWillBeginDecelerating?(cv)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        scrollObserverMultiplexer.notify(cv)
        throttleScrollUpdate()
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionWillBeginDragging?(cv)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let cv = scrollView as? UICollectionView else { return }
        listControllerDidEndDragging?(cv, decelerate)
        collectionDidEndDragging?(cv,decelerate)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionWillEndDraging?(cv,velocity,targetContentOffset)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionDidEndDecelerating?(cv)
        hideIndicator()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionDidEndScrollingAnimation?(cv)
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionDidScrolltoTop?(cv)
    }
}

// 2. 实现 Drag 和 Drop 协议
extension PTCollectionView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    // MARK: - Drag Delegate
    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard viewConfig.canMoveItem else { return [] }
        
        let snapshot = diffableDataSource.snapshot()
        guard indexPath.section < snapshot.sectionIdentifiers.count else { return [] }
        let sectionModel = snapshot.sectionIdentifiers[indexPath.section]
        
        guard let rows = sectionModel.rows, indexPath.item < rows.count else { return [] }
        let rowModel = rows[indexPath.item]
        
        let itemProvider = NSItemProvider(object: rowModel.diffId as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = rowModel
        
        return [dragItem]
    }
    
    // MARK: - Drop Delegate
    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard viewConfig.canMoveItem else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard viewConfig.canMoveItem,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else { return }

        var snapshot = diffableDataSource.snapshot()
        guard sourceIndexPath.section >= 0,
              sourceIndexPath.section < snapshot.sectionIdentifiers.count,
              let sourceItem = diffableDataSource.itemIdentifier(for: sourceIndexPath) else { return }

        let destinationSectionIndex = coordinator.destinationIndexPath?.section ?? sourceIndexPath.section
        guard destinationSectionIndex >= 0,
              destinationSectionIndex < snapshot.sectionIdentifiers.count else { return }

        let sourceSection = snapshot.sectionIdentifiers[sourceIndexPath.section]
        let destinationSection = snapshot.sectionIdentifiers[destinationSectionIndex]
        let sourceItems = snapshot.itemIdentifiers(inSection: sourceSection)
        var destinationItems = snapshot.itemIdentifiers(inSection: destinationSection)
        guard let sourceItemIndex = sourceItems.firstIndex(of: sourceItem) else { return }

        let requestedDestinationIndex = coordinator.destinationIndexPath?.item ?? destinationItems.count
        let destinationIndex = min(max(requestedDestinationIndex, 0), destinationItems.count)
        let isSameSection = sourceSection.identifier == destinationSection.identifier
        var insertionIndex = destinationIndex

        if isSameSection {
            destinationItems.remove(at: sourceItemIndex)
            let adjustedIndex = min(max(destinationIndex - (sourceItemIndex < destinationIndex ? 1 : 0), 0), destinationItems.count)
            guard adjustedIndex != sourceItemIndex else {
                coordinator.drop(item.dragItem, toItemAt: sourceIndexPath)
                return
            }
            insertionIndex = adjustedIndex

            var updatedRows = sourceSection.rows ?? []
            updatedRows.removeAll { $0.diffId == sourceItem.diffId }
            updatedRows.insert(sourceItem, at: min(adjustedIndex, updatedRows.count))
            sourceSection.rows = updatedRows
        } else {
            var sourceRows = sourceSection.rows ?? []
            sourceRows.removeAll { $0.diffId == sourceItem.diffId }
            sourceSection.rows = sourceRows

            var destinationRows = destinationSection.rows ?? []
            destinationRows.insert(sourceItem, at: min(destinationIndex, destinationRows.count))
            destinationSection.rows = destinationRows
        }

        snapshot.deleteItems([sourceItem])
        let remainingItems = destinationItems
        if let anchorItem = remainingItems[safe: insertionIndex] {
            snapshot.insertItems([sourceItem], beforeItem: anchorItem)
        } else {
            snapshot.appendItems([sourceItem], toSection: destinationSection)
        }

        layoutCache.removeAll()
        heightCache.remove(forKey: HeightCacheKey(id: sourceItem.diffId, width: collectionView.bounds.width))
        sourceSection.layoutVersion += 1
        if !isSameSection {
            destinationSection.layoutVersion += 1
        }

        if viewConfig.viewType == .WaterFall, waterFallLayout != nil {
            clearWaterfallCache(section: sourceIndexPath.section)
            clearWaterfallCache(section: destinationSectionIndex)
        }

        let finalIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: destinationIndex, section: destinationSectionIndex)
        let animated = !viewConfig.refreshWithoutAnimation
        applySnapshot(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self else { return }
            self.itemMoveTo?(collectionView, sourceIndexPath, finalIndexPath)
        }

        coordinator.drop(item.dragItem, toItemAt: finalIndexPath)
    }
}

