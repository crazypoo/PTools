//
//  NSString+RegularsEX.swift
//  Diou
//
//  Created by jax on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

import CommonCrypto
import SwifterSwift
import AVFoundation
import Foundation
import SwiftDate

/** 数字类型*/
let NUM = 1
/** 小写字母*/
let SMALL_LETTER = 2
/** 大写字母*/
let CAPITAL_LETTER = 3
/** 其他字符*/
let OTHER_CHAR = 4

let commonUsers = ["password", "abc123", "iloveyou", "adobe123", "123123", "sunshine", "1314520", "a1b2c3", "123qwe", "aaa111", "qweasd", "admin", "passwd"]

public enum PStrengthLevel {
    case Easy
    case Midium
    case Strong
    case Very_Strong
    case Extremely_Strong
}

public enum UTF8StringType:Int {
    case UTF8StringTypeOC
    case UTF8StringTypeC
}

public extension String
{
    static let URLCHECKSTRING = "(https|http|ftp|rtsp|igmp|file|rtspt|rtspu)://((((25[0-5]|2[0-4]\\d|1?\\d?\\d)\\.){3}(25[0-5]|2[0-4]\\d|1?\\d?\\d))|([0-9a-z_!~*'()-]*\\.?))([0-9a-z][0-9a-z-]{0,61})?[0-9a-z]\\.([a-z]{2,6})(:[0-9]{1,4})?([a-zA-Z/?_=]*)\\.\\w{1,5}"
    static let IpAddress = "^(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|[1-9])\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)$"
    static let URLSTRING = "[a-zA-z]+://.*"
    static let COLTDCode = "^([0-9A-HJ-NPQRTUWXY]{2}\\d{6}[0-9A-HJ-NPQRTUWXY]{10}|[1-9]\\d{14})$"
    static let POOPHONE = "^1[3|4|5|6|7|8|9][0-9]\\d{8}$"
    static let HomePhone = "^\\d{3}-?\\d{8}|\\d{4}-?\\d{8}$"
    static let ISNUMBER = "^[0-9]*$"
    static let AMOUT1 = "^[0][0-9]+$"
    static let AMOUT2 = "^(([1-9]{1}[0-9]*|[0])" + "\\." + "?[0-9]{0,2})$"
    static let CHINESE = "(^[\\u4e00-\\u9fa5]+$)"
    /*
     第一位是字母，后面都是数字
     P:P开头的是因公普通护照
     D:外交护照是D开头
     E: 有电子芯片的普通护照为“E”字开头，
     S: 后接8位阿拉伯数字公务护照
     G:因私护照G开头
     14：
     15：
     H:香港特区护照和香港公民所持回乡卡H开头,后接10位数字
     M:澳门特区护照和澳门公民所持回乡卡M开头,后接10位数字
     */
    static let PASSPORT = "^1[45][0-9]{7}|([P|p|S|s]\\d{7})|([S|s|G|g]\\d{8})|([Gg|Tt|Ss|Ll|Qq|Dd|Aa|Ff]\\d{8})|([H|h|M|m]\\d{8，10})$"
    static let MAIL = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}?$"
    static let LETTERFIRSTALPHABET = "^[A-Za-z]+$"
    static let ALPHABETLOWERCASED = "^[a-z]+$"
    static let ALPHABETUPPERCASED = "^[A-Za-z0-9]+$"
    static let CNCARLICENSE = "^[\\u4e00-\\u9fa5]{1}[a-zA-Z]{1}[a-zA-Z_0-9]{4}[a-zA-Z_0-9_\\u4e00-\\u9fa5]$"
    static let NUMBERANDWORD = "^[0-9_a-zA-Z]*$"
        
    //MARK: 判斷字符串是否帶有數字和字母
    ///判斷字符串是否帶有數字和字母
    func isNumberAndWord()->Bool
    {
        return self.checkWithString(expression: String.NUMBERANDWORD)
    }

    //MARK: 判斷字符串是否中國大陸車牌
    ///判斷字符串是否中國大陸車牌
    func isCnCarLicense()->Bool
    {
        return self.checkWithString(expression: String.CNCARLICENSE)
    }
    
    //MARK: 判斷字符串是否純字母
    ///判斷字符串是否純字母
    /// - Parameters:
    ///   - isLower: 是否大小寫
    func isAlphabet(isLower:Bool)->Bool
    {
        if isLower
        {
            return self.checkWithString(expression: String.ALPHABETLOWERCASED)
        }
        else
        {
            return self.checkWithString(expression: String.ALPHABETUPPERCASED)
        }
    }
    
    //MARK: 判斷字符串是否第一個為字母
    ///判斷字符串是否第一個為字母
    func isLetterFirstAlphabet()->Bool
    {
        return self.checkWithString(expression: String.LETTERFIRSTALPHABET)
    }
    
    //MARK: 判斷字符串是否郵箱
    ///判斷字符串是否郵箱
    func isMail()->Bool
    {
        return self.checkWithString(expression: String.MAIL)
    }
    
    //MARK: 判斷字符串是否中文
    ///判斷字符串是否中文
    func isChinese()->Bool
    {
        return self.checkWithString(expression: String.CHINESE)
    }
    
    //MARK: 判斷字符串是否護照號碼
    ///判斷字符串是否護照號碼
    func isPassportNumber()->Bool
    {
        return self.checkWithString(expression: String.PASSPORT)
    }
    
    //MARK: 判斷字符串是否URL
    ///判斷字符串是否URL
    func checkURL()->Bool
    {
        var newString : String = self
        if newString.countOfChars() < 1
        {
            return false
        }
        
        if ((self as NSString).length > 4) && ((self as NSString).substring(to: 4) == "www.")
        {
            newString = "http://" + newString
        }
        return newString.checkWithString(expression: String.URLCHECKSTRING)
    }
    
    //MARK: 判斷字符串是否數字
    ///判斷字符串是否數字
    func isNumberString()->Bool
    {
        return self.checkWithString(expression:String.ISNUMBER)
    }
    
    //MARK: 判斷字符串是否中國家庭電話
    ///判斷字符串是否中國家庭電話
    func isHomePhone()->Bool
    {
        return self.checkWithString(expression:String.HomePhone)
    }

    //MARK: 判斷字符串是否中國手機號碼
    ///判斷字符串是否中國手機號碼
    func isPooPhoneNum()->Bool
    {
        return self.checkWithString(expression:String.POOPHONE)
    }

    //MARK: 判斷字符串是否中國工商號碼
    ///判斷字符串是否中國工商號碼
    func isCOLTDCode()->Bool
    {
        return self.checkWithString(expression: String.COLTDCode)
    }
    
    //MARK: 判斷字符串是否URL
    ///判斷字符串是否URL
    func isURL()->Bool
    {
        return self.checkWithString(expression: String.URLSTRING)
    }
    
    //MARK: 判斷字符串是否IP地址
    ///判斷字符串是否IP地址
    func isIP()->Bool
    {
        return self.checkWithString(expression: String.IpAddress)
    }
    
    //MARK: 判斷字符串是否金額
    ///判斷字符串是否金額
    func isMoneyString()->Bool
    {
        return !self.checkWithString(expression: String.AMOUT1) && self.checkWithString(expression: String.AMOUT2) ? true : false
    }
    
    //MARK: 判斷字符串是否中文姓名
    ///判斷字符串是否中文姓名
    func isAChineseName()->Bool
    {
        if (self).stringIsEmpty()
        {
            return false
        }
        
        let range1 = (self as NSString).range(of: "·")
        let range2 = (self as NSString).range(of: "•")
        
        if range1.location != NSNotFound || range2.location != NSNotFound
        {
            if self.charactersArray.count < 2 || self.charactersArray.count > 15
            {
                return false
            }
            
            do {
                let regex = try NSRegularExpression.init(pattern: "^[\u{4e00}-\u{9fa5}]+[·•][\u{4e00}-\u{9fa5}]+$", options: NSRegularExpression.Options.caseInsensitive)
                let match = regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange.init(location: 0, length: self.charactersArray.count))
                let count = match?.numberOfRanges
                return count == 1
            } catch  {
                return false
            }
        }
        else
        {
            if self.charactersArray.count < 2 || self.charactersArray.count > 8
            {
                return false
            }

            do {
                let regex = try NSRegularExpression.init(pattern: "^[\u{4e00}-\u{9fa5}]+$", options: NSRegularExpression.Options.caseInsensitive)
                let match = regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange.init(location: 0, length: self.charactersArray.count))
                let count = match?.numberOfRanges
                return count == 1
            } catch  {
                return false
            }
        }
    }
        
    //MARK: 正則表達式基類
    ///正則表達式基類
    /// - Parameters:
    ///   - expression: 正則表達式
    func checkWithString(expression:String)->Bool
    {
        let regextest = NSPredicate.init(format: "SELF MATCHES %@", expression)
        return regextest.evaluate(with: self)
    }

    //MARK: 正則表達式基類(數組)
    ///正則表達式基類(數組)
    /// - Parameters:
    ///   - expression: 正則表達式(數組)
    func checkWithArray(expression:NSArray)->Bool
    {
        var res = false
        for value in expression
        {
            let regextest = NSPredicate.init(format: "SELF MATCHES %@", value as! String)
            res = regextest.evaluate(with: self)
            if !res
            {
                return false
            }
        }
        return true
    }

    //MARK: base64 解碼
    /// base64 解碼
    var base64Decoded: String? {
        let remainder = count % 4
        
        var padding = ""
        if remainder > 0 {
            padding = String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: self + padding,
                              options: .ignoreUnknownCharacters) else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
            
    @available(iOS, introduced: 2.0, deprecated: 13.0, message: "這是因為MD5算法已被證明是不安全的，不應在安全上下文中使用,所以在iOS13之後用sha256算法比較合適")
    var md5:String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes:UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress,CC_LONG(data.count),&hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0)}.joined()
    }
    
    /*
     sha256加密
     */
    private func hexStringFormatData(input:NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x",UInt8(byte))
        }
        return hexString
    }
    
    private func digest(input:NSData) -> NSData {
        let digestLength = Int(CC_SHA224_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    //MARK: sha256加密
    ///sha256加密
    var sha256:String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFormatData(input: digest(input: stringData as NSData))
        }
        return ""
    }
    
    //MARK: 是否包含emoji
    /// 是否包含emoji
   var isContainEmoji: Bool {
        for scalar in unicodeScalars {
            return self.containEmoji(scalar)
        }
        return false
    }
    
    //MARK: 是否包含表情
    /// 是否包含表情
    /// - Parameter scalar: unicode 字符
    /// - Returns: 是表情返回true
    func containEmoji(_ scalar: Unicode.Scalar) -> Bool {
        switch Int(scalar.value) {
        case 0x1F600...0x1F64F: return true     // Emoticons
        case 0x1F300...0x1F5FF: return true  // Misc Symbols and Pictographs
        case 0x1F680...0x1F6FF: return true  // Transport and Map
        case 0x1F1E6...0x1F1FF: return true  // Regional country flags
        case 0x2600...0x26FF: return true    // Misc symbols
        case 0x2700...0x27BF: return true    // Dingbats
        case 0xE0020...0xE007F: return true  // Tags
        case 0xFE00...0xFE0F: return true    // Variation Selectors
        case 0x1F900...0x1F9FF: return true  // Supplemental Symbols and Pictographs
        case 127000...127600: return true    // Various asian characters
        case 65024...65039: return true      // Variation selector
        case 9100...9300: return true        // Misc items
        case 8400...8447: return true        //
        default: return false
        }
    }
    
    //MARK: 移除表情
    /// 移除表情
    func removeEmoji() -> String {
        var scalars = self.unicodeScalars
        scalars.removeAll(where: containEmoji(_:))
        return String(scalars)
    }
    
    //MARK: 计算字符个数（英文 = 1，数字 = 1，汉语 = 2）
    /// 计算字符个数（英文 = 1，数字 = 1，汉语 = 2）
    /// - Returns: 返回字符的个数
    func countOfChars() -> Int {
        var count = 0
        guard self.count > 0 else { return 0}
        
        for i in 0...self.count - 1 {
            let c: unichar = (self as NSString).character(at: i)
            if (c >= 0x4E00) {
                count += 2
            }else {
                count += 1
            }
        }
        return count
    }
    
    //MARK: 根据字符个数返回从指定位置向后截取的字符串（英文 = 1，数字 = 1，汉语 = 2）
    /// 根据字符个数返回从指定位置向后截取的字符串（英文 = 1，数字 = 1，汉语 = 2）
    func sub(from index: Int) -> String {
        if self.count == 0 {
            return ""
        }
        
        var number = 0
        var strings: [String] = []
        for c in self {
            let subStr: String = "\(c)"
            let num = subStr.countOfChars()
            number += num
            if number <= index {
                strings.append(subStr)
            } else {
                break
            }
        }
        var resultStr: String = ""
        for str in strings {
            resultStr = resultStr + "\(str)"
        }
        return resultStr
    }
    
    //MARK: 中文轉換成拼音字母
    ///中文轉換成拼音字母
    func chineseTransToMandarinAlphabet()->String
    {
        let pinyin:NSMutableString = self.nsString.mutableCopy() as! NSMutableString
        CFStringTransform((pinyin as CFMutableString), nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform((pinyin as CFMutableString), nil, kCFStringTransformStripCombiningMarks, false)
        var newString:NSString = pinyin as NSString
        newString = newString.replacingOccurrences(of: " ", with: "") as NSString
        return newString.uppercased
    }
    
    //MARK: 暂时仅限英文换其他
    ///暂时仅限英文换其他
    func toOtherLanguage(otherLanguage:StringTransform)->String
    {
        return self.stringIsEmpty() ? "" : self.applyingTransform(otherLanguage, reverse: false)!
    }
    
    //MARK: 時間與當前時間的對比狀態
    ///時間與當前時間的對比狀態
    func timeContrastStatus(timeInterval:TimeInterval)->String
    {
        let dateFormatter = "yyyy-MM-dd HH:mm:ss"
        let timeString = timeInterval.toTimeString(dateFormat: dateFormatter)
                
        let regions = Region(calendar: Calendars.republicOfChina,zone: Zones.asiaMacau,locale: Locales.chineseChina)
        var timeInterval = timeString.toDate(dateFormatter,region: regions)!.date.timeIntervalSinceNow
        timeInterval = -timeInterval
        var result = ""
        if timeInterval < 60
        {
            result = "刚刚"
        }
        else if (timeInterval/60) < 60
        {
            result = "\((timeInterval/60))分钟前"
        }
        else if (timeInterval/3600) > 1 && (timeInterval/3600) < 24
        {
            result = "\((timeInterval/3600))小时前"
        }
        else if (timeInterval/3600) > 24 && (timeInterval/3600) < 48
        {
            result = "昨天"
        }
        else if (timeInterval/3600) > 48 && (timeInterval/3600) < 72
        {
            result = "前天"
        }
        else
        {
            result = timeString
        }
        return result
    }
    
    //MARK: JSON字符串轉換成真正的JSON字符串
    ///JSON字符串轉換成真正的JSON字符串
    func jsonToTrueJsonString()->String
    {
        var validString:NSString = self.nsString.replacingOccurrences(of: "(\\w+)\\s*:([^A-Za-z0-9_])", with: "\"$1\":$2",options: NSString.CompareOptions.regularExpression,range: NSRange(location: 0, length: self.nsString.length)) as NSString
        validString = validString.replacingOccurrences(of: "([:\\[,\\{])'", with: "$1\"",options: NSString.CompareOptions.regularExpression, range: NSRange(location: 0, length: validString.length)) as NSString
        validString = validString.replacingOccurrences(of: "'([:\\],\\}])", with: "\"$1",options: NSString.CompareOptions.regularExpression, range: NSRange(location: 0, length: validString.length)) as NSString
        validString = validString.replacingOccurrences(of: "([:\\[,\\{])(\\w+)\\s*:", with: "$1\"$2\":",options: NSString.CompareOptions.regularExpression, range: NSRange(location: 0, length: validString.length)) as NSString
        return validString as String
    }
    
    //MARK: 字符串轉換成UTF8字符串
    ///字符串轉換成UTF8字符串
    func stringToUTF8String(type:UTF8StringType)->NSString
    {
        switch type {
        case .UTF8StringTypeOC:
            return NSString.init(cString: self.nsString.utf8String!, encoding: NSUnicodeStringEncoding)!
        case .UTF8StringTypeC:
            return self.nsString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet(charactersIn: "`#%^{}\"[]|\\<> ").inverted)! as NSString
        }
    }
    
    //MARK: 根據字符串轉換成二維碼圖片
    ///根據字符串轉換成二維碼圖片
    func createQRImage(size:CGFloat)->UIImage
    {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setDefaults()
        let data = self.nsString.data(using: String.Encoding.utf8.rawValue)
        filter?.setValue(data, forKey: "inputMessage")
        let image = filter?.outputImage
        return PTUtils.createNoneInterpolatedUIImage(image: image!, imageSize: size)
    }
}

fileprivate extension PTUtils
{
    //MARK: 創建一個圖片
    ///創建一個圖片
    class func createNoneInterpolatedUIImage(image:CIImage,imageSize:CGFloat)->UIImage
    {
        let extent = CGRectIntegral(image.extent)
        let scale = min(imageSize / extent.width, imageSize / extent.height)
        
        let width = extent.width * scale
        let height = extent.height * scale
        let cs = CGColorSpaceCreateDeviceGray()
        let bitmapRef:CGContext = CGContext(data: nil , width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        let context = CIContext.init()
        let bitmapImage = context.createCGImage(image, from: extent)
        bitmapRef.interpolationQuality = .none
        bitmapRef.scaleBy(x: scale, y: scale)
        bitmapRef.draw(bitmapImage!, in: extent)
        
        let scaledImage = bitmapRef.makeImage()
        let newImage = UIImage(cgImage: scaledImage!)
        return newImage
    }
}


// MARK: - Initializers
public extension String {
    /// 初始化 base64
    init?(base64: String) {
        guard let decodedData = Data(base64Encoded: base64) else { return nil }
        guard let str = String(data: decodedData, encoding: .utf8) else { return nil }
        self.init(str)
    }
}

public extension String {
    /// 初始化 base64
    func toModel<T>(_ type: T.Type) -> T? where T: Decodable {
       return self.data(using: .utf8)?.toModel(type)
    }
}

public extension String
{    
    static func currencySymbol()->String
    {
        let locale:NSLocale = NSLocale.current as NSLocale
        let currency = locale.object(forKey: NSLocale.Key.currencySymbol)
        return currency as! String
    }

    /**
    * 金额的格式转化
    * str : 金额的字符串
    * numberStyle : 金额转换的格式
    * return  NSString : 转化后的金额格式字符串

    * 94863
    * NSNumberFormatterNoStyle = kCFNumberFormatterNoStyle,
    
    * 94,862.57
    * NSNumberFormatterDecimalStyle = kCFNumberFormatterDecimalStyle,
    
    * ￥94,862.57
    * NSNumberFormatterCurrencyStyle = kCFNumberFormatterCurrencyStyle,
    
    * 9,486,257%
    * NSNumberFormatterPercentStyle = kCFNumberFormatterPercentStyle,
    
    * 9.486257E4
    * NSNumberFormatterScientificStyle = kCFNumberFormatterScientificStyle,
    
    * 九万四千八百六十二点五七
    * NSNumberFormatterSpellOutStyle = kCFNumberFormatterSpellOutStyle
    
    **/
    //MARK: 金融字符串相关
    ///金融字符串相关
    func financeDataString(numberStyle:NumberFormatter.Style)->String
    {
        var str = self
        if self.stringIsEmpty()
        {
            str = "0"
        }
        
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = numberStyle
        let money = formatter.string(from: NSNumber(value: str.double() ?? 0.00))
        return money!
    }
    
    //MARK: 判斷字符串是否為空
    ///判斷字符串是否為空
    func stringIsEmpty()->Bool
    {
        return (self as NSString).length == 0 || (self.charactersArray.count < 1) ? true : false
    }
    
    //MARK: 轉換成數字字符串
    ///轉換成數字字符串
    /// - Parameters:
    ///   - decimal: 是否帶小數點
    func numberStringFormatter(decimal:Bool)->String
    {
        let numberFormat = NumberFormatter()
        numberFormat.numberStyle = .decimal
        var outputValue = ""
        if decimal
        {
            outputValue = numberFormat.string(from: NSDecimalNumber.init(string: self))!
        }
        else
        {
            outputValue = numberFormat.string(from: NSNumber.init(value: self.int!))!
        }
        return outputValue
    }
    
    //MARK: 轉換成金額
    ///轉換成金額
    func toMoney()->String
    {
        return String(format: "%.2f", self.float() ?? 0.00)
    }
    
    func toSecurityPhone()->String
    {
        if !(self).stringIsEmpty() && self.charactersArray.count > 10 && self.isPooPhoneNum()
        {
            return (self as NSString).replacingCharacters(in: NSRange.init(location: 3, length: 4), with: "****")
        }
        return self
    }
    
    //MARK: 字符串转Dic
    ///字符串转Dic
    func jsonStringToDic()->NSDictionary?
    {
        if self.isEmpty
        {
            return nil
        }
        
        let jsonData = self.data(using: Encoding.utf8)
        do {
            let dic = try JSONSerialization.jsonObject(with: jsonData!, options: JSONSerialization.ReadingOptions.mutableContainers)
            return (dic as! NSDictionary)
        } catch  {
            return nil
        }
    }
    
    // MARK: JSON 字符串 -> Array
    /// JSON 字符串 ->  Array
    /// - Returns: Array
    func jsonStringToArray() -> Array<Any>? {
        let jsonString = self
        let jsonData:Data = jsonString.data(using: .utf8)!
        let array = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        if array != nil {
            return (array as! Array<Any>)
        }
        return nil
    }
        
    func jsonStringToArray()->NSArray
    {
        do {
            let tmp = try JSONSerialization.jsonObject(with: self.data(using: String.Encoding.utf8)!, options: [JSONSerialization.ReadingOptions.mutableLeaves,JSONSerialization.ReadingOptions.mutableContainers])
            if tmp is NSArray
            {
                return (tmp as! NSArray)
            }
            else if (tmp is NSString) || (tmp is NSDictionary)
            {
                return NSArray.init(array: [tmp])
            }
        } catch {
            return NSArray.init()
        }
        return NSArray.init()
    }
    
    //MARK: 判斷密碼的強度
    ///判斷密碼的強度
    func passwordLevel()->PStrengthLevel
    {
        let level = self.checkPasswordStrength()
        if level > 0 && level < 4
        {
            return .Easy
        }
        else if level > 3 && level < 7
        {
            return .Midium
        }
        else if level > 7 && level < 10
        {
            return .Strong
        }
        else if level > 10 && level < 13
        {
            return .Very_Strong
        }
        else
        {
            return .Extremely_Strong
        }
    }
    
    //MARK: 检查字符的类型，包括数字、大写字母、小写字母等字符。
    ///检查字符的类型，包括数字、大写字母、小写字母等字符。
    /// - Parameters:
    ///   - string: 字符串
    private func checkCharacterType(string:String)->Int
    {
        let asciiCode = (string as NSString).character(at: 0)
        if asciiCode >= 48 && asciiCode <= 57
        {
            return NUM
        }
        else if asciiCode >= 65 && asciiCode <= 90
        {
            return CAPITAL_LETTER
        }
        else if asciiCode >= 97 && asciiCode <= 122
        {
            return SMALL_LETTER
        }
        return OTHER_CHAR
    }
    
    //MARK: 按不同类型计算密码
    ///按不同类型计算密码
    /// - Parameters:
    ///   - type: 類型
    private func countLetter(type:Int)->Int
    {
        var count = 0
        if (self as NSString).length > 0
        {
            for i in 0...((self as NSString).length - 1)
            {
                let character = (self as NSString).substring(with: NSRange.init(location: i, length: 1))
                if self.checkCharacterType(string: character) == type
                {
                    count += 1
                }
            }
        }
        return count
    }
    
    private func checkPasswordStrength()->Int
    {
        if self.isNull() && self.isCharEqual()
        {
            return 0
        }
        
        let len = (self as NSString).length
        var level : Int = 0
        
        if self.countLetter(type: NUM) > 0
        {
            level += 1
        }
        
        if countLetter(type: SMALL_LETTER) > 0
        {
            level += 1
        }
        
        if len > 4 && countLetter(type: CAPITAL_LETTER) > 0
        {
            level += 1
        }
        
        if len > 6 && countLetter(type: OTHER_CHAR) > 0
        {
            level += 1
        }
        
        if ((len > 4 && countLetter(type:NUM) > 0 && countLetter(type:SMALL_LETTER) > 0)
            || (countLetter(type:NUM) > 0 && countLetter(type:CAPITAL_LETTER) > 0)
            || (countLetter(type:NUM) > 0 && countLetter(type:OTHER_CHAR) > 0)
            || (countLetter(type:SMALL_LETTER) > 0 && countLetter(type:CAPITAL_LETTER) > 0)
            || (countLetter(type:SMALL_LETTER) > 0 && countLetter(type:OTHER_CHAR) > 0)
            || (countLetter(type:CAPITAL_LETTER) > 0 && countLetter(type:OTHER_CHAR) > 0)) {
            level += 1
        }
        
        if ((len > 6 && countLetter(type:NUM) > 0 && countLetter(type:SMALL_LETTER) > 0 && countLetter(type: CAPITAL_LETTER) > 0)
            || (countLetter(type:NUM) > 0 && countLetter(type:SMALL_LETTER) > 0 && countLetter(type:OTHER_CHAR) > 0)
            || (countLetter(type:NUM) > 0 && countLetter(type:CAPITAL_LETTER) > 0 && countLetter(type: OTHER_CHAR) > 0)
            || (countLetter(type:SMALL_LETTER) > 0 && countLetter(type:CAPITAL_LETTER) > 0 && countLetter(type: OTHER_CHAR) > 0)) {
            level += 1
        }
        
        if (len > 8 && countLetter(type: NUM) > 0 && countLetter(type:SMALL_LETTER) > 0 && countLetter(type: CAPITAL_LETTER) > 0 && countLetter(type:OTHER_CHAR) > 0) {
            level += 1
        }
        
        if ((len > 6 && countLetter(type:NUM) >= 3 && countLetter(type:SMALL_LETTER) >= 3)
            || (countLetter(type:NUM) >= 3 && countLetter(type:CAPITAL_LETTER) >= 3)
            || (countLetter(type:NUM) >= 3 && countLetter(type:OTHER_CHAR) >= 2)
            || (countLetter(type:SMALL_LETTER) >= 3 && countLetter(type:CAPITAL_LETTER) >= 3)
            || (countLetter(type:SMALL_LETTER) >= 3 && countLetter(type:OTHER_CHAR) >= 2)
            || (countLetter(type:CAPITAL_LETTER) >= 3 && countLetter(type:OTHER_CHAR) >= 2)) {
            level += 1
        }
        
        if ((len > 8 && countLetter(type:NUM) >= 2 && countLetter(type:SMALL_LETTER) >= 2 && countLetter(type:CAPITAL_LETTER) >= 2)
            || (countLetter(type:NUM) >= 2 && countLetter(type:SMALL_LETTER) >= 2 && countLetter(type:OTHER_CHAR) >= 2)
            || (countLetter(type:NUM) >= 2 && countLetter(type:CAPITAL_LETTER) >= 2 && countLetter(type:OTHER_CHAR) >= 2)
            || (countLetter(type:SMALL_LETTER) >= 2 && countLetter(type:CAPITAL_LETTER) >= 2 && countLetter(type:OTHER_CHAR) >= 2)) {
            level += 1
        }
        
        if (len > 10 && countLetter(type:NUM) >= 2 && countLetter(type:SMALL_LETTER) >= 2 && countLetter(type:CAPITAL_LETTER) >= 2 && countLetter(type:OTHER_CHAR) >= 2) {
            level += 1
        }
        
        if (countLetter(type:OTHER_CHAR) >= 3) {
            level += 1
        }
        
        if (countLetter(type:OTHER_CHAR) >= 6) {
            level += 1
        }
        
        if len > 12
        {
            level += 1
            if len >= 16
            {
                level += 1
            }
        }
        
        if "abcdefghijklmnopqrstuvwxyz".contains(self) || "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(self)
        {
            level -= 1
        }
        
        if "qwertyuiop".contains(self) || "asdfghjkl".contains(self) || "zxcvbnm".contains(self)
        {
            level -= 1
        }
        
        if isNumeric() && "01234567890".contains(self) || "09876543210".contains(self)
        {
            level -= 1
        }
        
        if countLetter(type: NUM) == len || countLetter(type: SMALL_LETTER) == len || countLetter(type: CAPITAL_LETTER) == len
        {
            level -= 1
        }
        
        if len % 2 == 0
        {
            let part1 = (self as NSString).substring(with: NSRange.init(location: 0, length: len / 2))
            let part2 = (self as NSString).substring(from: len / 2)
            if part1 == part2
            {
                level -= 1
            }
            
            if part1.isCharEqual() && part2.isCharEqual()
            {
                level -= 1
            }
        }
        
        if len % 3 == 0
        {
            let part1 = (self as NSString).substring(with: NSRange.init(location: 0, length: len / 3))
            let part2 = (self as NSString).substring(with: NSRange.init(location: len / 3, length: len / 3))
            let part3 = (self as NSString).substring(from: len / 3)
            if part1 == part2 && part2 == part3
            {
                level -= 1
            }
        }
        
        if isNumeric() && len >= 6
        {
            var year : Int = 0
            if len == 8 || len == 6
            {
                year = (self as NSString).substring(to: (self as NSString).length - 4).int!
            }
            let size = len - 4
            let month = (self as NSString).substring(with: NSRange.init(location: size, length: 2)).int!
            let day = (self as NSString).substring(with: NSRange.init(location: size + 2, length: 2)).int!
            if (year >= 1950 && year < 2050) && (month >= 1 && month <= 12) && (day >= 1 && day <= 31)
            {
                level -= 1
            }
        }
        
        commonUsers.enumerated().forEach { (index,value) in
            if value == self || (value as NSString).contains(self)
            {
                level -= 1
            }
        }
            
        if len <= 6
        {
            level -= 1
            if len <= 4
            {
                level -= 1
                if len <= 3
                {
                    level -= 0
                }
            }
        }
        
        if level < 0
        {
            level = 0
        }
        return level
    }
    
    private func isNull()->Bool
    {
        return (self).stringIsEmpty()
    }
    
    private func isCharEqual()->Bool
    {
        if (self as NSString).length < 1
        {
            return true
        }
        
        let character = (self as NSString).substring(with: NSRange.init(location: 0, length: 1))
        let string = self.replacingOccurrences(of: character, with: "")
        return ((string as NSString).length < 1)
    }
    
    private func isNumeric()->Bool
    {
        if (self as NSString).length < 1
        {
            return false
        }
        return self.isNumberString()
    }
    
    //MARK: 获取当前时间
    ///获取当前时间
    static func currentDate(dateFormatterString:String? = "yyyy-MM-dd")->String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormatterString
        return dateFormatter.string(from: Date())
    }
    
    //MARK: 时间字符串转化为时间戳
    /// - Returns: 时间戳
    func dateStrToTimeInterval(dateFormat:String = "yyyy-MM-dd") -> TimeInterval  {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = dateFormat
        let date = dateformatter.date(from: self)
        let dateTimeInterval:TimeInterval = date!.timeIntervalSince1970
        return dateTimeInterval
    }
    
    //MARK: 當前時間的時間戳字符串
    ///當前時間的時間戳字符串
    func currentTimeInterval(dateFormatter:String = "yyyy-MM-dd")->TimeInterval
    {
        return String.currentDate(dateFormatterString: dateFormatter).dateStrToTimeInterval(dateFormat: dateFormatter)
    }
    
    //MARK: 格式化時間字符串
    ///格式化時間字符串
    func dateStringFormat(calendar:Calendars = Calendars.republicOfChina,zone:Zones = Zones.asiaShanghai,local:Locales = Locales.chineseChina,formatString:String = "yyyy-MM-dd") -> String
    {
        let regions = Region(calendar: calendar, zone: zone, locale: local)
        return self.toDate(formatString,region: regions)?.toString() ?? ""
    }
    
    //MARK: JavaUnicode转苹果可以用的String
    ///JavaUnicode转苹果可以用的String
    func javaUnicodeToString()->String
    {
        let string = self.nsString.mutableCopy()
        CFStringTransform((string as! CFMutableString), nil, "Any-Hex/Java" as NSString, true)
        return (string as! String)
    }
    
    /*
     emoji相关
     */
    //MARK: 是否为单个emoji表情
    /// 是否为单个emoji表情
    var isSingleEmoji: Bool {
        return count==1 && containsEmoji
    }

    //MARK: 包含emoji表情
    /// 包含emoji表情
    var containsEmoji: Bool {
        return contains{$0.isEmoji}
    }

    //MARK: 只包含emoji表情
    /// 只包含emoji表情
    var containsOnlyEmoji: Bool {
        return !isEmpty && !contains{!$0.isEmoji}
    }

    //MARK: 提取emoji表情字符串
    /// 提取emoji表情字符串
    var emojiString: String {
        return emojis.map{ String($0) }.reduce("",+)
    }

    //MARK: 提取emoji表情数组
    /// 提取emoji表情数组
    var emojis: [Character] {
        return filter{ $0.isEmoji }
    }

    //MARK: 提取单元编码标量
    /// 提取单元编码标量
    var emojiScalars: [UnicodeScalar] {
        return filter{$0.isEmoji}.flatMap{$0.unicodeScalars}
    }
    
    //MARK: 获取视频的一个图片
    ///获取视频的一个图片
    func thumbnailImage()->UIImage
    {
        if self.isEmpty {
            //默认封面图
            return UIColor.randomColor.createImageWithColor()
        }
        
        let image = FileManager.pt.getLocalVideoImage(videoPath: self)
        if image != nil
        {
            return image!
        }
        else
        {
            return UIColor.randomColor.createImageWithColor()
        }
    }

    //MARK: 根据00:00:00时间格式，转换成秒
    ///根据00:00:00时间格式，转换成秒
    /// - Returns: Int
    func getSecondsFromTimeStr() -> Int {
        if self.isEmpty {
            return 0
        }

        let timeArry = self.replacingOccurrences(of: "：", with: ":").components(separatedBy: ":")
        var seconds:Int = 0
        if timeArry.count > 0 && timeArry[0].isNumberString()
        {
            let hh = Int(timeArry[0])
            if hh! > 0 {
                seconds += hh!*60*60
            }
        }
        if timeArry.count > 1 && timeArry[1].isNumberString(){
            let mm = Int(timeArry[1])
            if mm! > 0 {
                seconds += mm!*60
            }
        }

        if timeArry.count > 2 && timeArry[2].isNumberString(){
            let ss = Int(timeArry[2])
            if ss! > 0 {
                seconds += ss!
            }
        }
        return seconds
    }
}
