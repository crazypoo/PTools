//
//  CGFloat+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

extension CGFloat: PTProtocolCompatible {}
//MARK: 溫度單位
@objc public enum TemperatureUnit:Int {
    ///華氏
    case Fahrenheit
    ///攝氏
    case CentigradeDegree
}

public extension CGFloat {
    //MARK: 獲取屏幕寬度
    ///獲取屏幕寬度
    static let kSCREEN_WIDTH = kSCREEN_SIZE.width
    
    //MARK: 獲取屏幕高度
    ///獲取屏幕高度
    static let kSCREEN_HEIGHT = kSCREEN_SIZE.height
    
    //MARK: 等比例调整
    ///等比例调整
    /// - Returns: CGFloat
    static func ScaleW(w:CGFloat)->CGFloat {
        let width:CGFloat = w * kSCREEN_WIDTH/375
        return width
    }

    //MARK: 獲取導航欄Bar高度
    ///獲取導航欄Bar高度
    static let kNavBarHeight:CGFloat = 44
    
    //MARK: 獲取StatusBar的高度
    ///獲取StatusBar的高度
    /// - Returns: CGFloat
    static func statusBarHeight()->CGFloat {
        let window = UIApplication.shared.windows.first
        let statusBarFrame = window?.windowScene?.statusBarManager?.statusBarFrame
        return statusBarFrame?.height ?? 0
    }
    
    //MARK: 獲取導航欄總高度
    ///獲取導航欄總高度
    static let kNavBarHeight_Total:CGFloat = CGFloat.kNavBarHeight + CGFloat.statusBarHeight()

    //MARK: Tabbar安全高度
    ///Tabbar安全高度
    static let kTabbarSaveAreaHeight:CGFloat = isXModel ? 34 : 0
    //MARK: Tabbar高度
    ///Tabbar高度
    static let kTabbarHeight:CGFloat = 49
    //MARK: Tabbar總高度
    ///Tabbar總高度
    static let kTabbarHeight_Total = CGFloat.kTabbarSaveAreaHeight + CGFloat.kTabbarHeight
    
    //MARK: 华氏摄氏度转普通摄氏度/普通摄氏度转华氏摄氏度
    ///华氏摄氏度转普通摄氏度/普通摄氏度转华氏摄氏度
    static func temperatureUnitExchangeValue(value:CGFloat,changeToType:TemperatureUnit) ->CGFloat {
        switch changeToType {
        case .Fahrenheit:
            let values = 32 + 1.8 * value
            return values
        case .CentigradeDegree:
            let values = (value - 32) / 1.8
            return values
        default:
            return 0
        }
    }
}

public extension PTPOP where Base == CGFloat {
    //MARK: 一个数字四舍五入返回
    ///一个数字四舍五入返回
    /// - Parameters:
    ///   - value: 值
    ///   - scale: 保留小数的位数
    /// - Returns: 四舍五入返回结果
    func rounding(scale: Int16 = 1) -> CGFloat {
        let value = NSDecimalNumberHandler.pt.rounding(value: base,scale: scale)
        return "\(value.floatValue)".cgFloat() ?? 0
    }
}
