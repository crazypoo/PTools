//
//  UIRefreshControl+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
public typealias RefreshedBlock = (_ sender:UIRefreshControl) -> Void

public extension UIRefreshControl {
    static var UIRefreshControlBlockKey = "UIRefreshControlBlockKey"
    
    @objc func addRefreshHandlers(handler:@escaping RefreshedBlock) {
        objc_setAssociatedObject(self, &UIRefreshControl.UIRefreshControlBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        self.addTarget(self, action: #selector(self.actionRefreshed(sender:)), for: .valueChanged)
    }
    
    @objc func actionRefreshed(sender:UIRefreshControl) {
        let block:RefreshedBlock = objc_getAssociatedObject(self, &UIRefreshControl.UIRefreshControlBlockKey) as! RefreshedBlock
        block(sender)
    }
}
