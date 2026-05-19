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

public final class PTCoreUserDefultsWrapper: @unchecked Sendable {
    
    public static let shared = PTCoreUserDefultsWrapper()    
    private init() {}

    //MARK: 是否再显示更新框(0继续显示1不再显示)
    ///是否再显示更新框(0继续显示1不再显示)
    @PTUserDefault(withKey: "AppNoMoreShowUpdate", defaultValue: false) public var AppNoMoreShowUpdate:Bool
        
    /**
        测试相关
     */
    //MARK: App的全局URL环境配置设置(1生产2测试3自定义)
    ///App的全局URL环境配置设置(1生产2测试3自定义)
    @PTUserDefault(withKey: "AppServiceIdentifier", defaultValue: nil) public var AppServiceIdentifier:String?
    ///App的全局URL环境配置设置(1生产2测试3自定义)
    @PTUserDefault(withKey: "AppSocketServiceIdentifier", defaultValue: nil) public var AppSocketServiceIdentifier:String?
    //MARK: App的自定义URL环境请求连接
    ///App的自定义SocketURL环境请求连接
    @PTUserDefault(withKey: DevSocketKey, defaultValue: "") public var AppSocketUrl:String
    ///App的自定义URL环境请求连接
    @PTUserDefault(withKey: DevNetWorkKey, defaultValue: "") public var AppRequestUrl:String
    //MARK: App测试环境(YES是)
    ///App测试环境(YES是)
    @PTUserDefault(withKey: ConsoleDebug, defaultValue: false) public var AppDebugMode:Bool
    //MARK: App测试环境图片选项(YES是)
    ///App测试环境图片选项(YES是)
    @PTUserDefault(withKey: "WebImageOption", defaultValue: false) public var WebImageOption:Bool
    //MARK: App测试环境点击泡泡(YES是)
    ///App测试环境点击泡泡(YES是)
    @PTUserDefault(withKey: PTDevMaskTouchBubbleKey, defaultValue: true) public var AppDebbugTouchBubble:Bool
    //MARK: App测试环境标识(YES是)
    ///App测试环境标识(YES是)
    @PTUserDefault(withKey: PTDevMaskKey, defaultValue: true) public var AppDebbugMark:Bool
    //MARK: App测试环境点击信息(YES是)
    ///App测试环境点击信息(YES是)
    @PTUserDefault(withKey: TouchInspectorDebug, defaultValue: true) public var AppTouchInspectShow:Bool
    //MARK: App测试环境点击信息Hits(YES是)
    ///App测试环境点击信息Hits(YES是)
    @PTUserDefault(withKey: TouchInspectorHitsDebug, defaultValue: true) public var AppTouchInspectShowHits:Bool
    
    @PTUserDefault(withKey: "LocalConsoleFontSize", defaultValue: 7.5) public var LocalConsoleCurrentFontSize:CGFloat
    @PTUserDefault(withKey: "LocalConsoleFontColor", defaultValue: "#FFFFFF") public var LocalConsoleCurrentFontColor:String
    /**
        语言
     */
    //MARK: App语言环境(默认中文zh-Hans)
    ///App语言环境(默认中文zh-Hans)
    @PTUserDefault(withKey: "MyAppLanguage", defaultValue: PTDefaultLanguage) public var AppLanguage:String
    
    /**
        测速
     */
    //MARK: App网络测速记录
    ///App网络测速记录
    @PTUserDefault(withKey: "AppNetworkSpeedTestFunctionHistoria", defaultValue: "") public var NetworkSpeedTestFunctionHistoria:String
    
    /**
        权限检测
     */
    //MARK: App权限检测
    ///权限检测
    @PTUserDefault(withKey: "AppFirstPermission", defaultValue: false) public var AppFirstPermissionShowed:Bool
    
    //MARK: PTWhatsNews记录版本
    ///PTWhatsNews记录版本
    @PTUserDefault(withKey: "PTWhatNewsLatestAppVersionPresented", defaultValue: "") public var PTWhatNewsLatestAppVersionPresented:String
    /*
     LocalConsole
     */
    //MARK: LocalConsole
    @PTUserDefault(withKey: "LocalConsole.Width", defaultValue: nil) public var PTLocalConsoleWidth:CGFloat?
    @PTUserDefault(withKey: "LocalConsole.Height", defaultValue: nil) public var PTLocalConsoleHeight:CGFloat?
    @PTUserDefault(withKey: "LocalConsole.X", defaultValue: nil) public var PTLocalConsoleX:CGFloat?
    @PTUserDefault(withKey: "LocalConsole.Y", defaultValue: nil) public var PTLocalConsoleY:CGFloat?
    @PTUserDefault(withKey: "MockLocationLat", defaultValue: 0) public var PTMockLocationLat:CGFloat
    @PTUserDefault(withKey: "MockLocationLng", defaultValue: 0) public var PTMockLocationLng:CGFloat
    @PTUserDefault(withKey: "MockLocationOpen", defaultValue: false) public var PTMockLocationOpen:Bool
    @PTUserDefault(withKey: "LogWriteToTextFile", defaultValue: true) public var PTLogWrite:Bool
}
