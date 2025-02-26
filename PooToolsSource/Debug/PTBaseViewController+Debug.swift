//
//  PTBaseViewController+Debug.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

//MARK: 导入此模块须要引用camera的权限调用

//MARK: 用來調用測試模式
public extension PTBaseViewController {
    //MARK: 這裏提供給Flex使用
    ///這裏提供給Flex使用
    func showFlexFunction(show:Bool) {
        
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
#if POOTOOLS_DEBUG
        Task {
            let environment = UIApplication.shared.inferredEnvironment
            if environment != .appStore,PTCoreUserDefultsWrapper.AppDebugMode {
                let console = LocalConsole.shared
                console.isVisiable = !console.isVisiable
            }
        }
#endif
    }
}
