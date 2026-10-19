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
        guard snapshot.sectionIdentifiers.indices.contains(index) else { return nil }
        return resolvedSection(snapshot.sectionIdentifiers[index])
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemSec = getSafeSectionModel(at: indexPath.section) else { return }
        let logicalIndexPath = logicalIndexPath(for: indexPath)
        // English: Keep the legacy callback's physical index during projection; the new callback carries the logical index.
        // Español: Mantiene el índice físico en el callback heredado durante la proyección; el nuevo callback lleva el índice lógico.
        // 中文：无限投影期间旧回调继续收到物理下标，新回调负责传递逻辑下标。
        let legacyIndexPath = presentationAdapter.isActive ? indexPath : logicalIndexPath
        collectionDidSelect?(collectionView,itemSec,legacyIndexPath)
        if presentationAdapter.isActive,
           let physicalID = diffableDataSource.itemIdentifier(for: indexPath),
           let logicalIndex = presentationAdapter.logicalIndex(for: physicalID) {
            onLogicalItemSelected?(PTCollectionLogicalSelectionContext(
                rowID: presentationAdapter.logicalID(for: physicalID),
                logicalIndexPath: IndexPath(item: logicalIndex, section: logicalIndexPath.section)
            ))
        }
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
        updatePageGeometry(reason: .userScroll)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        autoScrollCoordinator.setInteracting(true)
        collectionWillBeginDragging?(cv)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let cv = scrollView as? UICollectionView else { return }
        if !decelerate {
            // English: Release the interaction gate before completion callbacks so an auto-scroll resume can start immediately.
            // Español: Libera el bloqueo de interacción antes de los callbacks de finalización para que el auto-scroll pueda reanudarse de inmediato.
            // 中文：无减速时先解除交互锁，再执行完成回调，确保自动轮播能够立即恢复。
            autoScrollCoordinator.setInteracting(false)
        }
        listControllerDidEndDragging?(cv, decelerate)
        collectionDidEndDragging?(cv,decelerate)
        if !decelerate {
            updatePageGeometry(reason: .userScroll)
            if let context = currentPageContext { onPageScrollCompleted?(context) }
        }
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let cv = scrollView as? UICollectionView else { return }
        if effectiveScrollStyle.isPaging || effectiveScrollStyle.isInfinite,
           isItemSnap {
            let proposedOffset = effectiveScrollStyle.isHorizontal
                ? targetContentOffset.pointee.x + cv.adjustedContentInset.left
                : targetContentOffset.pointee.y + cv.adjustedContentInset.top
            if let nearest = nearestItemPage(for: proposedOffset),
               let point = itemContentOffset(forPage: nearest.logicalPage) {
                if effectiveScrollStyle.isHorizontal {
                    targetContentOffset.pointee.x = point.x
                } else {
                    targetContentOffset.pointee.y = point.y
                }
            }
        } else if effectiveScrollStyle.isPaging || effectiveScrollStyle.isInfinite,
                  let extent = pageExtent,
                  extent > 0 {
            let current = currentPage
            let velocityValue = effectiveScrollStyle.isHorizontal ? velocity.x : velocity.y
            let proposedOffset = effectiveScrollStyle.isHorizontal
                ? targetContentOffset.pointee.x + cv.adjustedContentInset.left
                : targetContentOffset.pointee.y + cv.adjustedContentInset.top
            var targetPage = Int(round(proposedOffset / extent))
            if !viewConfig.scrollConfiguration.paging.allowsSkippingPages {
                targetPage = current + (velocityValue > 0.1 ? 1 : velocityValue < -0.1 ? -1 : 0)
            }
            if effectiveScrollStyle.isInfinite {
                targetPage = ((targetPage % max(totalPages, 1)) + max(totalPages, 1)) % max(totalPages, 1)
            } else {
                targetPage = max(0, min(targetPage, max(totalPages - 1, 0)))
            }
            if let physicalIndex = presentationAdapter.isActive
                ? presentationAdapter.physicalIndex(for: targetPage)
                : Optional(targetPage) {
                let offset = CGFloat(physicalIndex) * extent
                if effectiveScrollStyle.isHorizontal {
                    targetContentOffset.pointee.x = offset - cv.adjustedContentInset.left
                } else {
                    targetContentOffset.pointee.y = offset - cv.adjustedContentInset.top
                }
            }
        }
        collectionWillEndDraging?(cv,velocity,targetContentOffset)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        // English: Keep auto-scroll paused until UIKit confirms deceleration has ended, then let completion callbacks resume it.
        // Español: Mantiene el auto-scroll pausado hasta que UIKit confirme el fin de la desaceleración y después permite reanudarlo.
        // 中文：只有 UIKit 确认减速结束后才解除自动轮播暂停，再执行完成回调恢复轮播。
        autoScrollCoordinator.setInteracting(false)
        collectionDidEndDecelerating?(cv)
        hideIndicator()
        updatePageGeometry(reason: .userScroll)
        if let context = currentPageContext { onPageScrollCompleted?(context) }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let cv = scrollView as? UICollectionView else { return }
        collectionDidEndScrollingAnimation?(cv)
        updatePageGeometry(reason: .programmatic)
        if let context = currentPageContext { onPageScrollCompleted?(context) }
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
        let sectionModel = resolvedSection(snapshot.sectionIdentifiers[indexPath.section])
        
        guard let rows = sectionModel.rows, indexPath.item < rows.count else { return [] }
        let rowModel = resolvedRow(rows[indexPath.item])
        let context = PTCollectionCellContext(section: sectionModel,
                                               row: rowModel,
                                               indexPath: indexPath,
                                               logicalIndexPath: logicalIndexPath(for: indexPath),
                                               logicalRowID: PTRowIdentifier(rowModel.diffId),
                                               isInfiniteProjection: presentationAdapter.isActive)
        if let canBeginDrag, !canBeginDrag(context) { return [] }

        dragCoordinator.begin(sourceRowIDs: [PTRowIdentifier(rowModel.diffId)],
                              sourceIndexPaths: [indexPath],
                              isLocalSession: true) { [weak self] phase, outcome, proposed, final in
            self?.emitDragLifecycle(phase: phase, outcome: outcome, proposed: proposed, final: final)
        }
        
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
            dragCoordinator.update(phase: .moved,
                                   proposed: destinationIndexPath,
                                   emit: { [weak self] phase, outcome, proposed, final in
                self?.emitDragLifecycle(phase: phase, outcome: outcome, proposed: proposed, final: final)
            })
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard viewConfig.canMoveItem,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else { return }

        let requestedDestinationIndexPath = coordinator.destinationIndexPath ?? sourceIndexPath
        let sourceRowID = (item.dragItem.localObject as? PTRows)?.diffId
            ?? diffableDataSource.itemIdentifier(for: sourceIndexPath)?.diffId
        guard let sourceRowID else { return }

        if let sessionID = dragCoordinator.sessionID {
            let context = PTCollectionDragContext(sessionID: sessionID,
                                                  phase: .dropRequested,
                                                  outcome: .pending,
                                                  sourceRowIDs: dragCoordinator.sourceRowIDs,
                                                  sourceLogicalIndexPaths: dragCoordinator.sourceIndexPaths.map(logicalIndexPath(for:)),
                                                  proposedDestination: requestedDestinationIndexPath,
                                                  finalDestination: nil,
                                                  isLocalSession: dragCoordinator.isLocalSession)
            if let canDropItem, !canDropItem(context) {
                emitDragLifecycle(phase: .dropRejected,
                                  outcome: .rejected,
                                  proposed: requestedDestinationIndexPath,
                                  final: nil)
                dragCoordinator.end(phase: .ended,
                                    outcome: .rejected,
                                    proposed: requestedDestinationIndexPath,
                                    emit: { [weak self] phase, outcome, proposed, final in
                    self?.emitDragLifecycle(phase: phase, outcome: outcome, proposed: proposed, final: final)
                })
                return
            }
        }

        // English: Complete the drop interaction immediately; serialize only the model and snapshot mutation.
        // Español: Completa de inmediato la interacción de soltar; solo serializa la mutación del modelo y del snapshot.
        // 中文：先立即完成拖放交互，只将模型和快照变更交给串行队列。
        coordinator.drop(item.dragItem, toItemAt: requestedDestinationIndexPath)

        updateCoordinator.enqueue(name: "moveItem") { [weak self] finish in
            guard let self else {
                finish()
                return
            }

            var snapshot = self.diffableDataSource.snapshot()
            guard let sourceItem = snapshot.itemIdentifiers.first(where: { $0.diffId == sourceRowID }) else {
                finish()
                return
            }

            let sourceSectionIndex = snapshot.sectionIdentifiers.firstIndex { section in
                snapshot.itemIdentifiers(inSection: section).contains(sourceItem)
            }
            guard let sourceSectionIndex else {
                finish()
                return
            }

            let destinationSectionIndex = min(
                max(requestedDestinationIndexPath.section, 0),
                max(snapshot.sectionIdentifiers.count - 1, 0)
            )
            guard snapshot.sectionIdentifiers.indices.contains(destinationSectionIndex) else {
                finish()
                return
            }

            let sourceSectionSnapshot = snapshot.sectionIdentifiers[sourceSectionIndex]
            let destinationSectionSnapshot = snapshot.sectionIdentifiers[destinationSectionIndex]
            let sourceSection = self.resolvedSection(sourceSectionSnapshot)
            let destinationSection = self.resolvedSection(destinationSectionSnapshot)
            let sourceItems = snapshot.itemIdentifiers(inSection: sourceSectionSnapshot)
            var destinationItems = snapshot.itemIdentifiers(inSection: destinationSectionSnapshot)
            guard let sourceItemIndex = sourceItems.firstIndex(of: sourceItem) else {
                finish()
                return
            }

            let requestedDestinationIndex = min(
                max(requestedDestinationIndexPath.item, 0),
                destinationItems.count
            )
            let isSameSection = sourceSectionSnapshot.identifier == destinationSectionSnapshot.identifier
            var insertionIndex = requestedDestinationIndex

            if isSameSection {
                destinationItems.remove(at: sourceItemIndex)
                let adjustedIndex = min(
                    max(requestedDestinationIndex - (sourceItemIndex < requestedDestinationIndex ? 1 : 0), 0),
                    destinationItems.count
                )
                guard adjustedIndex != sourceItemIndex else {
                    finish()
                    return
                }
                insertionIndex = adjustedIndex

                var updatedRows = sourceSection.rows ?? []
                updatedRows.removeAll { $0.diffId == sourceItem.diffId }
                updatedRows.insert(self.resolvedRow(sourceItem), at: min(adjustedIndex, updatedRows.count))
                sourceSection.rows = updatedRows
            } else {
                var sourceRows = sourceSection.rows ?? []
                sourceRows.removeAll { $0.diffId == sourceItem.diffId }
                sourceSection.rows = sourceRows

                var destinationRows = destinationSection.rows ?? []
                destinationRows.insert(self.resolvedRow(sourceItem), at: min(requestedDestinationIndex, destinationRows.count))
                destinationSection.rows = destinationRows
            }

            snapshot.deleteItems([sourceItem])
            if let anchorItem = destinationItems[safe: insertionIndex] {
                snapshot.insertItems([sourceItem], beforeItem: anchorItem)
            } else {
                snapshot.appendItems([sourceItem], toSection: destinationSectionSnapshot)
            }

            self.layoutCache.removeAll()
            self.heightCache.remove(forKey: HeightCacheKey(id: sourceItem.diffId,
                                                           width: collectionView.bounds.width,
                                                           layoutRevision: self.runtimeLayoutRevision))
            sourceSection.layoutVersion += 1
            if !isSameSection {
                destinationSection.layoutVersion += 1
            }

            if self.viewConfig.viewType == .WaterFall, self.waterFallLayout != nil {
                self.clearWaterfallCache(section: sourceSectionIndex)
                self.clearWaterfallCache(section: destinationSectionIndex)
            }

            self.synchronizeModelStore(with: snapshot)
            let finalIndexPath = IndexPath(item: insertionIndex, section: destinationSectionIndex)
            let animated = !self.viewConfig.refreshWithoutAnimation
            self.applySnapshot(snapshot, animatingDifferences: animated) { [weak self] in
                if let self,
                   let sessionID = self.dragCoordinator.sessionID {
                    let commitContext = PTCollectionDragContext(
                        sessionID: sessionID,
                        phase: .dropCommitted,
                        outcome: .committed,
                        sourceRowIDs: self.dragCoordinator.sourceRowIDs,
                        sourceLogicalIndexPaths: self.dragCoordinator.sourceIndexPaths.map(self.logicalIndexPath(for:)),
                        proposedDestination: requestedDestinationIndexPath,
                        finalDestination: finalIndexPath,
                        isLocalSession: self.dragCoordinator.isLocalSession
                    )
                    self.onDragCommit?(commitContext)
                }
                self?.itemMoveTo?(collectionView, sourceIndexPath, finalIndexPath)
                self?.emitDragLifecycle(phase: .dropCommitted,
                                        outcome: .committed,
                                        proposed: requestedDestinationIndexPath,
                                        final: finalIndexPath)
                self?.dragCoordinator.end(phase: .ended,
                                          outcome: .committed,
                                          proposed: requestedDestinationIndexPath,
                                          final: finalIndexPath,
                                          emit: { [weak self] phase, outcome, proposed, final in
                    self?.emitDragLifecycle(phase: phase, outcome: outcome, proposed: proposed, final: final)
                })
                finish()
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        guard dragCoordinator.sessionID != nil else { return }
        dragCoordinator.end(phase: .cancelled,
                            outcome: .cancelled,
                            emit: { [weak self] phase, outcome, proposed, final in
            self?.emitDragLifecycle(phase: phase, outcome: outcome, proposed: proposed, final: final)
        })
    }
}
