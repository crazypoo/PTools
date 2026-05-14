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
    
    @objc func addRefreshHandlers(handler:@escaping RefreshedBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
