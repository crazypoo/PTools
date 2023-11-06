//
//  PTDevFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import Kingfisher

public typealias FlexDevTask = (Bool) -> Void

fileprivate extension String {
    static let openAll = "全部开启"
    static let closeAll = "全部关闭"
    static let closeTouches = "关闭检测界面点击特效"
    static let openTouches = "开启检测界面点击特效"
    static let closeTouchesHits = "关闭界面点击检测"
    static let openTouchesHits = "开启界面点击检测"
    static let flex = "FLEX"
    static let log = "LOG"
    static let fps = "FPS"
    static let memory = "Memory"
    static let colorCheck = "颜色检查"
    static let ruler = "卡尺"
    static let debugController = "调试功能界面"
    static let inAppViewsCheck = "界面图层展示"
    static let hyperioniOS = "HyperioniOS"
    static let devMask = "DEVMask"
    static let devMaskEvent = "DevMaskEvent"
    static let userDefults = "UserDefults"
    static let appDocument = "App文件夹"
    static let netPit = "网络拦截"
}

@objcMembers
public class PTDevFunction: NSObject {
    public static let share = PTDevFunction()
    
    public var mn_PFloatingButton : PFloatingButton?
    //去開發人員設置界面
    public var goToAppDevVC:PTActionTask?
    //開啟/關閉Flex
    /*
     #if DEBUG
     if FLEXManager.shared.isHidden {
         FLEXManager.shared.showExplorer()
     } else {
         FLEXManager.shared.hideExplorer()
     }
     #endif
     */
    public var flex:PTActionTask?
    public var flexBool:FlexDevTask?
    public var HyperioniOS:PTActionTask?
    public var TestHitShow:FlexDevTask?
    public var TestHitTouchesShow:FlexDevTask?
    public var FoxNet:PTActionTask?
    //開啟/關閉inAppViewDebugger
    /*
     #if DEBUG
        InAppViewDebugger.present()
     #endif
     */
    public var inApp:PTActionTask?
    
    //MARK: 测试模式下检查界面的点击展示事件
    ///测试模式下检查界面的点击展示事件
    public private(set) var touchesType: Bool = App_TouchInspect_Debug_Bool {
        didSet {
            App_TouchInspect_Debug_Bool = self.touchesType
        }
    }

    //MARK: 测试模式下检查界面的点击展示事件开关
    ///测试模式下检查界面的点击展示事件开关
    public private(set) var touchesTestHit: Bool = App_TouchInspect_Hits_Debug_Bool {
        didSet {
            App_TouchInspect_Hits_Debug_Bool = self.touchesTestHit
        }
    }
    
    private var maskView:PTDevMaskView?
    private var isAllOpen:Bool = false
    
    public func createLabBtn() {
        if UIApplication.applicationEnvironment() != .appStore {
            App_UI_Debug_Bool = true
            
            if PTDevMaskShowValue {
                if maskView == nil {
                    PTDevMaskShowValue = true
                    let maskConfig = PTDevMaskConfig()
                    
                    self.maskView = PTDevMaskView(config: maskConfig)
                    self.maskView?.frame = AppWindows!.frame
                    AppWindows?.addSubview(self.maskView!)
                }
            }
            
            if mn_PFloatingButton == nil {
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
                    var allOpenString = ""
                    if self.isAllOpen {
                        allOpenString = .closeAll
                    } else {
                        allOpenString = .openAll
                    }
                    
                    var touchTypeInfo = ""
                    if self.touchesType {
                        touchTypeInfo = .closeTouches
                    } else {
                        touchTypeInfo = .openTouches
                    }
                    
                    var showTouchHit = ""
                    if self.touchesTestHit {
                        showTouchHit = .closeTouchesHits
                    } else {
                        showTouchHit = .openTouchesHits
                    }
                    
                    let titles = [.flex,.log,.fps,.memory,.colorCheck,.ruler,allOpenString,.debugController,.inAppViewsCheck,.hyperioniOS,.devMask,.devMaskEvent,showTouchHit,touchTypeInfo,.userDefults,.appDocument,.netPit]

                    UIAlertController.base_alertVC(msg: "调试框架",okBtns: titles,cancelBtn: "取消") {
                        
                    } moreBtn: { index, title in
                        if title == .openAll {
                            self.isAllOpen = true
                            PTDevFunction.GobalDevFunction_open { show in
                                if self.flexBool != nil {
                                    self.flexBool!(show)
                                }
                                
                                if self.inApp != nil {
                                    self.inApp!()
                                }

                                if self.HyperioniOS != nil {
                                    self.HyperioniOS!()
                                }

                                if self.TestHitShow != nil {
                                    self.TestHitShow!(show)
                                }

                                if self.TestHitTouchesShow != nil {
                                    self.TestHitTouchesShow!(show)
                                }
                            }
                        } else if title == .closeAll {
                            self.isAllOpen = false
                            PTDevFunction.GobalDevFunction_close { show in
                                if self.flexBool != nil {
                                    self.flexBool!(show)
                                }
                                
                                if self.inApp != nil {
                                    self.inApp!()
                                }

                                if self.HyperioniOS != nil {
                                    self.HyperioniOS!()
                                }

                                if self.TestHitShow != nil {
                                    self.TestHitShow!(show)
                                }

                                if self.TestHitTouchesShow != nil {
                                    self.TestHitTouchesShow!(show)
                                }
                            }
                        } else if title == .closeTouchesHits {
                            self.touchesTestHit = false
                            if self.TestHitShow != nil {
                                self.TestHitShow!(self.touchesTestHit)
                            }
                        } else if title == .openTouchesHits {
                            self.touchesTestHit = true
                            if self.TestHitShow != nil {
                                self.TestHitShow!(self.touchesTestHit)
                            }
                        } else if title == .closeTouches {
                            self.touchesType = false
                            if self.TestHitTouchesShow != nil {
                                self.TestHitTouchesShow!(self.touchesType)
                            }
                        } else if title == .openTouches {
                            self.touchesType = true
                            if self.TestHitTouchesShow != nil {
                                self.TestHitTouchesShow!(self.touchesType)
                            }
                        } else if title == .flex {
                            if self.flex != nil {
                                self.flex!()
                            }
                        } else if title == .log {
                            if PTLocalConsoleFunction.share.localconsole.terminal == nil {
                                PTLocalConsoleFunction.share.localconsole.createSystemLogView()
                            } else {
                                PTLocalConsoleFunction.share.localconsole.cleanSystemLogView()
                            }
                        } else if title == .fps {
                            if PCheckAppStatus.shared.closed {
                                PCheckAppStatus.shared.open()
                            } else {
                                PCheckAppStatus.shared.close()
                            }
                        } else if title == .debugController {
                            if self.goToAppDevVC != nil {
                                self.goToAppDevVC!()
                            }
                        } else if title == .inAppViewsCheck {
                            if self.inApp != nil {
                                self.inApp!()
                            }
                        } else if title == .hyperioniOS {
                            if self.HyperioniOS != nil {
                                self.HyperioniOS!()
                            }
                        } else if title == .devMask {
                            if self.maskView != nil {
                                PTDevMaskShowValue = false
                                self.maskView?.removeFromSuperview()
                                self.maskView = nil
                            } else {
                                PTDevMaskShowValue = true
                                
                                let maskConfig = PTDevMaskConfig()
                                
                                self.maskView = PTDevMaskView(config: maskConfig)
                                self.maskView?.frame = AppWindows!.frame
                                AppWindows?.addSubview(self.maskView!)
                            }
                        } else if title == .devMaskEvent {
                            PTDevMaskTouchBubbleShowValue = !PTDevMaskTouchBubbleShowValue
                            if self.maskView != nil {
                                self.maskView!.showTouch = PTDevMaskTouchBubbleShowValue
                            }
                        } else if title == .memory {
                            if PTMemory.share.closed {
                                PTMemory.share.startMonitoring()
                            } else {
                                PTMemory.share.stopMonitoring()
                            }
                        } else if title == .colorCheck {
                            if PTColorPickPlugin.share.showed {
                                PTColorPickPlugin.share.close()
                            } else {
                                PTColorPickPlugin.share.show()
                            }
                        } else if title == .ruler {
                            if PTViewRulerPlugin.share.showed {
                                PTViewRulerPlugin.share.hide()
                            } else {
                                PTViewRulerPlugin.share.show()
                            }
                        } else if title == .userDefults {
                            let currentVC = PTUtils.getCurrentVC()
                            let vc = PTUserDefultsViewController()
                            let nav = PTBaseNavControl(rootViewController: vc)
                            nav.modalPresentationStyle = .fullScreen
                            currentVC.present(nav, animated: true)
                        } else if title == .appDocument {
                            let currentVC = PTUtils.getCurrentVC()
                            let vc = PTFileBrowserViewController()
                            let nav = PTBaseNavControl(rootViewController: vc)
                            nav.modalPresentationStyle = .fullScreen
                            currentVC.present(nav, animated: true)
                        } else if title == .netPit {
                            if self.FoxNet != nil {
                                self.FoxNet!()
                            }
                        }
                    }
                }
            }
        }
    }
    
    public class func GobalDevFunction_open(flexTask:(Bool)->Void) {
        if UIApplication.applicationEnvironment() != .appStore {
            flexTask(true)
            PTLocalConsoleFunction.share.localconsole.createSystemLogView()
            PCheckAppStatus.shared.open()
            
            let devShare = PTDevFunction.share
            devShare.touchesTestHit = true
            devShare.touchesType = true
            if devShare.maskView == nil {
                PTDevMaskShowValue = true
                let maskConfig = PTDevMaskConfig()
                
                devShare.maskView = PTDevMaskView(config: maskConfig)
                devShare.maskView?.frame = AppWindows!.frame
                AppWindows?.addSubview(devShare.maskView!)
            }
        }
    }

    public class func GobalDevFunction_close(flexTask:(Bool)->Void) {
        if UIApplication.shared.inferredEnvironment != .appStore {
            flexTask(false)
            PTLocalConsoleFunction.share.localconsole.cleanSystemLogView()
            PCheckAppStatus.shared.close()
            
            let devShare = PTDevFunction.share
            devShare.touchesTestHit = false
            devShare.touchesType = false
            if devShare.maskView != nil {
                PTDevMaskShowValue = false
                devShare.maskView?.removeFromSuperview()
                devShare.maskView = nil
            }
        }
    }

    public func lab_btn_release() {
        App_UI_Debug_Bool = false
        mn_PFloatingButton?.removeFromSuperview()
        mn_PFloatingButton = nil
    }

    //MARK: SDWebImage的加载失误图片方式(全局控制)
    ///SDWebImage的加载失误图片方式(全局控制)
    public class func gobalWebImageLoadOption()->KingfisherOptionsInfo {
        #if DEBUG
        let userDefaults = UserDefaults.standard.value(forKey: "sdwebimage_option")
        let devServer:Bool = userDefaults == nil ? true : (userDefaults as! Bool)
        if devServer {
            return [KingfisherOptionsInfoItem.cacheOriginalImage]
        } else {
            return [.lowDataModeSource,.memoryCacheExpiration(.seconds(60)).diskCacheExpiration(.seconds(20))]
        }
        #else
        return [KingfisherOptionsInfoItem.cacheOriginalImage]
        #endif
    }
}
