//
//  PTBaseViewController+Debug.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

//MARK: 导入此模块须要引用camera的权限调用

//MARK: 用來調用測試模式
extension PTBaseViewController {
    //MARK: 這裏提供給Flex使用
    ///這裏提供給Flex使用
    public func showFlexFunction(show:Bool) {
        
    }

    open override func motionEnded(_ motion: UIEvent.EventSubtype, 
                                   with event: UIEvent?) {
        if UIApplication.applicationEnvironment() != .appStore {
            let uidebug:Bool = App_UI_Debug_Bool
            UserDefaults.standard.set(!uidebug, forKey: LocalConsole.ConsoleDebug)
            if uidebug {
                if PTDevFunction.share.mn_PFloatingButton != nil {
                    PTDevFunction.share.lab_btn_release()
                } else {
                    PTDevFunction.GobalDevFunction_close { show in
#if DEBUG
                                self.showFlexFunction(show: showFlex)
#endif
                    }
                }
            } else {
                let vc = PTDebugViewController.init(hideBaseNavBar: false)
                PTUtils.getCurrentVC().navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
