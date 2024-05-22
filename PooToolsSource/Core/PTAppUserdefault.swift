//
//  PTAppUserdefault.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public let DevNetWorkKey = "UI_test_url"
public let DevSocketKey = "UI_test_socket_url"
public let PTDevMaskTouchBubbleKey = "PTDevMaskTouchBubbleKey"
public let PTDevMaskKey = "PTDevMaskKey"
public let ConsoleDebug = "UI_debug"
public let TouchInspectorDebug = "TS_debug"
public let TouchInspectorHitsDebug = "TS_Hit_debug"

public struct PTCoreUserDefultsWrapper {

    //MARK: 是否再显示更新框(0继续显示1不再显示)
    ///是否再显示更新框(0继续显示1不再显示)
    @PTUserDefault(withKey: "AppNoMoreShowUpdate", defaultValue: false) public static var AppNoMoreShowUpdate:Bool
        
    /**
        测试相关
     */
    //MARK: App的全局URL环境配置设置(1生产2测试3自定义)
    ///App的全局URL环境配置设置(1生产2测试3自定义)
    @PTUserDefault(withKey: "AppServiceIdentifier", defaultValue: nil) public static var AppServiceIdentifier:String?
    ///App的全局URL环境配置设置(1生产2测试3自定义)
    @PTUserDefault(withKey: "AppSocketServiceIdentifier", defaultValue: nil) public static var AppSocketServiceIdentifier:String?
    //MARK: App的自定义URL环境请求连接
    ///App的自定义SocketURL环境请求连接
    @PTUserDefault(withKey: DevSocketKey, defaultValue: "") public static var AppSocketUrl:String
    ///App的自定义URL环境请求连接
    @PTUserDefault(withKey: DevNetWorkKey, defaultValue: "") public static var AppRequestUrl:String
    //MARK: App测试环境(YES是)
    ///App测试环境(YES是)
    @PTUserDefault(withKey: ConsoleDebug, defaultValue: true) public static var AppDebugMode:Bool
    //MARK: App测试环境图片选项(YES是)
    ///App测试环境图片选项(YES是)
    @PTUserDefault(withKey: "WebImageOption", defaultValue: false) public static var WebImageOption:Bool
    //MARK: App测试环境点击泡泡(YES是)
    ///App测试环境点击泡泡(YES是)
    @PTUserDefault(withKey: PTDevMaskTouchBubbleKey, defaultValue: true) public static var AppDebbugTouchBubble:Bool
    //MARK: App测试环境标识(YES是)
    ///App测试环境标识(YES是)
    @PTUserDefault(withKey: PTDevMaskKey, defaultValue: true) public static var AppDebbugMark:Bool
    //MARK: App测试环境点击信息(YES是)
    ///App测试环境点击信息(YES是)
    @PTUserDefault(withKey: TouchInspectorDebug, defaultValue: true) public static var AppTouchInspectShow:Bool
    //MARK: App测试环境点击信息Hits(YES是)
    ///App测试环境点击信息Hits(YES是)
    @PTUserDefault(withKey: TouchInspectorHitsDebug, defaultValue: true) public static var AppTouchInspectShowHits:Bool
    
    @PTUserDefault(withKey: "LocalConsoleFontSize", defaultValue: 7.5) public static var LocalConsoleCurrentFontSize:CGFloat
    @PTUserDefault(withKey: "LocalConsoleFontColor", defaultValue: "#FFFFFF") public static var LocalConsoleCurrentFontColor:String
    /**
        语言
     */
    //MARK: App语言环境(默认中文zh-Hans)
    ///App语言环境(默认中文zh-Hans)
    @PTUserDefault(withKey: "MyAppLanguage", defaultValue: "zh-Hans") public static var AppLanguage:String
    
    /**
        测速
     */
    //MARK: App网络测速记录
    ///App网络测速记录
    @PTUserDefault(withKey: "AppNetworkSpeedTestFunctionHistoria", defaultValue: "") public static var NetworkSpeedTestFunctionHistoria:String
    
    /**
        权限检测
     */
    //MARK: App权限检测
    ///权限检测
    @PTUserDefault(withKey: "AppFirstPermission", defaultValue: false) public static var AppFirstPermissionShowed:Bool
    
    //MARK: PTWhatsNews记录版本
    ///PTWhatsNews记录版本
    @PTUserDefault(withKey: "PTWhatNewsLatestAppVersionPresented", defaultValue: "") public static var PTWhatNewsLatestAppVersionPresented:String
    /*
     LocalConsole
     */
    //MARK: LocalConsole
    @PTUserDefault(withKey: "LocalConsole.Width", defaultValue: nil) public static var PTLocalConsoleWidth:CGFloat?
    @PTUserDefault(withKey: "LocalConsole.Height", defaultValue: nil) public static var PTLocalConsoleHeight:CGFloat?
    @PTUserDefault(withKey: "LocalConsole.X", defaultValue: nil) public static var PTLocalConsoleX:CGFloat?
    @PTUserDefault(withKey: "LocalConsole.Y", defaultValue: nil) public static var PTLocalConsoleY:CGFloat?
}
