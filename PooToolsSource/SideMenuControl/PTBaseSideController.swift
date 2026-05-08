//
//  PTBaseSideController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
open class PTBaseSideController: PTBaseViewController {

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 【修复】依赖父视图的 bounds 而不是物理屏幕宽度
        guard let parentWidth = self.parent?.view.bounds.width else { return }
        
        let menuWidth = PTSideMenuControl.preferences.basic.menuWidth
        let direction = PTSideMenuControl.preferences.basic.direction
        
        switch direction {
        case .left:
            view.frame = CGRect(x: parentWidth - menuWidth, y: 0, width: menuWidth, height: view.bounds.height)
        case .right:
            view.frame = CGRect(x: 0, y: 0, width: menuWidth, height: view.bounds.height)
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
    }
}
