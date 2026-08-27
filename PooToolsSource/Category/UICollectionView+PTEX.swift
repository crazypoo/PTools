//
//  UICollectionView+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/21.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

struct PTCollectionLayoutGeometryResult {
    let frames: [CGRect]
    let contentWidth: CGFloat
    let contentHeight: CGFloat
}

enum PTCollectionLayoutGeometry {
    static let minimumDimension: CGFloat = 0.1

    static func roundedUpDivision(_ value: Int, by divisor: Int) -> Int {
        guard value > 0 else { return 0 }
        let safeDivisor = max(1, divisor)
        let quotient = value / safeDivisor
        return quotient + (value % safeDivisor == 0 ? 0 : 1)
    }

    static func finite(_ value: CGFloat, fallback: CGFloat = 0) -> CGFloat {
        value.isFinite ? value : fallback
    }

    static func dimension(_ value: CGFloat, fallback: CGFloat = minimumDimension) -> CGFloat {
        max(minimumDimension, finite(value, fallback: fallback))
    }

    static func grid(itemCount: Int,
                     width: CGFloat,
                     itemHeight: CGFloat,
                     columnCount: Int,
                     itemOriginalX: CGFloat,
                     topContentSpace: CGFloat,
                     bottomContentSpace: CGFloat,
                     itemLeadingSpace: CGFloat,
                     itemTrailingSpace: CGFloat) -> PTCollectionLayoutGeometryResult {
        let safeWidth = dimension(width)
        let safeItemHeight = dimension(itemHeight)
        let safeColumnCount = max(1, columnCount)
        let itemX = finite(itemOriginalX)
        let horizontalSpace = finite(itemLeadingSpace)
        let verticalSpace = finite(itemTrailingSpace)
        let topSpace = finite(topContentSpace)
        let bottomSpace = finite(bottomContentSpace)
        let itemWidth = dimension((safeWidth - itemX * 2 - CGFloat(safeColumnCount - 1) * horizontalSpace) / CGFloat(safeColumnCount))
        let safeCount = max(0, itemCount)
        var frames: [CGRect] = []
        frames.reserveCapacity(safeCount)

        for index in 0..<safeCount {
            let row = index / safeColumnCount
            let column = index % safeColumnCount
            let x = itemX + CGFloat(column) * (itemWidth + horizontalSpace)
            let y = topSpace + CGFloat(row) * (safeItemHeight + verticalSpace)
            frames.append(CGRect(x: x, y: y, width: itemWidth, height: safeItemHeight))
        }

        let rowCount = roundedUpDivision(safeCount, by: safeColumnCount)
        let contentHeight = rowCount == 0
            ? 0
            : topSpace + CGFloat(rowCount) * safeItemHeight + CGFloat(max(0, rowCount - 1)) * verticalSpace + bottomSpace
        return PTCollectionLayoutGeometryResult(frames: frames,
                                                 contentWidth: safeWidth,
                                                 contentHeight: contentHeight)
    }

    static func waterfall(data: [AnyObject],
                          width: CGFloat,
                          rowCount: Int,
                          itemOriginalX: CGFloat,
                          topContentSpace: CGFloat,
                          bottomContentSpace: CGFloat,
                          itemSpace: CGFloat,
                          itemTrailingSpace: CGFloat,
                          itemHeight: (Int, AnyObject) -> CGFloat) -> PTCollectionLayoutGeometryResult {
        let safeWidth = dimension(width)
        let safeCount = data.count
        guard safeCount > 0 else {
            return PTCollectionLayoutGeometryResult(frames: [], contentWidth: safeWidth, contentHeight: minimumDimension)
        }

        // 列数超过数据量时没有必要继续分配空列，避免异常参数造成过大的数组。
        let safeRowCount = min(max(1, rowCount), safeCount)
        let itemX = finite(itemOriginalX)
        let horizontalSpace = finite(itemSpace)
        let verticalSpace = finite(itemTrailingSpace)
        let topSpace = finite(topContentSpace)
        let bottomSpace = finite(bottomContentSpace)
        let cellWidth = dimension((safeWidth - itemX * 2 - CGFloat(safeRowCount - 1) * horizontalSpace) / CGFloat(safeRowCount))

        var columnHeights = Array(repeating: topSpace, count: safeRowCount)
        var frames: [CGRect] = []
        frames.reserveCapacity(data.count)

        for (index, model) in data.enumerated() {
            var shortestColumn = 0
            if safeRowCount > 1 {
                for column in 1..<safeRowCount where columnHeights[column] < columnHeights[shortestColumn] {
                    shortestColumn = column
                }
            }

            let height = dimension(itemHeight(index, model))
            let x = itemX + CGFloat(shortestColumn) * (cellWidth + horizontalSpace)
            let frame = CGRect(x: x,
                               y: columnHeights[shortestColumn],
                               width: cellWidth,
                               height: height)
            frames.append(frame)
            columnHeights[shortestColumn] = frame.maxY + verticalSpace
        }

        let contentHeight = max(minimumDimension,
                                (columnHeights.max() ?? topSpace) - verticalSpace + bottomSpace)
        return PTCollectionLayoutGeometryResult(frames: frames,
                                                 contentWidth: safeWidth,
                                                 contentHeight: contentHeight)
    }

    static func horizontal(itemCount: Int,
                           itemOriginalX: CGFloat,
                           itemWidth: CGFloat,
                           itemHeight: CGFloat,
                           topContentSpace: CGFloat,
                           bottomContentSpace: CGFloat,
                           itemLeadingSpace: CGFloat) -> PTCollectionLayoutGeometryResult {
        let itemX = finite(itemOriginalX)
        let safeItemWidth = dimension(itemWidth)
        let safeItemHeight = dimension(itemHeight)
        let topSpace = finite(topContentSpace)
        let bottomSpace = finite(bottomContentSpace)
        let horizontalSpace = finite(itemLeadingSpace)
        let safeCount = max(0, itemCount)
        var frames: [CGRect] = []
        frames.reserveCapacity(safeCount)

        for index in 0..<safeCount {
            frames.append(CGRect(x: itemX + CGFloat(index) * (safeItemWidth + horizontalSpace),
                                 y: topSpace,
                                 width: safeItemWidth,
                                 height: safeItemHeight))
        }

        let contentWidth = safeCount == 0
            ? max(minimumDimension, itemX)
            : max(minimumDimension, itemX + CGFloat(safeCount) * safeItemWidth + CGFloat(max(0, safeCount - 1)) * horizontalSpace)
        let contentHeight = max(minimumDimension, safeItemHeight + topSpace + bottomSpace)
        return PTCollectionLayoutGeometryResult(frames: frames,
                                                 contentWidth: contentWidth,
                                                 contentHeight: contentHeight)
    }

    static func paging(itemCount: Int,
                       width: CGFloat,
                       itemOriginalX: CGFloat,
                       itemHeight: CGFloat,
                       topContentSpace: CGFloat,
                       bottomContentSpace: CGFloat,
                       columnCount: Int,
                       rowCount: Int,
                       itemLeadingSpace: CGFloat,
                       itemTrailingSpace: CGFloat) -> PTCollectionLayoutGeometryResult {
        let safeWidth = dimension(width)
        let itemX = finite(itemOriginalX)
        let safeItemHeight = dimension(itemHeight)
        let topSpace = finite(topContentSpace)
        let bottomSpace = finite(bottomContentSpace)
        let horizontalSpace = finite(itemLeadingSpace)
        let verticalSpace = finite(itemTrailingSpace)
        let safeColumnCount = max(1, columnCount)
        let safeRowCount = max(1, rowCount)
        let safeCount = max(0, itemCount)
        guard safeCount > 0 else {
            return PTCollectionLayoutGeometryResult(frames: [], contentWidth: minimumDimension, contentHeight: minimumDimension)
        }

        let multiplication = safeColumnCount.multipliedReportingOverflow(by: safeRowCount)
        let itemsPerPage = multiplication.overflow ? Int.max : max(1, multiplication.partialValue)
        let totalPages = roundedUpDivision(safeCount, by: itemsPerPage)
        let itemWidth = dimension((safeWidth - itemX * 2 - CGFloat(safeColumnCount - 1) * horizontalSpace) / CGFloat(safeColumnCount))
        var frames: [CGRect] = []
        frames.reserveCapacity(safeCount)

        for index in 0..<safeCount {
            let page = index / itemsPerPage
            let row = (index % itemsPerPage) / safeColumnCount
            let column = index % safeColumnCount
            frames.append(CGRect(x: CGFloat(page) * safeWidth + itemX + CGFloat(column) * (itemWidth + horizontalSpace),
                                 y: topSpace + CGFloat(row) * (safeItemHeight + verticalSpace),
                                 width: itemWidth,
                                 height: safeItemHeight))
        }

        let rowsInSinglePage = roundedUpDivision(safeCount, by: safeColumnCount)
        let effectiveRowCount = totalPages > 1 ? safeRowCount : rowsInSinglePage
        let contentHeight = max(minimumDimension,
                                topSpace + CGFloat(effectiveRowCount) * safeItemHeight + CGFloat(max(0, effectiveRowCount - 1)) * verticalSpace + bottomSpace)
        return PTCollectionLayoutGeometryResult(frames: frames,
                                                 contentWidth: max(minimumDimension, safeWidth * CGFloat(totalPages)),
                                                 contentHeight: contentHeight)
    }
}

public extension UICollectionView {
    
    // MARK: - 基础功能
    
    /// 获取 CollectionView 所有 Section 的 Item 总数。
    func numberOfItems() -> Int {
        var count = 0
        // 性能微调：使用 for 循环代替 reduce，在简单累加场景下略微提升性能并减少闭包开销
        for section in 0..<numberOfSections {
            count += numberOfItems(inSection: section)
        }
        return count
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
    
    // MARK: - 🐛 [补充功能] 安全滚动
        
    /// 安全地滚动到指定的 IndexPath，防止因数据源未同步导致的 Crash
    /// - Parameters:
    ///   - indexPath: 目标 IndexPath
    ///   - scrollPosition: 滚动位置
    ///   - animated: 是否需要动画
    func safeScrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        guard isValidIndexPath(indexPath) else {
            PTNSLogConsole("⚠️ [UICollectionView] 尝试滚动到无效的 IndexPath: \(indexPath)")
            return
        }
        scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    }

    // MARK: - 🚀 [补充功能] 泛型注册与复用 (超级好用)
        
    /// 泛型注册 Cell (纯代码)
    func register<T: UICollectionViewCell>(cellType: T.Type) {
        register(cellType, forCellWithReuseIdentifier: String(describing: cellType))
    }
    
    /// 泛型注册 Cell (Xib)
    func registerNib<T: UICollectionViewCell>(cellType: T.Type) {
        let nib = UINib(nibName: String(describing: cellType), bundle: nil)
        register(nib, forCellWithReuseIdentifier: String(describing: cellType))
    }
    
    /// 泛型复用 Cell，无需显式强转 (as!)
    func dequeueReusableCell<T: UICollectionViewCell>(with type: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: type)
        guard let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else {
            fatalError("🚨 [UICollectionView] 无法出列类型为 \(identifier) 的 Cell。请确保你已经注册了它！")
        }
        return cell
    }

    // MARK: - 撇除動畫重加載
    /// 撇除動畫重加載
    /// 注：修复了原生 reloadData 没有闭包的问题，使用 layoutIfNeeded 确保 UI 刷新完成
    @objc func reloadDataWithOutAnimation(completion: PTActionTask?) {
        UIView.performWithoutAnimation {
            self.reloadData()
            self.layoutIfNeeded() // 强制触发布局更新
            // 优化：将 completion 放入主线程异步队列，确保在布局彻底渲染完成后才执行回调
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    // MARK: - 獲取Cell在Window的位置
    /// 獲取Cell在Window的位置
    /// 注：去除了危险的 AppWindows! 强制解包，改用更安全的获取方式
    @objc func cellInWindow(cellFrame: CGRect) -> CGRect {
        let keyWindow = AppWindows ?? self.window
        guard let window = keyWindow else { return cellFrame }
        return convert(cellFrame, to: window)
    }
    
    // MARK: - Gird 形式布局计算
    private static func girdCollectionGeometry(data: [AnyObject]?,
                                               groupW: CGFloat?,
                                               itemHeight: CGFloat,
                                               cellRowCount: NSInteger,
                                               originalX: CGFloat,
                                               topContentSpace: CGFloat,
                                               bottomContentSpace: CGFloat,
                                               cellLeadingSpace: CGFloat,
                                               cellTrailingSpace: CGFloat) -> PTCollectionLayoutGeometryResult {
        PTCollectionLayoutGeometry.grid(itemCount: data?.count ?? 0,
                                        width: groupW ?? CGFloat.kSCREEN_WIDTH,
                                        itemHeight: itemHeight,
                                        columnCount: cellRowCount,
                                        itemOriginalX: originalX,
                                        topContentSpace: topContentSpace,
                                        bottomContentSpace: bottomContentSpace,
                                        itemLeadingSpace: cellLeadingSpace,
                                        itemTrailingSpace: cellTrailingSpace)
    }

    private static func makeCustomItems(from frames: [CGRect]) -> [NSCollectionLayoutGroupCustomItem] {
        frames.enumerated().map { index, frame in
            NSCollectionLayoutGroupCustomItem(frame: frame, zIndex: 1000 + index)
        }
    }

    class func girdCollectionContentHeight(data: [AnyObject]?,
                                                 groupW: CGFloat? = nil,
                                                 itemHeight: CGFloat,
                                                 cellRowCount: NSInteger = 3,
                                                 originalX: CGFloat = 10,
                                                 topContentSpace: CGFloat = 0,
                                                 bottomContentSpace: CGFloat = 0,
                                                 cellLeadingSpace: CGFloat = 0,
                                                 cellTrailingSpace: CGFloat = 0,
                                                 handle: (_ groupHeight: CGFloat, _ groupItem: [NSCollectionLayoutGroupCustomItem]) -> Void) {
        let result = girdCollectionGeometry(data: data,
                                             groupW: groupW,
                                             itemHeight: itemHeight,
                                             cellRowCount: cellRowCount,
                                             originalX: originalX,
                                             topContentSpace: topContentSpace,
                                             bottomContentSpace: bottomContentSpace,
                                             cellLeadingSpace: cellLeadingSpace,
                                             cellTrailingSpace: cellTrailingSpace)
        handle(result.contentHeight, makeCustomItems(from: result.frames))
    }
    
    class func girdCollectionContentHeight(data: [AnyObject]?,
                                           groupW: CGFloat? = nil,
                                           itemHeight: CGFloat,
                                           cellRowCount: NSInteger = 3,
                                           originalX: CGFloat = 10,
                                           topContentSpace: CGFloat = 0,
                                           bottomContentSpace: CGFloat = 0,
                                           cellLeadingSpace: CGFloat = 0,
                                           cellTrailingSpace: CGFloat = 0) -> (CGFloat, [NSCollectionLayoutGroupCustomItem]) {
        let result = girdCollectionGeometry(data: data,
                                             groupW: groupW,
                                             itemHeight: itemHeight,
                                             cellRowCount: cellRowCount,
                                             originalX: originalX,
                                             topContentSpace: topContentSpace,
                                             bottomContentSpace: bottomContentSpace,
                                             cellLeadingSpace: cellLeadingSpace,
                                             cellTrailingSpace: cellTrailingSpace)
        return (result.contentHeight, makeCustomItems(from: result.frames))
    }
    
    class func girdCollectionLayout(data: [AnyObject]?,
                                          groupWidth: CGFloat? = nil,
                                          itemHeight: CGFloat,
                                          cellRowCount: NSInteger = 3,
                                          originalX: CGFloat = 10,
                                          topContentSpace: CGFloat = 0,
                                          bottomContentSpace: CGFloat = 0,
                                          cellLeadingSpace: CGFloat = 0,
                                          cellTrailingSpace: CGFloat = 0,
                                          sectionContentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) -> NSCollectionLayoutGroup {
        let result = girdCollectionGeometry(data: data,
                                             groupW: groupWidth,
                                             itemHeight: itemHeight,
                                             cellRowCount: cellRowCount,
                                             originalX: originalX,
                                             topContentSpace: topContentSpace,
                                             bottomContentSpace: bottomContentSpace,
                                             cellLeadingSpace: cellLeadingSpace,
                                             cellTrailingSpace: cellTrailingSpace)
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(result.contentWidth),
                                               heightDimension: .absolute(max(PTCollectionLayoutGeometry.minimumDimension, result.contentHeight)))
        let items = makeCustomItems(from: result.frames)
        let group = NSCollectionLayoutGroup.custom(layoutSize: groupSize) { _ in items }
        return group
    }
    
    // MARK: - WaterFallLayout (瀑布流布局)
    class func waterFallLayout(data: [AnyObject]?,
                                     screenWidth: CGFloat? = nil,
                                     rowCount: Int = 2,
                                     itemOriginalX: CGFloat? = nil,
                                     topContentSpace: CGFloat = 0,
                                     bottomContentSpace: CGFloat = 0,
                                     itemSpace: CGFloat,
                                     itemTrailingSpace: CGFloat = 0,
                                     itemHeight: (Int, AnyObject) -> CGFloat) -> NSCollectionLayoutGroup {
        let result = PTCollectionLayoutGeometry.waterfall(data: data ?? [],
                                                          width: screenWidth ?? CGFloat.kSCREEN_WIDTH,
                                                          rowCount: rowCount,
                                                          itemOriginalX: itemOriginalX ?? PTAppBaseConfig.share.defaultViewSpace,
                                                          topContentSpace: topContentSpace,
                                                          bottomContentSpace: bottomContentSpace,
                                                          itemSpace: itemSpace,
                                                          itemTrailingSpace: itemTrailingSpace,
                                                          itemHeight: itemHeight)
        let items = result.frames.enumerated().map { index, frame in
            NSCollectionLayoutGroupCustomItem(frame: frame, zIndex: 1000 + index)
        }
        let size = NSCollectionLayoutSize(widthDimension: .absolute(result.contentWidth),
                                          heightDimension: .absolute(result.contentHeight))
        return NSCollectionLayoutGroup.custom(layoutSize: size) { _ in items }
    }
    
    // MARK: - TagShowLayout (标签流水布局)
    class func tagShowLayout(data: [PTTagLayoutModel]?,
                                   screenWidth: CGFloat? = nil,
                                   itemOriginalX: CGFloat? = nil,
                                   itemHeight: CGFloat = 32,
                                   topContentSpace: CGFloat = 10,
                                   bottomContentSpace: CGFloat = 10,
                                   itemLeadingSpace: CGFloat = 10,
                                   itemTrailingSpace: CGFloat = 10,
                                   itemContentSpace: CGFloat = 20) -> NSCollectionLayoutGroup {
        let viewW = PTCollectionLayoutGeometry.dimension(screenWidth ?? CGFloat.kSCREEN_WIDTH)
        let itemX = PTCollectionLayoutGeometry.finite(itemOriginalX ?? PTAppBaseConfig.share.defaultViewSpace)

        let result = UICollectionView.tagShowLayoutHeight(data: data, screenWidth: viewW, itemOriginalX: itemX, itemHeight: itemHeight, topContentSpace: topContentSpace, bottomContentSpace: bottomContentSpace, itemLeadingSpace: itemLeadingSpace, itemTrailingSpace: itemTrailingSpace, itemContentSpace: itemContentSpace)

        let safeGroupHeight = max(PTCollectionLayoutGeometry.minimumDimension, result.groupHeight)
        let bannerGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(viewW), heightDimension: .absolute(safeGroupHeight))
        
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { _ in
            return result.groupItems
        })
    }
    
    class func tagShowLayoutHeight(data: [PTTagLayoutModel]?,
                                   screenWidth: CGFloat? = nil,
                                   itemOriginalX: CGFloat? = nil, // 左右边距 (假设对称)
                                   itemHeight: CGFloat = 32,
                                   topContentSpace: CGFloat = 10,
                                   bottomContentSpace: CGFloat = 10,
                                   itemLeadingSpace: CGFloat = 10,
                                   itemTrailingSpace: CGFloat = 10,
                                   itemContentSpace: CGFloat = 20,
                                   maxRows: Int = 0                // 新增：最大行数限制 (0 表示不限制，全部展示)
    ) -> (groupHeight: CGFloat, groupItems: [NSCollectionLayoutGroupCustomItem], rowCount: Int) {
        
        guard let datas = data, !datas.isEmpty else {
            let emptyHeight = PTCollectionLayoutGeometry.finite(topContentSpace) + PTCollectionLayoutGeometry.finite(bottomContentSpace)
            return (max(PTCollectionLayoutGeometry.minimumDimension, emptyHeight), [], 0)
        }

        let viewW = PTCollectionLayoutGeometry.dimension(screenWidth ?? CGFloat.kSCREEN_WIDTH)
        let itemX = max(0, PTCollectionLayoutGeometry.finite(itemOriginalX ?? PTAppBaseConfig.share.defaultViewSpace))
        let safeItemHeight = PTCollectionLayoutGeometry.dimension(itemHeight)
        let topSpace = PTCollectionLayoutGeometry.finite(topContentSpace)
        let bottomSpace = PTCollectionLayoutGeometry.finite(bottomContentSpace)
        let leadingSpace = PTCollectionLayoutGeometry.finite(itemLeadingSpace)
        let trailingSpace = PTCollectionLayoutGeometry.finite(itemTrailingSpace)
        let contentSpace = PTCollectionLayoutGeometry.finite(itemContentSpace)
        var customItems: [NSCollectionLayoutGroupCustomItem] = []
        customItems.reserveCapacity(datas.count)

        var x = itemX
        var y = topSpace
        var rowCount = 1
        let maxRowWidth = max(0.1, viewW - itemX * 2)

        for (index, model) in datas.enumerated() {
            let cacheKey = PTTagLayoutWidthCacheKey(text: model.name,
                                                     fontName: model.contentFont.fontName,
                                                     fontSize: model.contentFont.pointSize,
                                                     fontTraits: model.contentFont.fontDescriptor.symbolicTraits.rawValue,
                                                     itemHeight: safeItemHeight,
                                                     maximumWidth: maxRowWidth,
                                                     itemContentSpace: contentSpace,
                                                     haveImage: model.haveImage,
                                                     imageWidth: PTCollectionLayoutGeometry.finite(model.imageWidth),
                                                     contentSpace: PTCollectionLayoutGeometry.finite(model.contentSpace))
            let currentWidth: CGFloat
            if let cachedWidth = model.cachedWidth,
               cachedWidth > 0,
               model.cachedWidthKey == nil {
                currentWidth = min(cachedWidth, maxRowWidth)
            } else if let cachedWidth = model.cachedWidth,
                      model.cachedWidthKey == cacheKey,
                      cachedWidth > 0 {
                currentWidth = min(cachedWidth, maxRowWidth)
            } else {
                var measuredWidth = UIView.sizeFor(string: model.name,
                                                    font: model.contentFont,
                                                    height: safeItemHeight).width + contentSpace
                if model.haveImage {
                    measuredWidth += PTCollectionLayoutGeometry.dimension(model.imageWidth) + PTCollectionLayoutGeometry.finite(model.contentSpace)
                }
                let calculatedWidth = min(max(0.1, measuredWidth), maxRowWidth)
                model.storeCachedWidth(calculatedWidth, key: cacheKey)
                currentWidth = calculatedWidth
            }

            if x + currentWidth > (viewW - itemX) {
                if maxRows > 0 && rowCount >= maxRows {
                    break
                }

                x = itemX
                y += safeItemHeight + trailingSpace
                rowCount += 1
            }

            let frame = CGRect(x: x, y: y, width: currentWidth, height: safeItemHeight)
            let item = NSCollectionLayoutGroupCustomItem(frame: frame, zIndex: 1000 + index)
            customItems.append(item)
            x += currentWidth + leadingSpace
        }

        let totalHeight = y + safeItemHeight + bottomSpace
        return (totalHeight, customItems, rowCount)
    }

    // MARK: - 横向布局 (Horizontal)
    class func horizontalLayout(data: [AnyObject]?,
                                      itemOriginalX: CGFloat? = nil,
                                      itemWidth: CGFloat = 100,
                                      itemHeight: CGFloat = 44,
                                      topContentSpace: CGFloat = 10,
                                      bottomContentSpace: CGFloat = 10,
                                      itemLeadingSpace: CGFloat = 10) -> NSCollectionLayoutGroup {
        let result = PTCollectionLayoutGeometry.horizontal(itemCount: data?.count ?? 0,
                                                            itemOriginalX: itemOriginalX ?? PTAppBaseConfig.share.defaultViewSpace,
                                                            itemWidth: itemWidth,
                                                            itemHeight: itemHeight,
                                                            topContentSpace: topContentSpace,
                                                            bottomContentSpace: bottomContentSpace,
                                                            itemLeadingSpace: itemLeadingSpace)
        let customers = makeCustomItems(from: result.frames)
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(result.contentWidth),
                                               heightDimension: .absolute(result.contentHeight))
        return NSCollectionLayoutGroup.custom(layoutSize: groupSize) { _ in customers }
    }
    
    class func horizontalLayoutSystem(data: [AnyObject]?,
                                            itemOriginalX: CGFloat? = nil,
                                            itemWidth: CGFloat = 100,
                                            itemHeight: CGFloat = 44,
                                            topContentSpace: CGFloat = 10,
                                            bottomContentSpace: CGFloat = 10,
                                            itemLeadingSpace: CGFloat = 10) -> NSCollectionLayoutGroup {
        let itemX = max(0, PTCollectionLayoutGeometry.finite(itemOriginalX ?? PTAppBaseConfig.share.defaultViewSpace))
        let safeItemWidth = PTCollectionLayoutGeometry.dimension(itemWidth)
        let safeItemHeight = PTCollectionLayoutGeometry.dimension(itemHeight)
        let topSpace = max(0, PTCollectionLayoutGeometry.finite(topContentSpace))
        let bottomSpace = max(0, PTCollectionLayoutGeometry.finite(bottomContentSpace))
        let horizontalSpace = max(0, PTCollectionLayoutGeometry.finite(itemLeadingSpace))
        let itemCount = max(0, data?.count ?? 0)
        let groupWidth = itemCount == 0
            ? max(PTCollectionLayoutGeometry.minimumDimension, itemX)
            : max(PTCollectionLayoutGeometry.minimumDimension,
                  itemX + CGFloat(itemCount) * safeItemWidth + CGFloat(max(0, itemCount - 1)) * horizontalSpace)
        let groupHeight = max(PTCollectionLayoutGeometry.minimumDimension, safeItemHeight + topSpace + bottomSpace)
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(groupWidth),
                                               heightDimension: .absolute(groupHeight))
        guard itemCount > 0 else {
            return NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [])
        }

        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(safeItemWidth),
                                                                              heightDimension: .absolute(safeItemHeight)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       repeatingSubitem: item,
                                                       count: itemCount)
        group.contentInsets = NSDirectionalEdgeInsets(top: topSpace,
                                                       leading: itemX,
                                                       bottom: bottomSpace,
                                                       trailing: 0)
        group.interItemSpacing = .fixed(horizontalSpace)
        return group
    }
    
    // MARK: - 移动 Item 手势
    /// 允许手势移动Item，默认不允许
    func allowsMoveItem() {
        let moveGestureName = "PooTools.UICollectionView.moveItem"
        if gestureRecognizers?.contains(where: { $0.name == moveGestureName }) == true {
            return
        }

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
        longPressGesture.name = moveGestureName
        self.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - 横向分页布局
    class func horizontalPagingLayout(data: [AnyObject]?,
                                            monitorWidth: CGFloat? = nil,
                                            itemOriginalX: CGFloat = 0,
                                            itemHeight: CGFloat = 76,
                                            topContentSpace: CGFloat = 0,
                                            bottomContentSpace: CGFloat = 0,
                                            columnCount: Int = 5,
                                            rowCount: Int = 2,
                                            itemLeadingSpace: CGFloat = 15,
                                            itemTrailingSpace: CGFloat = 10) -> NSCollectionLayoutGroup {
        let result = PTCollectionLayoutGeometry.paging(itemCount: data?.count ?? 0,
                                                       width: monitorWidth ?? CGFloat.kSCREEN_WIDTH,
                                                       itemOriginalX: itemOriginalX,
                                                       itemHeight: itemHeight,
                                                       topContentSpace: topContentSpace,
                                                       bottomContentSpace: bottomContentSpace,
                                                       columnCount: columnCount,
                                                       rowCount: rowCount,
                                                       itemLeadingSpace: itemLeadingSpace,
                                                       itemTrailingSpace: itemTrailingSpace)
        let items = makeCustomItems(from: result.frames)
        let size = NSCollectionLayoutSize(widthDimension: .absolute(result.contentWidth),
                                          heightDimension: .absolute(result.contentHeight))
        return NSCollectionLayoutGroup.custom(layoutSize: size) { _ in items }
    }
    
    func hasVisibleCell<T: UICollectionViewCell>(of type: T.Type) -> Bool {
        visibleCells.contains { $0 is T }
    }

    func visibleCell<T: UICollectionViewCell>(of type: T.Type) -> T? {
        visibleCells.first { $0 is T } as? T
    }
}
