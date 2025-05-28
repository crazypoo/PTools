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
    case Call, SMS, Mail, AppStore, Safari, iBook, FaceTime, Map, Music,
         Battery, Location, Privace, Siri, Sounds, Wallpaper, Display, Keyboard,
         DateAndTime, Accessibilly, About, General, Notification, MobileData,
         Bluetooth, WIFI, Castle, Setting, Unknow
}

@objcMembers
public class PTOpenSystemConfig:NSObject {
    public var types : SystemFunctionType = .Setting
    public var content : String = ""
    public var scheme : String = ""
}

/*
 根據所需跳轉某Setting內的方法
 */
@objcMembers
public class PTOpenSystemFunction: NSObject {
    
    static let setScheme = "PT Open setting".localized()
    static let setPhone = "PT Open setting phone".localized()
    
    private class func showAlert(_ msg:String) {
        UIAlertController.gobal_drop(title: "PT Alert Opps".localized(),subTitle: msg)
    }
    
    private class func validateScheme(_ scheme: String?) -> String? {
        guard let scheme = scheme, !scheme.isEmpty else {
            showAlert(setScheme)
            return nil
        }
        return scheme
    }

    //MARK: 根據所需跳轉某Setting內的方法
    ///根據所需跳轉某Setting內的方法
    /// - Parameters:
    ///   - config: 選項
    public class func openSystemFunction(config:PTOpenSystemConfig) {
        var uriString: String?
        
        switch config.types {
        case .Call:
            guard !config.content.isEmpty, config.content.isPooPhoneNum() else {
                showAlert(setPhone)
                return
            }
            uriString = "tel://\(config.content)"
            
        case .SMS:
            guard !config.content.isEmpty, config.content.isPooPhoneNum() else {
                showAlert(setPhone)
                return
            }
            uriString = "sms://\(config.content)"
            
        case .Mail:
            guard !config.content.isEmpty, config.content.isValidEmail else {
                showAlert("PT Open setting email".localized())
                return
            }
            uriString = "mailto://\(config.content)"
            
        case .AppStore:
            guard !config.content.isEmpty else {
                showAlert("PT Open setting aid".localized())
                return
            }
            uriString = "itms-apps://itunes.apple.com/app/id\(config.content)"
            
        case .Safari:
            guard !config.content.isEmpty, config.content.isURL() else {
                showAlert("PT Open setting url".localized())
                return
            }
            uriString = config.content
            
        case .iBook:        uriString = "itms-books://"
        case .Map:          uriString = "maps://"
        case .Music:        uriString = "music://"
        case .FaceTime:
            guard !config.content.isEmpty, config.content.isPooPhoneNum() else {
                showAlert(setPhone)
                return
            }
            uriString = "facetime://\(config.content)"
            
        case .Battery:      uriString = "\(validateScheme(config.scheme) ?? ""):root=BATTERY_USAGE"
        case .Location:     uriString = "\(validateScheme(config.scheme) ?? ""):root=Privacy&path=LOCATION"
        case .Privace:      uriString = "\(validateScheme(config.scheme) ?? ""):root=Privacy"
        case .Siri:         uriString = "\(validateScheme(config.scheme) ?? ""):root=Siri"
        case .Sounds:       uriString = "\(validateScheme(config.scheme) ?? ""):root=Sounds"
        case .Wallpaper:    uriString = "\(validateScheme(config.scheme) ?? ""):root=Wallpaper"
        case .Display:      uriString = "\(validateScheme(config.scheme) ?? ""):root=General&path=DISPLAY"
        case .Keyboard:     uriString = "\(validateScheme(config.scheme) ?? ""):root=General&path=Keyboard"
        case .DateAndTime:  uriString = "\(validateScheme(config.scheme) ?? ""):root=General&path=DATE_AND_TIME"
        case .Accessibilly: uriString = "\(validateScheme(config.scheme) ?? ""):root=General&path=ACCESSIBILITY"
        case .About:        uriString = "\(validateScheme(config.scheme) ?? ""):root=General&path=About"
        case .General:      uriString = "\(validateScheme(config.scheme) ?? ""):root=General"
        case .Notification: uriString = "\(validateScheme(config.scheme) ?? ""):root=NOTIFICATIONS_ID"
        case .MobileData:   uriString = "\(validateScheme(config.scheme) ?? ""):root=MOBILE_DATA_SETTINGS_ID"
        case .Bluetooth:    uriString = "\(validateScheme(config.scheme) ?? ""):root=Bluetooth"
        case .WIFI:         uriString = "\(validateScheme(config.scheme) ?? ""):root=WIFI"
        case .Castle:       uriString = "\(validateScheme(config.scheme) ?? ""):root=CASTLE"
        case .Setting:      uriString = UIApplication.openSettingsURLString
        case .Unknow:       break
        }
        
        if let uri = uriString, let url = URL(string: uri) {
            PTAppStoreFunction.jumpLink(url: url)
        }
    }
    
    public class func jumpCurrentAppSetting() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        PTAppStoreFunction.jumpLink(url: url)
    }
}
