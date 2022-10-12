//
//  PTDevFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
#if DEBUG
#if canImport(FLEX)
import FLEX
#endif
#if canImport(InAppViewDebugger)
import InAppViewDebugger
#endif
#endif

public typealias GoToAppDev = () -> Void

@objcMembers
public class PTDevFunction: NSObject {
    public static let share = PTDevFunction()
    
    public var mn_PFloatingButton : PFloatingButton?
    public var goToAppDevVC:GoToAppDev?
    
    public func createLabBtn()
    {
        if UIApplication.applicationEnvironment() != .appStore
        {
            UserDefaults.standard.set(true,forKey: LocalConsole.ConsoleDebug)
            if self.mn_PFloatingButton == nil
            {
                mn_PFloatingButton = PFloatingButton.init(view: AppWindows as Any, frame: CGRect.init(x: 0, y: 200, width: 50, height: 50))
                mn_PFloatingButton?.backgroundColor = .randomColor
                
                let btnLabel = UILabel()
                btnLabel.textColor = .randomColor
                btnLabel.sizeToFit()
                btnLabel.textAlignment = .center
                btnLabel.font = .systemFont(ofSize: 13)
                btnLabel.numberOfLines = 0
                btnLabel.text = "实验室"
                mn_PFloatingButton?.addSubview(btnLabel)
                btnLabel.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                
                mn_PFloatingButton?.longPressBlock = { (sender) in
                    
                    PTUtils.base_alertVC(msg:"调试框架",okBtns: ["取消","全部开启","FLEX","Log","FPS","全部关闭","调试功能界面","检测界面"],showIn: PTUtils.getCurrentVC()) { index, title in
                        if index == 0
                        {

                        }
                        else
                        {
                            if title == "全部开启"
                            {
                                PTDevFunction.GobalDevFunction_open()
                            }
                            else if title == "全部关闭"
                            {
                                PTDevFunction.GobalDevFunction_close()
                            }
                            else if title == "FLEX"
                            {
                                #if DEBUG
                                if FLEXManager.shared.isHidden
                                {
                                    FLEXManager.shared.showExplorer()
                                }
                                else
                                {
                                    FLEXManager.shared.hideExplorer()
                                }
                                #endif
                            }
                            else if title == "Log"
                            {
                                if PTLocalConsoleFunction.share.localconsole.terminal == nil
                                {
                                    PTLocalConsoleFunction.share.localconsole.createSystemLogView()
                                }
                                else
                                {
                                    PTLocalConsoleFunction.share.localconsole.cleanSystemLogView()
                                }
                            }
                            else if title == "FPS"
                            {
                                if PCheckAppStatus.shared.closed
                                {
                                    PCheckAppStatus.shared.open()
                                }
                                else
                                {
                                    PCheckAppStatus.shared.close()
                                }
                            }
                            else if title == "调试功能界面"
                            {
                                if self.goToAppDevVC != nil
                                {
                                    self.goToAppDevVC!()
                                }
                            }
                            else if title == "检测界面"
                            {
#if DEBUG
                                InAppViewDebugger.present()
#endif
                            }
                        }
                    }
                }
            }
        }
    }
    
    public class func GobalDevFunction_open()
    {
        if UIApplication.applicationEnvironment() != .appStore
        {
            #if DEBUG
            FLEXManager.shared.showExplorer()
            #endif
            PTLocalConsoleFunction.share.localconsole.createSystemLogView()
            PCheckAppStatus.shared.open()
        }
    }

    public class func GobalDevFunction_close()
    {
        if UIApplication.shared.inferredEnvironment != .appStore
        {
            #if DEBUG
            FLEXManager.shared.hideExplorer()
            #endif
            PTLocalConsoleFunction.share.localconsole.cleanSystemLogView()
            PCheckAppStatus.shared.close()
        }
    }

    public func lab_btn_release()
    {
        UserDefaults.standard.set(false,forKey: LocalConsole.ConsoleDebug)
        self.mn_PFloatingButton?.removeFromSuperview()
        self.mn_PFloatingButton = nil
    }

}
