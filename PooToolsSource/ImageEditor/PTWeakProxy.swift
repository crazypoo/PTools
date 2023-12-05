//
//  PTWeakProxy.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

class PTWeakProxy: NSObject {
    private weak var target: NSObjectProtocol?
    
    init(target: NSObjectProtocol) {
        self.target = target
        super.init()
    }
    
    class func proxy(withTarget target: NSObjectProtocol) -> PTWeakProxy {
        PTWeakProxy(target: target)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        target
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        target?.responds(to: aSelector) ?? false
    }
}

