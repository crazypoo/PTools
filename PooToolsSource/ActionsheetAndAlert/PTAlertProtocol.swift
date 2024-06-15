//
//  PTAlertProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public protocol PTAlertProtocol where Self: PTAlertController {
    /// 显示
    func showAnimation(completion: (() -> Void)?)
    /// 隐藏
    func dismissAnimation(completion: (() -> Void)?)
}
