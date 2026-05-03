//
//  UIPageControl+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import UIKit

public typealias PageControlTouchedBlock = (_ sender:UIPageControl) -> Void

public extension UIPageControl {
    @objc func addPageControlHandlers(handler:@escaping PageControlTouchedBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
