//
//  PTSideMenuSegue.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

open class PTSideMenuSegue: UIStoryboardSegue {

    /// 路由类型
    public enum ContentType: String {
        /// Side control内的content
        case content = "PTSideMenu.Content"
        /// Side control的场景
        case menu = "PTSideMenu.Menu"
    }

    /// 当前的Content type
    public var contentType = ContentType.content

    /// 执行路由，会将侧菜单对应的视图控制器更改为目标视图控制器。
    /// 这个方法在从storyboard加载时被调用。
    open override func perform() {
        guard let sideMenuController = source as? PTSideMenuControl else {
            return
        }

        switch contentType {
        case .content:
            sideMenuController.contentViewController = destination
        case .menu:
            sideMenuController.menuViewController = destination
        }
    }
}
