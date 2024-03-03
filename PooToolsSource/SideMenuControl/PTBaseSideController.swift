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
        let sideMenuBasicConfiguration = PTSideMenuControl.preferences.basic
        switch sideMenuBasicConfiguration.direction {
        case .left:
            view.frame = CGRectMake(CGFloat.kSCREEN_WIDTH - PTSideMenuControl.preferences.basic.menuWidth, 0, PTSideMenuControl.preferences.basic.menuWidth, view.bounds.height)
        case .right:
            view.frame = CGRectMake(0, 0, PTSideMenuControl.preferences.basic.menuWidth, view.bounds.height)
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
