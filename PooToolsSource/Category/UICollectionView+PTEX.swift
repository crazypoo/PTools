//
//  UICollectionView+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/21.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension UICollectionView
{
    //MARK: 撇除動畫重加載
    ///撇除動畫重加載
    @objc func reloadDataWithOutAnimation(completion:(()->Void)?)
    {
        UIView.performWithoutAnimation {
            self.reloadData {
                if completion != nil
                {
                    completion!()
                }
            }
        }
    }
    
    //MARK: 獲取Cell在Window的位置
    ///獲取Cell在Window的位置
    @objc func cellInWindow(cellFrame:CGRect)->CGRect
    {
        let cellInCollectionViewRect = self.convert(cellFrame, to: self)
        let cellRectInWindow = self.convert(cellInCollectionViewRect, to: AppWindows!)
        return cellRectInWindow
    }
    
    //MARK: 計算CollectionView的Group高度和設置佈局(Gird形式)
    ///計算CollectionView的Group高度和設置佈局(Gird形式)
    /// - Parameters:
    ///   - data: 數據(數組)
    ///   - size: 佈局大小
    ///   - cellRowCount: 每一行多少個數量
    ///   - originalX: 每行第一個起始位置
    ///   - contentTopAndBottom: 起始行的起始高度
    ///   - cellLeadingSpace: 每個item相隔距離
    ///   - cellTrailingSpace: 每一行相隔高度
    ///   - handle: 返回Group高度和[GroupCustomItem]
    @objc class func girdCollectionContentHeight(data:[AnyObject],
                                                 size:CGSize = CGSize.init(width: (CGFloat.kSCREEN_WIDTH - 10 * 2)/3, height: (CGFloat.kSCREEN_WIDTH - 10 * 2)/3),
                                                 cellRowCount:NSInteger = 3,
                                                 originalX:CGFloat = 10,
                                                 contentTopAndBottom:CGFloat = 0,
                                                 cellLeadingSpace:CGFloat = 0,
                                                 cellTrailingSpace:CGFloat = 0,
                                                 handle:((_ groupHeight:CGFloat,_ groupItem:[NSCollectionLayoutGroupCustomItem])->Void))
    {
        var customers = [NSCollectionLayoutGroupCustomItem]()
        var groupH:CGFloat = 0
        let itemH = size.height
        let itemW = size.width
        var x:CGFloat = originalX,y:CGFloat = 0 + contentTopAndBottom
        data.enumerated().forEach { (index,value) in
            if index < cellRowCount
            {
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: x, y: y, width: itemW, height: itemH), zIndex: 1000+index)
                customers.append(customItem)
                x += itemW + cellLeadingSpace
                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom
                }
            }
            else
            {
                x += itemW + cellLeadingSpace
                if index > 0 && (index % cellRowCount == 0)
                {
                    x = originalX
                    y += itemH + cellTrailingSpace
                }

                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom
                }
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: x, y: y, width: itemW, height: itemH), zIndex: 1000+index)
                customers.append(customItem)
            }
        }
        handle(groupH,customers)
    }
    
    //MARK: 設置CollectionView的GirdLayout
    ///設置CollectionView的GirdLayout
    /// - Parameters:
    ///   - data: 數據(數組)
    ///   - groupWidth: gropu的實際展示寬度
    ///   - size: 佈局大小
    ///   - cellRowCount: 每一行多少個數量
    ///   - originalX: 每行第一個起始位置
    ///   - contentTopAndBottom: 起始行的起始高度
    ///   - cellLeadingSpace: 每個item相隔距離
    ///   - cellTrailingSpace: 每一行相隔高度
    ///   - sectionContentInsets: 佈局偏移
    /// - Returns: Gird佈局
    @objc class func girdCollectionLayout(data:[AnyObject],
                                          groupWidth:CGFloat = CGFloat.kSCREEN_WIDTH,
                                          size:CGSize = CGSize.init(width: (CGFloat.kSCREEN_WIDTH - 10 * 2)/3, height: (CGFloat.kSCREEN_WIDTH - 10 * 2)/3),
                                          cellRowCount:NSInteger = 3,
                                          originalX:CGFloat = 10,
                                          contentTopAndBottom:CGFloat = 0,
                                          cellLeadingSpace:CGFloat = 0,
                                          cellTrailingSpace:CGFloat = 0,
                                          sectionContentInsets:NSDirectionalEdgeInsets = NSDirectionalEdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0)) -> NSCollectionLayoutGroup
    {
        var customers = [NSCollectionLayoutGroupCustomItem]()

        let bannerItemSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.fractionalHeight(1))
        let bannerItem = NSCollectionLayoutItem.init(layoutSize: bannerItemSize)
        var bannerGroupSize : NSCollectionLayoutSize
        
        var groupH:CGFloat = 0
        UICollectionView.girdCollectionContentHeight(data: data,size: size,cellRowCount: cellRowCount,originalX: originalX,contentTopAndBottom: contentTopAndBottom,cellLeadingSpace: cellLeadingSpace,cellTrailingSpace: cellTrailingSpace) { groupHeight, groupItem in
            groupH = groupHeight
            customers = groupItem
        }
        
        bannerItem.contentInsets = sectionContentInsets
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupWidth - originalX * 2), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
            customers
        })
    }
}
