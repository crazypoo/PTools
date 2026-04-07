//
//  UICollectionView+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/21.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension UICollectionView {
    
    // MARK: - 基础功能
    /**
     获取 CollectionView 所有 Section 的 Item 总数。
     */
    func numberOfItems() -> Int {
        return (0..<numberOfSections).reduce(0) { $0 + numberOfItems(inSection: $1) }
    }

    /// 验证 IndexPath 是否越界，防止直接访问导致 Crash
    func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        return indexPath.section >= 0 &&
               indexPath.item >= 0 &&
               indexPath.section < numberOfSections &&
               indexPath.item < numberOfItems(inSection: indexPath.section)
    }
    
    // MARK: - 重载 Layout
    /// 重载 Layout
    func invalidateLayout(animated: Bool) {
        if animated {
            performBatchUpdates({
                self.collectionViewLayout.invalidateLayout()
            }, completion: nil)
        } else {
            collectionViewLayout.invalidateLayout()
        }
    }
    
    // MARK: - 撇除動畫重加載
    /// 撇除動畫重加載
    /// 注：修复了原生 reloadData 没有闭包的问题，使用 layoutIfNeeded 确保 UI 刷新完成
    @objc func reloadDataWithOutAnimation(completion: PTActionTask?) {
        UIView.performWithoutAnimation {
            self.reloadData()
            self.layoutIfNeeded() // 强制触发布局更新
            completion?()
        }
    }
    
    // MARK: - 獲取Cell在Window的位置
    /// 獲取Cell在Window的位置
    /// 注：去除了危险的 AppWindows! 强制解包，改用更安全的获取方式
    @objc func cellInWindow(cellFrame: CGRect) -> CGRect {
        let cellInCollectionViewRect = self.convert(cellFrame, to: self)
        
        // 安全获取当前 KeyWindow
        let keyWindow = AppWindows ?? self.window
        guard let window = keyWindow else { return cellInCollectionViewRect }
        
        return self.convert(cellInCollectionViewRect, to: window)
    }
    
    // MARK: - Gird 形式布局计算
    @objc class func girdCollectionContentHeight(data: [AnyObject]?,
                                                 groupW: CGFloat = CGFloat.kSCREEN_WIDTH,
                                                 itemHeight: CGFloat,
                                                 cellRowCount: NSInteger = 3,
                                                 originalX: CGFloat = 10,
                                                 topContentSpace: CGFloat = 0,
                                                 bottomContentSpace: CGFloat = 0,
                                                 cellLeadingSpace: CGFloat = 0,
                                                 cellTrailingSpace: CGFloat = 0,
                                                 handle: (_ groupHeight: CGFloat, _ groupItem: [NSCollectionLayoutGroupCustomItem]) -> Void) {
        let result = UICollectionView.girdCollectionContentHeight(data: data, groupW: groupW, itemHeight: itemHeight, cellRowCount: cellRowCount, originalX: originalX, topContentSpace: topContentSpace, bottomContentSpace: bottomContentSpace, cellLeadingSpace: cellLeadingSpace, cellTrailingSpace: cellTrailingSpace)
        handle(result.0, result.1)
    }
    
    class func girdCollectionContentHeight(data: [AnyObject]?,
                                           groupW: CGFloat = CGFloat.kSCREEN_WIDTH,
                                           itemHeight: CGFloat,
                                           cellRowCount: NSInteger = 3,
                                           originalX: CGFloat = 10,
                                           topContentSpace: CGFloat = 0,
                                           bottomContentSpace: CGFloat = 0,
                                           cellLeadingSpace: CGFloat = 0,
                                           cellTrailingSpace: CGFloat = 0) -> (CGFloat, [NSCollectionLayoutGroupCustomItem]) {
        guard let data = data, !data.isEmpty else { return (0, []) }
        
        var customers = [NSCollectionLayoutGroupCustomItem]()
        // 性能优化：提前分配内存容量
        customers.reserveCapacity(data.count)
        
        var groupH: CGFloat = 0
        let itemH = max(0.1, itemHeight)
        
        // 安全优化：防止 cellRowCount 为 0 导致除以 0 崩溃；防止宽度为负数导致 Layout 崩溃
        let safeRowCount = max(1, cellRowCount)
        let rawItemW = (groupW - originalX * 2 - CGFloat(safeRowCount - 1) * cellLeadingSpace) / CGFloat(safeRowCount)
        let itemW = max(0.1, rawItemW)
        
        var x: CGFloat = originalX
        var y: CGFloat = topContentSpace
        
        data.enumerated().forEach { (index, value) in
            if index < safeRowCount {
                let customItem = NSCollectionLayoutGroupCustomItem(frame: CGRect(x: x, y: y, width: itemW, height: itemH), zIndex: 1000 + index)
                customers.append(customItem)
                x += itemW + cellLeadingSpace
            } else {
                if index > 0 && (index % safeRowCount == 0) {
                    x = originalX
                    y += itemH + cellTrailingSpace
                } else {
                    x += itemW + cellLeadingSpace
                }
                
                let customItem = NSCollectionLayoutGroupCustomItem(frame: CGRect(x: x, y: y, width: itemW, height: itemH), zIndex: 1000 + index)
                customers.append(customItem)
            }
            
            if index == (data.count - 1) {
                groupH = y + itemH + bottomContentSpace
            }
        }
        return (groupH, customers)
    }
    
    @objc class func girdCollectionLayout(data: [AnyObject]?,
                                          groupWidth: CGFloat = CGFloat.kSCREEN_WIDTH,
                                          itemHeight: CGFloat,
                                          cellRowCount: NSInteger = 3,
                                          originalX: CGFloat = 10,
                                          topContentSpace: CGFloat = 0,
                                          bottomContentSpace: CGFloat = 0,
                                          cellLeadingSpace: CGFloat = 0,
                                          cellTrailingSpace: CGFloat = 0,
                                          sectionContentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) -> NSCollectionLayoutGroup {
        
        let result = UICollectionView.girdCollectionContentHeight(data: data, groupW: groupWidth, itemHeight: itemHeight, cellRowCount: cellRowCount, originalX: originalX, topContentSpace: topContentSpace, bottomContentSpace: bottomContentSpace, cellLeadingSpace: cellLeadingSpace, cellTrailingSpace: cellTrailingSpace)
        
        // 安全优化：保证 group 的宽和高始终为正数，防止闪退
        let safeGroupWidth = max(0.1, groupWidth - originalX * 2)
        let safeGroupHeight = max(0.1, result.0)
        
        let bannerGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(safeGroupWidth),
                                                     heightDimension: .absolute(safeGroupHeight))
        
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { _ in
            return result.1
        })
    }
    
    // MARK: - WaterFallLayout (瀑布流布局)
    @objc class func waterFallLayout(data: [AnyObject]?,
                                     screenWidth: CGFloat = CGFloat.kSCREEN_WIDTH,
                                     rowCount: Int = 2,
                                     itemOriginalX: CGFloat = PTAppBaseConfig.share.defaultViewSpace,
                                     topContentSpace: CGFloat = 0,
                                     bottomContentSpace: CGFloat = 0,
                                     itemSpace: CGFloat,
                                     itemTrailingSpace: CGFloat = 0,
                                     itemHeight: (Int, AnyObject) -> CGFloat) -> NSCollectionLayoutGroup {
        
        guard let data = data, !data.isEmpty else {
            let size = NSCollectionLayoutSize(widthDimension: .absolute(max(0.1, screenWidth)), heightDimension: .absolute(0.1))
            return NSCollectionLayoutGroup.custom(layoutSize: size) { _ in [] }
        }
        
        let safeRowCount = max(1, rowCount)
        let rawCellWidth = (screenWidth - itemOriginalX * 2 - CGFloat(safeRowCount - 1) * itemSpace) / CGFloat(safeRowCount)
        let cellWidth = max(0.1, rawCellWidth)
        
        var columnHeights = Array(repeating: topContentSpace, count: safeRowCount)
        let columnX: [CGFloat] = (0..<safeRowCount).map { itemOriginalX + CGFloat($0) * (cellWidth + itemSpace) }
        
        var customItems: [NSCollectionLayoutGroupCustomItem] = []
        customItems.reserveCapacity(data.count) // 性能提升
        
        for (index, model) in data.enumerated() {
            let height = max(0.1, itemHeight(index, model))
            
            guard let minColumnIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset else {
                continue
            }
            
            let x = columnX[minColumnIndex]
            let y = columnHeights[minColumnIndex]
            let frame = CGRect(x: x, y: y, width: cellWidth, height: height)
            
            let item = NSCollectionLayoutGroupCustomItem(frame: frame, zIndex: 1000 + index)
            customItems.append(item)
            
            columnHeights[minColumnIndex] = frame.maxY + itemTrailingSpace
        }
        
        // 修正隐藏的 Bug: 避免减去 trailing space 后为负数
        let calculatedMax = (columnHeights.max() ?? topContentSpace) - itemTrailingSpace + bottomContentSpace
        let maxHeight = max(0.1, calculatedMax)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(max(0.1, screenWidth)), heightDimension: .absolute(maxHeight))
        
        return NSCollectionLayoutGroup.custom(layoutSize: groupSize) { _ in return customItems }
    }
    
    // MARK: - TagShowLayout (标签流水布局)
    @objc class func tagShowLayout(data: [PTTagLayoutModel]?,
                                   screenWidth: CGFloat = CGFloat.kSCREEN_WIDTH,
                                   itemOriginalX: CGFloat = PTAppBaseConfig.share.defaultViewSpace,
                                   itemHeight: CGFloat = 32,
                                   topContentSpace: CGFloat = 10,
                                   bottomContentSpace: CGFloat = 10,
                                   itemLeadingSpace: CGFloat = 10,
                                   itemTrailingSpace: CGFloat = 10,
                                   itemContentSpace: CGFloat = 20) -> NSCollectionLayoutGroup {
        
        let result = UICollectionView.tagShowLayoutHeight(data: data, screenWidth: screenWidth, itemOriginalX: itemOriginalX, itemHeight: itemHeight, topContentSpace: topContentSpace, bottomContentSpace: bottomContentSpace, itemLeadingSpace: itemLeadingSpace, itemTrailingSpace: itemTrailingSpace, itemContentSpace: itemContentSpace)

        let safeGroupHeight = max(0.1, result.groupHeight)
        let bannerGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(max(0.1, screenWidth)), heightDimension: .absolute(safeGroupHeight))
        
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { _ in
            return result.groupItems
        })
    }
    
    class func tagShowLayoutHeight(data: [PTTagLayoutModel]?,
                                   screenWidth: CGFloat = CGFloat.kSCREEN_WIDTH,
                                   itemOriginalX: CGFloat = PTAppBaseConfig.share.defaultViewSpace,
                                   itemHeight: CGFloat = 32,
                                   topContentSpace: CGFloat = 10,
                                   bottomContentSpace: CGFloat = 10,
                                   itemLeadingSpace: CGFloat = 10,
                                   itemTrailingSpace: CGFloat = 10,
                                   itemContentSpace: CGFloat = 20) -> (groupHeight: CGFloat, groupItems: [NSCollectionLayoutGroupCustomItem], columnCount: Int) {
        guard let datas = data, !datas.isEmpty else {
            return (topContentSpace + bottomContentSpace, [], 0)
        }

        var customItems: [NSCollectionLayoutGroupCustomItem] = []
        customItems.reserveCapacity(datas.count)
        
        var x = itemOriginalX
        var y: CGFloat = topContentSpace
        var columnCount = 1

        let maxRowWidth = max(0.1, screenWidth - itemOriginalX * 2)
        let safeItemHeight = max(0.1, itemHeight)

        func calculateCellWidth(for model: PTTagLayoutModel) -> CGFloat {
            var width = UIView.sizeFor(string: model.name, font: model.contentFont, height: safeItemHeight).width + itemContentSpace
            if model.haveImage {
                width += model.imageWidth + model.contentSpace
            }
            return min(width, maxRowWidth) // 防止单个标签太长撑爆屏幕
        }

        for (index, model) in datas.enumerated() {
            let currentWidth = calculateCellWidth(for: model)

            if x + currentWidth > (screenWidth - itemOriginalX) { // 换行逻辑优化：基于屏幕右侧边缘计算
                x = itemOriginalX
                y += safeItemHeight + itemTrailingSpace
                columnCount += 1
            }

            let frame = CGRect(x: x, y: y, width: currentWidth, height: safeItemHeight)
            let item = NSCollectionLayoutGroupCustomItem(frame: frame, zIndex: 1000 + index)
            customItems.append(item)

            x += currentWidth + itemLeadingSpace
        }

        let totalHeight = y + safeItemHeight + bottomContentSpace
        return (totalHeight, customItems, columnCount)
    }
    
    // MARK: - 横向布局 (Horizontal)
    @objc class func horizontalLayout(data: [AnyObject]?,
                                      itemOriginalX: CGFloat = PTAppBaseConfig.share.defaultViewSpace,
                                      itemWidth: CGFloat = 100,
                                      itemHeight: CGFloat = 44,
                                      topContentSpace: CGFloat = 10,
                                      bottomContentSpace: CGFloat = 10,
                                      itemLeadingSpace: CGFloat = 10) -> NSCollectionLayoutGroup {
        var groupWidth: CGFloat = itemOriginalX
        var customers = [NSCollectionLayoutGroupCustomItem]()
        
        if let data = data {
            customers.reserveCapacity(data.count)
            data.enumerated().forEach { (index, _) in
                let customItem = NSCollectionLayoutGroupCustomItem(frame: CGRect(x: groupWidth, y: topContentSpace, width: max(0.1, itemWidth), height: max(0.1, itemHeight)), zIndex: 1000 + index)
                customers.append(customItem)
                groupWidth += (itemWidth + itemLeadingSpace)
            }
        }
        
        let safeGroupWidth = max(0.1, groupWidth)
        let bannerGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(safeGroupWidth), heightDimension: .absolute(max(0.1, itemHeight + topContentSpace + bottomContentSpace)))
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { _ in return customers })
    }
    
    @objc class func horizontalLayoutSystem(data: [AnyObject]?,
                                            itemOriginalX: CGFloat = PTAppBaseConfig.share.defaultViewSpace,
                                            itemWidth: CGFloat = 100,
                                            itemHeight: CGFloat = 44,
                                            topContentSpace: CGFloat = 10,
                                            bottomContentSpace: CGFloat = 10,
                                            itemLeadingSpace: CGFloat = 10) -> NSCollectionLayoutGroup {
        var groupWidth: CGFloat = itemOriginalX
        var customers = [NSCollectionLayoutItem]()
        
        if let data = data {
            customers.reserveCapacity(data.count)
            data.enumerated().forEach { (index, _) in
                let customItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(max(0.1, itemWidth)), heightDimension: .absolute(max(0.1, itemHeight))))
                customItem.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: NSCollectionLayoutSpacing.fixed(index == 0 ? itemOriginalX : itemLeadingSpace), top: NSCollectionLayoutSpacing.fixed(topContentSpace), trailing: NSCollectionLayoutSpacing.fixed(0), bottom: NSCollectionLayoutSpacing.fixed(bottomContentSpace))
                customers.append(customItem)
                groupWidth += (itemWidth + itemLeadingSpace)
            }
        }
        
        let safeGroupWidth = max(0.1, groupWidth)
        let bannerGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(safeGroupWidth), heightDimension: .absolute(max(0.1, itemHeight + topContentSpace + bottomContentSpace)))
        return NSCollectionLayoutGroup.horizontal(layoutSize: bannerGroupSize, subitems: customers)
    }
    
    // MARK: - 移动 Item 手势
    /// 允许手势移动Item，默认不允许
    func allowsMoveItem() {
        // 防止重复添加长按手势导致响应混乱
        if let gestures = self.gestureRecognizers, gestures.contains(where: { $0 is UILongPressGestureRecognizer }) {
            return
        }
        
        // 假定此处使用的是自定义扩展支持闭包回调。关键优化：加入 [weak self] 防止内存泄漏！
        let longPressGesture = UILongPressGestureRecognizer { [weak self] sender in
            guard let self = self, let gesture = sender as? UILongPressGestureRecognizer else { return }
            
            switch gesture.state {
            case .began:
                if let gesView = gesture.view {
                    let point = gesture.location(in: gesView)
                    if let selectedIndexPath = self.indexPathForItem(at: point) {
                        self.beginInteractiveMovementForItem(at: selectedIndexPath)
                    }
                }
            case .changed:
                if let gesView = gesture.view {
                    let point = gesture.location(in: gesView)
                    self.updateInteractiveMovementTargetPosition(point)
                }
            case .ended:
                self.endInteractiveMovement()
            default:
                self.cancelInteractiveMovement()
            }
        }
        self.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - 横向分页布局
    @objc class func horizontalPagingLayout(data: [AnyObject]?,
                                            monitorWidth: CGFloat = CGFloat.kSCREEN_WIDTH,
                                            itemOriginalX: CGFloat = 0,
                                            itemHeight: CGFloat = 76,
                                            topContentSpace: CGFloat = 0,
                                            bottomContentSpace: CGFloat = 0,
                                            columnCount: Int = 5,
                                            rowCount: Int = 2,
                                            itemLeadingSpace: CGFloat = 15,
                                            itemTrailingSpace: CGFloat = 10) -> NSCollectionLayoutGroup {
        guard let data = data, !data.isEmpty else {
            return NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .absolute(0.1), heightDimension: .absolute(0.1)), subitems: [])
        }

        // 安全校验：防止除数为 0 导致崩溃
        let safeColumnCount = max(1, columnCount)
        let safeRowCount = max(1, rowCount)
        
        let itemsPerPage = safeColumnCount * safeRowCount
        let totalPages = Int(ceil(Double(data.count) / Double(itemsPerPage)))
        let rawItemWidth = (monitorWidth - itemOriginalX * 2 - CGFloat(safeColumnCount - 1) * itemLeadingSpace) / CGFloat(safeColumnCount)
        let itemWidth = max(0.1, rawItemWidth)
        let safeItemHeight = max(0.1, itemHeight)
        
        var customers = [NSCollectionLayoutGroupCustomItem]()
        customers.reserveCapacity(data.count)
        
        var groupHeight: CGFloat = 0

        for (index, _) in data.enumerated() {
            let pageIndex = index / itemsPerPage
            let rowIndex = (index % itemsPerPage) / safeColumnCount
            let columnIndex = index % safeColumnCount

            let x = CGFloat(pageIndex) * monitorWidth + itemOriginalX + CGFloat(columnIndex) * (itemWidth + itemLeadingSpace)
            let y = topContentSpace + CGFloat(rowIndex) * (safeItemHeight + itemTrailingSpace)

            groupHeight = max(groupHeight, y + safeItemHeight + bottomContentSpace)

            let item = NSCollectionLayoutGroupCustomItem(
                frame: CGRect(x: x, y: y, width: itemWidth, height: safeItemHeight),
                zIndex: 1000 + index
            )
            customers.append(item)
        }

        let layoutSize = NSCollectionLayoutSize(
            widthDimension: .absolute(max(0.1, monitorWidth * CGFloat(totalPages))),
            heightDimension: .absolute(max(0.1, groupHeight))
        )

        return NSCollectionLayoutGroup.custom(layoutSize: layoutSize) { _ in return customers }
    }
    
    func hasVisibleCell<T: UICollectionViewCell>(of type: T.Type) -> Bool {
        visibleCells.contains { $0 is T }
    }

    func visibleCell<T: UICollectionViewCell>(of type: T.Type) -> T? {
        visibleCells.first { $0 is T } as? T
    }
}
