//
//  CommonMacro.swift
//  lamb
//
//  Created by lamb on 2019/1/22.
//  Copyright © 2019 lamb. All rights reserved.
//

import UIKit
import Foundation

// MARK: - 判断是那种设备
/*
 4  4s  320*480
 */
func iPhone4() -> Bool {
    return kScreenHeight == 480.0
}

/*
 5  5s SE  320*568
 */
func iPhone5() -> Bool {
    return kScreenHeight == 568.0
}

/*
 6  6s  7 8  375*667
 */
func iPhone6() -> Bool {
    return kScreenHeight == 667.0
}

/*
 6p  6sp 7p 8p  414*736
 */
func iPhone6plus() -> Bool {
    return kScreenHeight == 736.0
}

/*
 x xs  375*812
*/
func iPhoneX() -> Bool {
    return kScreenHeight == 812.0
}

/*
 xr xsMax 11 11pro 11proMax  414*896
*/
func iPhoneXR() -> Bool {
    return kScreenHeight == 896.0
}


// MARK: - 屏幕、导航栏、Tabbar尺寸
let kScreenBounds = UIScreen.main.bounds

/// 屏幕大小
let kScreenSize                           = kScreenBounds.size
/// 屏幕宽度
let kScreenWidth:CGFloat                  = kScreenSize.width
/// 屏幕高度
let kScreenHeight:CGFloat                 = kScreenSize.height

/// 是否刘海屏
var isFullScreen: Bool {
    if #available(iOS 11, *) {
        guard let w = UIApplication.shared.delegate?.window, let unwrapedWindow = w else {
            return false
        }
        if unwrapedWindow.safeAreaInsets.left > 0 || unwrapedWindow.safeAreaInsets.bottom > 0 {
//            print(unwrapedWindow.safeAreaInsets)
            return true
        }
    }
    return false
}

/// 状态栏默认高度
var kStatusBarHeight: CGFloat {
    return isFullScreen ? 44 : 20
}

/// 获取导航栏高度，刘海屏88，普通屏64。
var kNavigationBarHeight: CGFloat {
    return isFullScreen ? 88 : 64
}

// MARK: - app版本&设备系统版本
let infoDictionary            = Bundle.main.infoDictionary
/* App名称 */
let kAppName: String?         = infoDictionary!["CFBundleDisplayName"] as? String
/* App版本号 */
let kAppVersion: String?      = infoDictionary!["CFBundleShortVersionString"] as? String
/* Appbuild版本号 */
let kAppBuildVersion: String? = infoDictionary!["CFBundleVersion"] as? String
/* app bundleId */
let kAppBundleId: String?     = infoDictionary!["CFBundleIdentifier"] as? String

/* 平台名称（iphonesimulator 、 iphone）*/
let kPlatformName: String?    = infoDictionary!["DTPlatformName"] as? String
/* iOS系统版本 */
let kiOSVersion: String       = UIDevice.current.systemVersion
/* 系统名称+版本，e.g. @"iOS 12.1" */
let kOSType: String           = UIDevice.current.systemName + UIDevice.current.systemVersion


// MARK: - 颜色相关
func kRGBColor(_ R: CGFloat, _ G: CGFloat, _ B: CGFloat) -> UIColor {
    return kRGBAColor(R: R, G: G, B: B, A: 1.0)
}

func kRGBAColor(R: CGFloat, G: CGFloat, B: CGFloat, A: CGFloat) -> UIColor {
    return UIColor.init(red: R/255.0, green: G/255.0, blue: B/255.0, alpha: A)
}

/// 颜色扩展
extension UIColor {
    
    var toHexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(
            format: "%02X%02X%02X",
            Int(r * 0xff),
            Int(g * 0xff),
            Int(b * 0xff)
        )
    }
    
//    convenience init(hex: String) {
//        let scanner = Scanner(string: hex)
//        scanner.scanLocation = 0
//        
//        var rgbValue: UInt64 = 0
//        
//        scanner.scanHexInt64(&rgbValue)
//        
//        let r = (rgbValue & 0xff0000) >> 16
//        let g = (rgbValue & 0xff00) >> 8
//        let b = rgbValue & 0xff
//        
//        self.init(
//            red: CGFloat(r) / 0xff,
//            green: CGFloat(g) / 0xff,
//            blue: CGFloat(b) / 0xff, alpha: 1
//        )
//    }
    
    /// 返回随机颜色
    open class var randomColor:UIColor{
        get
        {
            let red = CGFloat(arc4random()%256)/255.0
            let green = CGFloat(arc4random()%256)/255.0
            let blue = CGFloat(arc4random()%256)/255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }
}

// MARK: - 常用沙盒路径
func kPathHome() -> String {
    return NSHomeDirectory()
}

func kPathTemp() -> String {
    return NSTemporaryDirectory()
}

func kPathDocument() -> String {
    let array = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    return array[0]
}

private func kPathDocumentForFile(_ pathName: String) -> String {
    // 1.获得沙盒的根路径 + 文档的目录路径
    let rootPath = kPathDocument() as NSString
    // 2.获取文本文件路径
    let filePath = rootPath.appendingPathComponent(pathName)
    return filePath
}

// MARK: - ========把数组存入.plist文件 从沙盒中读取文件=========
func kSaveWithFile(pathName: String, forArray arr: NSArray) {
    
    let filePath = kPathDocumentForFile(pathName)
    // 将数据写入文件中
    arr.write(toFile: filePath, atomically: true)
    
}

func kReadWithFile(pathName: String) -> NSArray {
    
    let filePath = kPathDocumentForFile(pathName)
    // 读取文件
    let arr = NSArray(contentsOfFile: filePath) ?? []
    return arr
    
}

// MARK: - UIImage相关
/// 读取Bundle文件中的png图片
///
/// - Parameters:
///   - bundleName: bundle名称，默认是imageBD（imageBD.bundle是保存图片的文件,可以根据项目情况自行修改）
///   - picName: 图片名称
/// - Returns: UIImage对象，没有对应的图片则返回nil
func kImage(from bundleName: String = "imageBD", name picName: String) -> UIImage? {
    let imagepath = Bundle.main.path(forResource: "\(bundleName).bundle/\(picName)", ofType: "png")
    let img = UIImage(contentsOfFile: imagepath ?? "")
    return img
}


// MARK: - String相关
extension String {
    
    /// 判断字符串是否是空白的。
    /// 空格、换行符都会判断为空白
    /// ""  -> true
    /// " "  -> true
    /// "\n"  -> true
    /// "\n "  -> true
    ///
    /// - Returns: true or false
    func isBlank() -> Bool {
        var tmpStr = self
        //去掉空格&换行
        tmpStr = tmpStr.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        return tmpStr.isEmpty
    }
}

// MARK: - 打印日志
func DPrint<T>(_ msg: T, file: String = #file, function: String = #function, lineNum: Int = #line) {
    let url:NSURL = NSURL.fileURL(withPath: file) as NSURL
    #if DEBUG
    print("<<<DEBUG环境>>>\(url.lastPathComponent!)-->[LINE: \(lineNum)]-->\(msg)")
    #elseif Development
    print("<<<开发环境>>>\(url.lastPathComponent!)-->[LINE: \(lineNum)]-->\(msg)")
    #elseif Test
    print("<<<测试环境>>>\(url.lastPathComponent!)-->[LINE: \(lineNum)]-->\(msg)")
    #elseif Distribution
    print("<<<生产环境>>>\(url.lastPathComponent!)-->[LINE: \(lineNum)]-->\(msg)")
    #endif
}

// MARK: - 时间转换处理
/// Date类型转化为日期字符串
///
/// - Parameters:
///   - date: Date类型
///   - dateFormat: 格式化样式默认“yyyy-MM-dd HH:mm:ss”
func dateToString(_ date: Date, dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> String {
    
    let timeZone = NSTimeZone.local
    let formatter = DateFormatter()
    formatter.timeZone = timeZone
    formatter.dateFormat = dateFormat
    let date = formatter.string(from: date)
    return date.components(separatedBy: " ").first!
    
}

/// 日期字符串转化为Date类型
///
/// - Parameters:
///   - str: 日期字符串
///   - dateFormat: 格式化样式，默认为“yyyy-MM-dd HH:mm:ss”
/// - Returns: Date类型
func stringToDate(_ str: String, dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> Date {
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    let date = dateFormatter.date(from: str)
    let localDate = worldTimeToChinaTime(date!)
    return localDate
    
}

/// 比较时间先后
func compareDate(_ startDate: Date, _ endDate: Date) -> Int {
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let startDateString = dateFormatter.string(from: startDate)
    let endDateString = dateFormatter.string(from: endDate)
    let dateA = dateFormatter.date(from: startDateString)
    let dateB = dateFormatter.date(from: endDateString)
    let result : ComparisonResult = (dateA?.compare(dateB!))!
    
    if result == .orderedDescending { // startDate > endDate
        return 1
    } else if result == .orderedAscending { // startDate < endDate
        return 2
    } else {
        return 0
    }
    
}

/// 世界时间转化为中国区时间
func worldTimeToChinaTime(_ date: Date) -> Date {
    
    let timeZone = NSTimeZone.local
    let interval = timeZone.secondsFromGMT(for: date)
    let localDate = date.addingTimeInterval(TimeInterval(interval))
    return localDate
    
}

/// 获取当前的年月日
func getCurrentYearMonthDay() -> String? {
    
    let date = Date()
    let caledar = Calendar.current
    let data = caledar.dateComponents([.year, .month, .day], from: date)
    guard let year = data.year,
        let month = data.month,
        let day = data.day else { return nil }
    let dateStr = "\(year)年\(month)月\(day)日"
    return dateStr
    
}

/**
 *  获取时间差值  截止时间-当前时间
 *  nowDateStr : 当前时间
 *  deadlineStr : 截止时间
 *  @return 时间戳差值
 */
func getDateDifference(withNowDateStr nowDateStr: String?, deadlineStr: String?) -> Int {

    var timeDifference = 0

    let formatter = DateFormatter()
    formatter.dateFormat = "yy-MM-dd HH:mm:ss"
    let nowDate = formatter.date(from: nowDateStr ?? "")
    let deadline = formatter.date(from: deadlineStr ?? "")
    let oldTime = nowDate?.timeIntervalSince1970 ?? 0.0
    let newTime = deadline?.timeIntervalSince1970 ?? 0.0
    timeDifference = Int(newTime - oldTime)

    return timeDifference
}

/// 秒数转化为时间字符串 格式HH:mm:ss
func secondsToTimeString(seconds: Int) -> String {
    // 天数计算
//    let days = (seconds)/(24*3600)
    // 小时计算
    let hours = (seconds)%(24*3600)/3600
    // 分钟计算
    let minutes = (seconds)%3600/60
    // 秒计算
    let second = (seconds)%60
    let timeString = String(format: "%02lu:%02lu:%02lu", hours, minutes, second)
    return timeString
    
}

/// 秒数转化为时间字符串 格式HH:mm:ss(分开获取时分秒)
func secondsToTimeStringPart(seconds: Int) -> (hours: String, mins: String, seconds: String) {
    // 天数计算
//    let days = (seconds)/(24*3600)
    // 小时计算
    let hours = (seconds)%(24*3600)/3600
    // 分钟计算
    let minutes = (seconds)%3600/60
    // 秒计算
    let second = (seconds)%60
    return (String(format: "%02lu", hours), String(format: "%02lu", minutes), String(format: "%02lu", second))
    
}

// MARK: - 打印属性列表
func DPrintIvarList(_ classString: String) {
    
    DPrint("\n\n///////////// \(classString)  IvarList /////////////\n")
    var count : UInt32 = 0
    let list = class_copyIvarList(NSClassFromString(classString), &count)
    for i in 0..<Int(count) {
        let ivar = list![i]
        let name = ivar_getName(ivar)
        let type = ivar_getTypeEncoding(ivar)
        print(String(cString: name!), "<---->", String(cString: type!), "\n")
    }
    
}

func DPrintPropertyList(_ classString: String) {
    
    DPrint("\n\n///////////// \(classString)  PropertyList /////////////\n")
    var count : UInt32 = 0
    let list = class_copyPropertyList(NSClassFromString(classString), &count)
    for i in 0..<Int(count) {
        let property = list![i]
        let name = property_getName(property)
        let type = property_getAttributes(property)
        print(String(cString: name), "<---->", String(cString: type!), "\n")
    }
    
}

// MARK: - 提取字符串中的Float
/// 字符串提取Float
///
/// - Parameters:
///   - str: 带Float的字符串
/// - Returns: Float类型
func getFloatFromString(str: String) -> Float? {
    
    let nonDigits = CharacterSet.decimalDigits.inverted
    let numStr = str.trimmingCharacters(in: nonDigits)
    guard let number = Float(numStr) else { return nil }
    return number
    
}

// MARK: - 提取字符串中的Int
/// 字符串提取Int
///
/// - Parameters:
///   - str: 带Int的字符串
/// - Returns: Int类型
func getIntFromString(str: String) -> Int? {
    
    let nonDigits = CharacterSet.decimalDigits.inverted
    let numStr = str.trimmingCharacters(in: nonDigits)
    guard let number = Int(numStr) else { return nil }
    return number
    
}
