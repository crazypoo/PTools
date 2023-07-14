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
    
    private struct AssociatedKeys {
        static var UIRefreshControlBlockKey = 998
    }

    @objc func addRefreshHandlers(handler:@escaping RefreshedBlock) {
        objc_setAssociatedObject(self, &AssociatedKeys.UIRefreshControlBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        addTarget(self, action: #selector(actionRefreshed(sender:)), for: .valueChanged)
    }
    
    @objc func actionRefreshed(sender:UIRefreshControl) {
        let block:RefreshedBlock = objc_getAssociatedObject(self, &AssociatedKeys.UIRefreshControlBlockKey) as! RefreshedBlock
        block(sender)
    }
}
