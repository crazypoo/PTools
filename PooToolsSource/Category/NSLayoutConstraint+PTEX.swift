//
//  NSLayoutConstraint+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension NSLayoutConstraint {
    func priority(_ value: CGFloat) -> NSLayoutConstraint {
        self.priority = UILayoutPriority(Float(value))
        return self
    }
}
