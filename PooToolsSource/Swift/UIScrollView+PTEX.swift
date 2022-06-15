//
//  UIScrollView+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import MJRefresh

public extension UIScrollView {
    
    /// 自动判断上拉或下拉结束正在刷新状态
    func bk_endMJRefresh() {
        
        if mj_header != nil {
            if mj_header!.isRefreshing {
                mj_header!.endRefreshing()
            }
        }
        
        if mj_footer != nil {
            if mj_footer!.isRefreshing {
                mj_footer!.endRefreshing()
            }
        }
        
        if mj_trailer != nil
        {
            if mj_trailer!.isRefreshing {
                mj_trailer!.endRefreshing()
            }
        }
    }
}

//MARK: 防止刷新时候屏幕闪一下
public extension UICollectionView
{
    @objc func reloadDataWithOutAnimation()
    {
        UIView.performWithoutAnimation {
            self.reloadData()
        }
    }
}
