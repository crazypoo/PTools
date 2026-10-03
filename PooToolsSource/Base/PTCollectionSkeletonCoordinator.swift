//
//  PTCollectionSkeletonCoordinator.swift
//  PooTools
//
// English: Keep skeleton presentation and geometry separate from Diffable data updates.
// Español: Mantiene la presentación y la geometría del skeleton separadas de las actualizaciones Diffable.
// 中文：将骨架展示和几何布局与 Diffable 数据更新分离。
//

import UIKit

extension PTCollectionView {
    /// 显示独立的骨架覆盖层，不改变当前 Diffable snapshot。
    public func showSkeleton(itemCount: Int? = nil) {
        let requestedCount = itemCount ?? viewConfig.skeletonItemCount
        activeSkeletonItemCount = min(max(requestedCount, 1), 50)
        isSkeletonVisible = true
        skeletonOverlayView.isHidden = false
        bringSubviewToFront(skeletonOverlayView)
        updateSkeletonLayout()
        skeletonOverlayView.startShimmerIfNeeded()
    }

    /// 隐藏骨架覆盖层，不改变当前空状态或内容状态。
    public func hideSkeleton() {
        guard isSkeletonVisible || !skeletonOverlayView.isHidden else { return }
        isSkeletonVisible = false
        activeSkeletonItemCount = nil
        skeletonOverlayView.stopShimmer()
        skeletonOverlayView.isHidden = true
    }
}

extension PTCollectionView {
    func updateSkeletonLayout() {
        guard isSkeletonVisible else { return }
        bringSubviewToFront(skeletonOverlayView)
        let count = activeSkeletonItemCount ?? viewConfig.skeletonItemCount
        skeletonOverlayView.update(rects: skeletonFrames(itemCount: count), cornerRadius: viewConfig.skeletonCornerRadius)
    }

    fileprivate func skeletonFrames(itemCount: Int) -> [CGRect] {
        let count = min(max(itemCount, 1), 50)
        guard let config = viewConfig else { return [] }
        let bounds = skeletonOverlayView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return [] }

        let leading = max(0, config.itemOriginalX)
        let trailing = max(0, config.itemOriginalX)
        let verticalSpacing = max(0, config.cellTrailingSpace)
        let contentTop = max(0, config.contentTopSpace)
        let contentBottom = max(0, config.contentBottomSpace)
        let contentWidth = max(1, bounds.width - leading - trailing)
        let baseHeight = max(1, config.itemHeight)
        let columnCount = max(1, config.rowCount)
        let columnSpacing = max(0, config.cellLeadingSpace)
        let availableColumnWidth = max(1, (contentWidth - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount))

        func photoHeight(for width: CGFloat, fallback: CGFloat) -> CGFloat {
            guard config.viewForPhoto,
                  config.previewImageSize.width > 0,
                  config.previewImageSize.height > 0 else {
                return fallback
            }
            return max(1, width * config.previewImageSize.height / config.previewImageSize.width)
        }

        switch config.viewType {
        case .Normal, .Custom:
            let width = max(1, bounds.width - leading - trailing)
            let height = photoHeight(for: width, fallback: baseHeight)
            return (0..<count).map { index in
                CGRect(x: leading,
                       y: contentTop + CGFloat(index) * (height + verticalSpacing),
                       width: width,
                       height: height)
            }

        case .Gird, .Tag:
            let height = photoHeight(for: availableColumnWidth, fallback: baseHeight)
            return (0..<count).map { index in
                let row = index / columnCount
                let column = index % columnCount
                return CGRect(x: leading + CGFloat(column) * (availableColumnWidth + columnSpacing),
                              y: contentTop + CGFloat(row) * (height + verticalSpacing),
                              width: availableColumnWidth,
                              height: height)
            }

        case .WaterFall:
            var columnHeights = Array(repeating: contentTop, count: columnCount)
            let heightMultipliers: [CGFloat] = [0.82, 1.0, 1.18]
            return (0..<count).map { index in
                let column = index % columnCount
                let width = availableColumnWidth
                let height = photoHeight(for: width, fallback: baseHeight) * heightMultipliers[index % heightMultipliers.count]
                let frame = CGRect(x: leading + CGFloat(column) * (width + columnSpacing),
                                   y: columnHeights[column],
                                   width: width,
                                   height: max(1, height))
                columnHeights[column] = frame.maxY + verticalSpacing
                return frame
            }

        case .Horizontal, .HorizontalLayoutSystem:
            let width = max(1, config.itemWidth)
            let height = min(baseHeight, max(1, bounds.height - contentTop - contentBottom))
            let y = max(contentTop, (bounds.height - height) / 2)
            return (0..<count).map { index in
                CGRect(x: leading + CGFloat(index) * (width + columnSpacing),
                       y: y,
                       width: width,
                       height: height)
            }
        }
    }
}

//MARK: Get something
extension PTCollectionView {
#if POOTOOLS_PAGINGCONTROL
    public func segmentScrolView() -> UIScrollView {
        collectionView
    }
#endif
    
    public func visibleCells() -> [UICollectionViewCell] {
        collectionView.visibleCells
    }
}

//MARK: MoveItem
extension PTCollectionView {
    public func scrolToItem(indexPath:IndexPath,position:UICollectionView.ScrollPosition) {
        collectionView.scrollToItem(at: indexPath,
                                    at: position,
                                    animated: !PTUIAccessibility.reduceMotionEnabled)
    }
    
    public func mtSelectItem(indexPath:IndexPath,animated:Bool,scrollPosition:UICollectionView.ScrollPosition) {
        collectionView.selectItem(at: indexPath,
                                  animated: animated && !PTUIAccessibility.reduceMotionEnabled,
                                  scrollPosition: scrollPosition)
    }
}
