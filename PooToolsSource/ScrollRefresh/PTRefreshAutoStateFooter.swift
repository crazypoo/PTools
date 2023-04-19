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
        self.stateLabel?.isHidden = self.state != .noMoreData
    }
    
    public override func scrollViewContentSizeDidChange(_ change: [AnyHashable : Any]?) {
        super.scrollViewContentSizeDidChange(change)
        
        let contentHeight = self.scrollView!.mj_contentH + self.ignoredScrollViewContentInsetBottom
        let scrollHeight = self.scrollView!.mj_h - self.scrollViewOriginalInset.top - self.scrollViewOriginalInset.bottom + self.ignoredScrollViewContentInsetBottom
        self.mj_y = max(contentHeight,scrollHeight)
    }
}
