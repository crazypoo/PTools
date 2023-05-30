//
//  PTBaseViewController+ListEmptyData.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import LXFProtocolTool

//MARK: 添加emptydataset
extension PTBaseViewController:LXFEmptyDataSetable {
    //MARK: 添加emptydataset
    ///添加emptydataset,设置无数据空页面
    open func showEmptyDataSet(currentScroller:UIScrollView) {
        self.lxf_EmptyDataSet(currentScroller) { () -> [LXFEmptyDataSetAttributeKeyType : Any] in
            [
                .tipStr: "",
                .tipColor: UIColor.black,
                .verticalOffset: 0,
                .tipImage: UIImage()
            ]
        }
    }
    
    open func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        NSAttributedString()
    }
}
