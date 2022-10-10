//
//  PTOpenSystemFunction.swift
//  PooTools_Example
//
//  Created by jax on 2021/11/5.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit
import Foundation

@objc public enum SystemFunctionType : Int {
    case Call
    case SMS
    case Mail
    case AppStore
    case Safari
    case iBook
    case FaceTime
    case Map
    case Music
    case Battery
    case Location
    case Privace
    case Siri
    case Sounds
    case Wallpaper
    case Display
    case Keyboard
    case DateAndTime
    case Accessibilly
    case About
    case General
    case Notification
    case MobileData
    case Bluetooth
    case WIFI
    case Castle
    case Setting
    case Unknow
}

@objcMembers
public class PTOpenSystemConfig:NSObject
{
    public var types : SystemFunctionType = SystemFunctionType(rawValue: 27)!
    public var content : String = ""
    public var scheme : String = ""
}

@objcMembers
public class PTOpenSystemFunction: NSObject {
    private class func functionAlert(msg:String)
    {
        PTUtils.base_alertVC(title: "提示", msg: msg, cancelBtn: "好的", showIn: PTUtils.getCurrentVC()) {
            
        } moreBtn: { index, title in
            
        }

    }
    
    public class func openSystemFunction(config:PTOpenSystemConfig)
    {
        var uriString : String? = ""
        switch config.types {
        case .Call:
            if config.content.stringIsEmpty() || !config.content.isPooPhoneNum()
            {
                PTOpenSystemFunction.functionAlert(msg: "请填写电话号码")
                return
            }
            else
            {
                uriString = String(format: "tel://%@",config.content)
            }
        case .SMS:
            if config.content.stringIsEmpty() || config.content.isPooPhoneNum()
            {
                PTOpenSystemFunction.functionAlert(msg: "请填写电话号码")
                return
            }
            else
            {
                uriString = String(format: "sms://%@",config.content)
            }
        case .Mail:
            if config.content.stringIsEmpty() || config.content.isValidEmail
            {
                PTOpenSystemFunction.functionAlert(msg: "请填写邮箱")
                return
            }
            else
            {
                uriString = String(format: "mailto://%@",config.content)
            }
        case .AppStore:
            if config.content.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请填写AppID")
                return
            }
            else
            {
                uriString = String(format: "itms-apps://itunes.apple.com/app/id%@",config.content)
            }
        case .Safari:
            if config.content.stringIsEmpty() || config.content.isURL()
            {
                PTOpenSystemFunction.functionAlert(msg: "请填写网址")
                return
            }
            else
            {
                uriString = String(format: "%@",config.content)
            }
        case .iBook:
            uriString = "itms-books://"
        case .FaceTime:
            if config.content.stringIsEmpty() || config.content.isPooPhoneNum()
            {
                PTOpenSystemFunction.functionAlert(msg: "请填写电话号码")
                return
            }
            else
            {
                uriString = String(format: "facetime://%@",config.content)
            }
        case .Map:
            uriString = "maps://"
        case .Music:
            uriString = "music://"
        case .Battery:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=BATTERY_USAGE",config.scheme)
            }
        case .Location:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=Privacy&path=LOCATION",config.scheme)
            }
        case .Privace:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=Privacy",config.scheme)
            }
        case .Siri:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=Siri",config.scheme)
            }
        case .Sounds:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=Sounds",config.scheme)
            }
        case .Wallpaper:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=Wallpaper",config.scheme)
            }
        case .Display:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=General&path=DISPLAY",config.scheme)
            }
        case .Keyboard:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=General&path=Keyboard",config.scheme)
            }
        case .DateAndTime:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=General&path=DATE_AND_TIME",config.scheme)
            }
        case .Accessibilly:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=General&path=ACCESSIBILITY",config.scheme)
            }
        case .About:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=General&path=About",config.scheme)
            }
        case .General:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=General",config.scheme)
            }
        case .Notification:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=NOTIFICATIONS_ID",config.scheme)
            }
        case .MobileData:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=MOBILE_DATA_SETTINGS_ID",config.scheme)
            }
        case .Bluetooth:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=Bluetooth",config.scheme)
            }
        case .WIFI:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=WIFI",config.scheme)
            }
        case .Castle:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@:root=CASTLE",config.scheme)
            }
        case .Setting:
            if config.scheme.stringIsEmpty()
            {
                PTOpenSystemFunction.functionAlert(msg: "请在Xcode设置Scheme")
                return
            }
            else
            {
                uriString = String(format: "%@",UIApplication.openSettingsURLString)
            }
        default:
            break
        }
        if uriString!.stringIsEmpty()
        {
            
        }
        else
        {
            UIApplication.shared.open(URL(string: uriString)!, options: [:], completionHandler: nil)

        }
    }
}
