//
//  PTRefreshAutoStateFooter.swift
//  KRMovie
//
//  Created by 邓杰豪 on 17/4/23.
//  Copyright © 2023 Zola. All rights reserved.
//

import UIKit
import MJRefresh

public class PTRefreshAutoStateFooter: MJRefreshAutoStateFooter {
    
    public override func prepare() {
        super.prepare()
    }
    
    public override func placeSubviews() {
        super.placeSubviews()
        stateLabel?.isHidden = state != .noMoreData
    }
    
    public override func scrollViewContentSizeDidChange(_ change: [AnyHashable : Any]?) {
        super.scrollViewContentSizeDidChange(change)
        
        let contentHeight = scrollView!.mj_contentH + ignoredScrollViewContentInsetBottom
        let scrollHeight = scrollView!.mj_h - scrollViewOriginalInset.top - scrollViewOriginalInset.bottom + ignoredScrollViewContentInsetBottom
        mj_y = max(contentHeight,scrollHeight)
    }
}
