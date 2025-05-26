//
//  UICollectionView+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/21.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension UICollectionView {
    
    /**
        Total count of rows.
     */
    func numberOfItems() -> Int {
        return (0..<numberOfSections).reduce(0) { $0 + numberOfItems(inSection: $1) }
    }

    func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        return indexPath.section >= 0 &&
               indexPath.item >= 0 &&
               indexPath.section < numberOfSections &&
               indexPath.item < numberOfItems(inSection: indexPath.section)
    }
    
    //MARK: 重载Layout
    ///重载Layout
    func invalidateLayout(animated: Bool) {
        if animated {
            performBatchUpdates({
                self.collectionViewLayout.invalidateLayout()
            }, completion: nil)
        } else {
            collectionViewLayout.invalidateLayout()
        }
    }
    
    //MARK: 撇除動畫重加載
    ///撇除動畫重加載
    @objc func reloadDataWithOutAnimation(completion:PTActionTask?) {
        UIView.performWithoutAnimation {
            self.reloadData {
                completion?()
            }
        }
    }
    
    //MARK: 獲取Cell在Window的位置
    ///獲取Cell在Window的位置
    @objc func cellInWindow(cellFrame:CGRect)->CGRect {
        let cellInCollectionViewRect = self.convert(cellFrame, to: self)
        let cellRectInWindow = self.convert(cellInCollectionViewRect, to: AppWindows!)
        return cellRectInWindow
    }
    
    //MARK: 計算CollectionView的Group高度和設置佈局(Gird形式)
    ///計算CollectionView的Group高度和設置佈局(Gird形式)
    /// - Parameters:
    ///   - data: 數據(數組)
    ///   - groupW:
    ///   - itemHeight:
    ///   - cellRowCount: 每一行多少個數量
    ///   - originalX: 每行第一個起始位置
    ///   - contentTopAndBottom: 起始行的起始高度
    ///   - cellLeadingSpace: 每個item相隔距離
    ///   - cellTrailingSpace: 每一行相隔高度
    ///   - handle: 返回Group高度和[GroupCustomItem]
    ///   - itemHeight:
    ///   - groupW:
    ///   - groupW:
    @objc class func girdCollectionContentHeight(data:[AnyObject]?,
                                                 groupW:CGFloat = CGFloat.kSCREEN_WIDTH,
                                                 itemHeight:CGFloat,
                                                 cellRowCount:NSInteger = 3,
                                                 originalX:CGFloat = 10,
                                                 topContentSpace:CGFloat = 0,
                                                 bottomContentSpace:CGFloat = 0,
                                                 cellLeadingSpace:CGFloat = 0,
                                                 cellTrailingSpace:CGFloat = 0,
                                                 handle: (_ groupHeight:CGFloat, _ groupItem:[NSCollectionLayoutGroupCustomItem])->Void) {
        let result =  UICollectionView.girdCollectionContentHeight(data: data,groupW: groupW,itemHeight: itemHeight,cellRowCount: cellRowCount,originalX: originalX,topContentSpace: topContentSpace,bottomContentSpace: bottomContentSpace,cellLeadingSpace: cellLeadingSpace,cellTrailingSpace: cellTrailingSpace)
        handle(result.0,result.1)
    }
    
    class func girdCollectionContentHeight(data:[AnyObject]?,
                                           groupW:CGFloat = CGFloat.kSCREEN_WIDTH,
                                           itemHeight:CGFloat,
                                           cellRowCount:NSInteger = 3,
                                           originalX:CGFloat = 10,
                                           topContentSpace:CGFloat = 0,
                                           bottomContentSpace:CGFloat = 0,
                                           cellLeadingSpace:CGFloat = 0,
                                           cellTrailingSpace:CGFloat = 0) -> (CGFloat,[NSCollectionLayoutGroupCustomItem]) {
        var customers = [NSCollectionLayoutGroupCustomItem]()
        var groupH:CGFloat = 0
        let itemH = itemHeight
        let itemW = (groupW - originalX * 2 - CGFloat(cellRowCount - 1) * cellLeadingSpace) / CGFloat(cellRowCount)
        var x:CGFloat = originalX,y:CGFloat = 0 + topContentSpace
        data?.enumerated().forEach { (index,value) in
            if index < cellRowCount {
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: x, y: y, width: itemW, height: itemH), zIndex: 1000+index)
                customers.append(customItem)
                x += itemW + cellLeadingSpace
                if index == (data!.count - 1) {
                    groupH = y + itemH + bottomContentSpace
                }
            } else {
                x += itemW + cellLeadingSpace
                if index > 0 && (index % cellRowCount == 0) {
                    x = originalX
                    y += itemH + cellTrailingSpace
                }

                if index == (data!.count - 1) {
                    groupH = y + itemH + bottomContentSpace
                }
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: x, y: y, width: itemW, height: itemH), zIndex: 1000+index)
                customers.append(customItem)
            }
        }
        return (groupH,customers)
    }
    
    //MARK: 設置CollectionView的GirdLayout
    ///設置CollectionView的GirdLayout
    /// - Parameters:
    ///   - data: 數據(數組)
    ///   - groupWidth: group的實際展示寬度
    ///   - itemHeight:
    ///   - cellRowCount: 每一行多少個數量
    ///   - originalX: 每行第一個起始位置
    ///   - contentTopAndBottom: 起始行的起始高度
    ///   - cellLeadingSpace: 每個item相隔距離
    ///   - cellTrailingSpace: 每一行相隔高度
    ///   - sectionContentInsets: 佈局偏移
    ///   - itemHeight:
    ///   - itemHeight:
    /// - Returns: Gird佈局
    @objc class func girdCollectionLayout(data:[AnyObject]?,
                                          groupWidth:CGFloat = CGFloat.kSCREEN_WIDTH,
                                          itemHeight:CGFloat,
                                          cellRowCount:NSInteger = 3,
                                          originalX:CGFloat = 10,
                                          topContentSpace:CGFloat = 0,
                                          bottomContentSpace:CGFloat = 0,
                                          cellLeadingSpace:CGFloat = 0,
                                          cellTrailingSpace:CGFloat = 0,
                                          sectionContentInsets:NSDirectionalEdgeInsets = NSDirectionalEdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0)) -> NSCollectionLayoutGroup {
        var customers = [NSCollectionLayoutGroupCustomItem]()

        let bannerItemSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.fractionalHeight(1))
        let bannerItem = NSCollectionLayoutItem.init(layoutSize: bannerItemSize)
        var bannerGroupSize : NSCollectionLayoutSize
        
        var groupH:CGFloat = 0
        UICollectionView.girdCollectionContentHeight(data: data,groupW: groupWidth,itemHeight: itemHeight,cellRowCount: cellRowCount,originalX: originalX,topContentSpace: topContentSpace,bottomContentSpace:bottomContentSpace,cellLeadingSpace: cellLeadingSpace,cellTrailingSpace: cellTrailingSpace) { groupHeight, groupItem in
            groupH = groupHeight
            customers = groupItem
        }
        
        bannerItem.contentInsets = sectionContentInsets
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupWidth - originalX * 2), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
            customers
        })
    }
    
    //MARK: 設置CollectionView的WaterFallLayout
    ///設置CollectionView的WaterFallLayout
    /// - Parameters:
    ///   - data: 數據(數組)
    ///   - screenWidth: group的實際展示寬度
    ///   - rowCount: 每一行多少個數量
    ///   - itemOriginalX: item的初始x坐标
    ///   - itemOriginalY: item的初始y坐标
    ///   - itemSpace: item间隔距离
    ///   - itemWidth: item的width
    ///   - itemHeight: 根据回调的index和model来使外部传入对应每个item的height
    /// - Returns: 瀑布流佈局
    @objc class func waterFallLayout(data:[AnyObject]?,
                                     screenWidth:CGFloat = CGFloat.kSCREEN_WIDTH,
                                     rowCount:Int = 2,
                                     itemOriginalX:CGFloat = PTAppBaseConfig.share.defaultViewSpace,
                                     topContentSpace:CGFloat = 0,
                                     bottomContentSpace:CGFloat = 0,
                                     itemSpace:CGFloat,
                                     itemTrailingSpace:CGFloat = 0,
                                     itemHeight:(Int,AnyObject)->CGFloat) -> NSCollectionLayoutGroup {
        var bannerGroupSize : NSCollectionLayoutSize
        var customers = [NSCollectionLayoutGroupCustomItem]()
        var groupH:CGFloat = 0
        let itemRightSapce:CGFloat = itemSpace
        let screenW:CGFloat = screenWidth

        let cellWidth = (screenWidth - itemOriginalX * 2 - CGFloat(rowCount - 1) * itemSpace) / CGFloat(rowCount)
        let originalX = itemOriginalX
        var x:CGFloat = originalX,y:CGFloat = 0 + topContentSpace
        data?.enumerated().forEach { index, model in
            let itemH = itemHeight(index, model)
            var itemX = x
            var itemY = y

            if index < rowCount {
                // 第一行：只需排好横向位置
                x += cellWidth + itemRightSapce
            } else {
                // 多行：参考前一行同列 item 的位置计算 y
                let previousIndex = index - rowCount
                let previousItem = customers[previousIndex]
                itemY = previousItem.frame.maxY + itemTrailingSpace

                // 判断是否是换行第一个元素
                if index % rowCount == 0 {
                    x = originalX
                    itemX = x
                }
                x += cellWidth + itemRightSapce
            }

            // 添加当前 item
            let customItem = NSCollectionLayoutGroupCustomItem(
                frame: CGRect(x: itemX, y: itemY, width: cellWidth, height: itemH),
                zIndex: 1000 + index
            )
            customers.append(customItem)

            // 判断 groupH 最后一项时更新
            if index == data!.count - 1 {
                let lastHeight = itemY + itemH + bottomContentSpace
                let fallbackHeight = customers.last?.frame.maxY ?? 0 + bottomContentSpace
                groupH = max(lastHeight, fallbackHeight)
            }
        }
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenW), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
            customers
        })
    }
    
    //MARK: 設置CollectionView的TagShowLayout
    ///設置CollectionView的TagShowLayout
    /// - Parameters:
    ///   - data: 數據(數組)
    ///   - screenWidth: group的實際展示寬度
    ///   - itemOriginalX: item的初始x坐标
    ///   - itemHeight: item的height
    ///   - contentTopAndBottom: item的初始y坐标
    ///   - itemLeadingSpace: item左右间隔距离
    ///   - itemTrailingSpace: item上下间隔距离
    ///   - itemFont: item的字体大小
    ///   - itemContentSpace: item的内容左右间距总和
    /// - Returns: TagLayout
    @objc class func tagShowLayout(data:[PTTagLayoutModel]?,
                                   screenWidth:CGFloat = CGFloat.kSCREEN_WIDTH,
                                   itemOriginalX:CGFloat = PTAppBaseConfig.share.defaultViewSpace,
                                   itemHeight:CGFloat = 32,
                                   topContentSpace:CGFloat = 10,
                                   bottomContentSpace:CGFloat = 10,
                                   itemLeadingSpace:CGFloat = 10,
                                   itemTrailingSpace:CGFloat = 10,
                                   itemContentSpace:CGFloat = 20) -> NSCollectionLayoutGroup {
        var bannerGroupSize : NSCollectionLayoutSize
        var customers = [NSCollectionLayoutGroupCustomItem]()
                
        let result = UICollectionView.tagShowLayoutHeight(data: data,screenWidth: screenWidth,itemOriginalX: itemOriginalX,itemHeight: itemHeight,topContentSpace: topContentSpace,bottomContentSpace:bottomContentSpace,itemLeadingSpace: itemLeadingSpace,itemTrailingSpace: itemTrailingSpace,itemContentSpace: itemContentSpace)

        let groupH = result.groupHeight
        customers = result.groupItems
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenWidth), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
            customers
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
        var x = itemOriginalX
        var y: CGFloat = topContentSpace
        var columnCount = 1

        let maxRowWidth = screenWidth - itemOriginalX * 2

        func calculateCellWidth(for model: PTTagLayoutModel) -> CGFloat {
            var width = UIView.sizeFor(string: model.name, font: model.contentFont, height: itemHeight).width + itemContentSpace
            if model.haveImage {
                width += model.imageWidth + model.contentSpace
            }
            return min(width, maxRowWidth)
        }

        for (index, model) in datas.enumerated() {
            let currentWidth = calculateCellWidth(for: model)

            // 如果当前内容宽度超出最大行宽，就换行
            if x + currentWidth > maxRowWidth {
                x = itemOriginalX
                y += itemHeight + itemTrailingSpace
                columnCount += 1
            }

            let frame = CGRect(x: x, y: y, width: currentWidth, height: itemHeight)
            let item = NSCollectionLayoutGroupCustomItem(frame: frame, zIndex: 1000 + index)
            customItems.append(item)

            x += currentWidth + itemLeadingSpace
        }

        let totalHeight = y + itemHeight + bottomContentSpace

        return (totalHeight, customItems, columnCount)
    }
    
    //MARK: 設置CollectionView的Horizontallayout
    ///設置CollectionView的Horizontallayout
    /// - Parameters:
    ///   - data: 數據(數組)
    ///   - itemOriginalX: item的初始x坐标
    ///   - itemWidth: item的width
    ///   - itemHeight: item的height
    ///   - contentTopAndBottom: item的初始y坐标
    ///   - itemLeadingSpace: item左右间隔距离
    /// - Returns: Horizontallayout
    @objc class func horizontalLayout(data:[AnyObject]?,
                                      itemOriginalX:CGFloat = PTAppBaseConfig.share.defaultViewSpace,
                                      itemWidth:CGFloat = 100,
                                      itemHeight:CGFloat = 44,
                                      topContentSpace:CGFloat = 10,
                                      bottomContentSpace:CGFloat = 10,
                                      itemLeadingSpace:CGFloat = 10) -> NSCollectionLayoutGroup {
        var groupWidth:CGFloat = itemOriginalX
        var bannerGroupSize : NSCollectionLayoutSize
        var customers = [NSCollectionLayoutGroupCustomItem]()
        data?.enumerated().forEach { (index,model) in
            let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: groupWidth, y: topContentSpace, width: itemWidth, height: itemHeight), zIndex: 1000+index)
            customers.append(customItem)
            groupWidth += (itemWidth + itemLeadingSpace)
        }
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupWidth), heightDimension: NSCollectionLayoutDimension.absolute((itemHeight + topContentSpace + bottomContentSpace)))
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
            customers
        })
    }
    
    @objc class func horizontalLayoutSystem(data:[AnyObject]?,
                                      itemOriginalX:CGFloat = PTAppBaseConfig.share.defaultViewSpace,
                                      itemWidth:CGFloat = 100,
                                      itemHeight:CGFloat = 44,
                                      topContentSpace:CGFloat = 10,
                                      bottomContentSpace:CGFloat = 10,
                                      itemLeadingSpace:CGFloat = 10) -> NSCollectionLayoutGroup {
        var groupWidth:CGFloat = itemOriginalX
        var bannerGroupSize : NSCollectionLayoutSize
        var customers = [NSCollectionLayoutItem]()
        data?.enumerated().forEach { (index,model) in
            let customItem = NSCollectionLayoutItem.init(layoutSize: NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.absolute(itemWidth), heightDimension: NSCollectionLayoutDimension.absolute(itemHeight)))
            
            customItem.edgeSpacing = NSCollectionLayoutEdgeSpacing.init(leading: NSCollectionLayoutSpacing.fixed(index == 0 ? itemOriginalX : itemLeadingSpace), top: NSCollectionLayoutSpacing.fixed(topContentSpace), trailing: NSCollectionLayoutSpacing.fixed(0), bottom: NSCollectionLayoutSpacing.fixed(bottomContentSpace))
            customers.append(customItem)
            groupWidth += (itemWidth + itemLeadingSpace)
        }
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupWidth), heightDimension: NSCollectionLayoutDimension.absolute((itemHeight + topContentSpace + bottomContentSpace)))
        return NSCollectionLayoutGroup.horizontal(layoutSize: bannerGroupSize, subitems: customers)
    }
    
    // MARK: 移动 item
    /// 允许手势移动Item，默认不允许
    func allowsMoveItem() {
        // 长点击事件，做移动cell操作
        let longPressGesture = UILongPressGestureRecognizer { sender in
            let gesture = sender as! UILongPressGestureRecognizer
            switch(gesture.state) {
            // 开始移动
            case UIGestureRecognizer.State.began:
                let point = gesture.location(in: gesture.view!)
                if let selectedIndexPath = self.indexPathForItem(at: point) {
                    // 开始移动
                    self.beginInteractiveMovementForItem(at: selectedIndexPath)
                }
            case UIGestureRecognizer.State.changed:
                // 移动中
                let point = gesture.location(in: gesture.view!)
                self.updateInteractiveMovementTargetPosition(point)
            case UIGestureRecognizer.State.ended:
                // 结束移动
                self.endInteractiveMovement()
            default:
                // 取消移动
                self.cancelInteractiveMovement()
            }
        }
        self.addGestureRecognizer(longPressGesture)
    }
    
    @objc class func horizontalPagingLayout(data:[AnyObject]?,
                                            monitorWidth:CGFloat = CGFloat.kSCREEN_WIDTH,
                                            itemOriginalX:CGFloat = 0,
                                            itemHeight:CGFloat = 76,
                                            topContentSpace:CGFloat = 0,
                                            bottomContentSpace:CGFloat = 0,
                                            columnCount:Int = 5,
                                            rowCount:Int = 2,
                                            itemLeadingSpace:CGFloat = 15,
                                            itemTrailingSpace:CGFloat = 10) -> NSCollectionLayoutGroup {
        guard let data = data, !data.isEmpty else {
            return NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .absolute(0), heightDimension: .absolute(0)), subitems: [])
        }

        let itemsPerPage = columnCount * rowCount
        let totalPages = Int(ceil(Double(data.count) / Double(itemsPerPage)))
        let itemWidth = (monitorWidth - itemOriginalX * 2 - CGFloat(columnCount - 1) * itemLeadingSpace) / CGFloat(columnCount)
        
        var customers = [NSCollectionLayoutGroupCustomItem]()
        var groupHeight: CGFloat = 0

        for (index, _) in data.enumerated() {
            let pageIndex = index / itemsPerPage
            let rowIndex = (index % itemsPerPage) / columnCount
            let columnIndex = index % columnCount

            let x = CGFloat(pageIndex) * monitorWidth + itemOriginalX + CGFloat(columnIndex) * (itemWidth + itemLeadingSpace)
            let y = topContentSpace + CGFloat(rowIndex) * (itemHeight + itemTrailingSpace)

            groupHeight = max(groupHeight, y + itemHeight + bottomContentSpace)

            let item = NSCollectionLayoutGroupCustomItem(
                frame: CGRect(x: x, y: y, width: itemWidth, height: itemHeight),
                zIndex: 1000 + index
            )
            customers.append(item)
        }

        let layoutSize = NSCollectionLayoutSize(
            widthDimension: .absolute(monitorWidth * CGFloat(totalPages)),
            heightDimension: .absolute(groupHeight)
        )

        return NSCollectionLayoutGroup.custom(layoutSize: layoutSize) { _ in
            customers
        }
    }
}
