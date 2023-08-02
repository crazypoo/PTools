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

extension String:PTProtocolCompatible {}

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

public extension String {
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
    func isNumberAndWord()->Bool {
        checkWithString(expression: String.NUMBERANDWORD)
    }

    //MARK: 判斷字符串是否中國大陸車牌
    ///判斷字符串是否中國大陸車牌
    func isCnCarLicense()->Bool {
        checkWithString(expression: String.CNCARLICENSE)
    }
    
    //MARK: 判斷字符串是否純字母
    ///判斷字符串是否純字母
    /// - Parameters:
    ///   - isLower: 是否大小寫
    func isAlphabet(isLower:Bool)->Bool {
        if isLower {
            return checkWithString(expression: String.ALPHABETLOWERCASED)
        } else {
            return checkWithString(expression: String.ALPHABETUPPERCASED)
        }
    }
    
    //MARK: 判斷字符串是否第一個為字母
    ///判斷字符串是否第一個為字母
    func isLetterFirstAlphabet()->Bool {
        checkWithString(expression: String.LETTERFIRSTALPHABET)
    }
    
    //MARK: 判斷字符串是否郵箱
    ///判斷字符串是否郵箱
    func isMail()->Bool {
        checkWithString(expression: String.MAIL)
    }
    
    //MARK: 判斷字符串是否中文
    ///判斷字符串是否中文
    func isChinese()->Bool {
        checkWithString(expression: String.CHINESE)
    }
    
    //MARK: 判斷字符串是否護照號碼
    ///判斷字符串是否護照號碼
    func isPassportNumber()->Bool {
        checkWithString(expression: String.PASSPORT)
    }
    
    //MARK: 判斷字符串是否URL
    ///判斷字符串是否URL
    func checkURL()->Bool {
        var newString : String = self
        if newString.countOfChars() < 1 {
            return false
        }
        
        if ((self as NSString).length > 4) && ((self as NSString).substring(to: 4) == "www.") {
            newString = "http://" + newString
        }
        return newString.checkWithString(expression: String.URLCHECKSTRING)
    }
    
    //MARK: 判斷字符串是否數字
    ///判斷字符串是否數字
    func isNumberString()->Bool {
        checkWithString(expression: String.ISNUMBER)
    }
    
    //MARK: 判斷字符串是否中國家庭電話
    ///判斷字符串是否中國家庭電話
    func isHomePhone()->Bool {
        checkWithString(expression: String.HomePhone)
    }

    //MARK: 判斷字符串是否中國手機號碼
    ///判斷字符串是否中國手機號碼
    func isPooPhoneNum()->Bool {
        checkWithString(expression: String.POOPHONE)
    }

    //MARK: 判斷字符串是否中國工商號碼
    ///判斷字符串是否中國工商號碼
    func isCOLTDCode()->Bool {
        checkWithString(expression: String.COLTDCode)
    }
    
    //MARK: 判斷字符串是否URL
    ///判斷字符串是否URL
    func isURL()->Bool {
        checkWithString(expression: String.URLSTRING)
    }
    
    //MARK: 判斷字符串是否IP地址
    ///判斷字符串是否IP地址
    func isIP()->Bool {
        checkWithString(expression: String.IpAddress)
    }
    
    //MARK: 判斷字符串是否金額
    ///判斷字符串是否金額
    func isMoneyString()->Bool {
        !checkWithString(expression: String.AMOUT1) && checkWithString(expression: String.AMOUT2) ? true : false
    }
    
    //MARK: 判斷字符串是否中文姓名
    ///判斷字符串是否中文姓名
    func isAChineseName()->Bool {
        if (self).stringIsEmpty() {
            return false
        }
        
        let range1 = (self as NSString).range(of: "·")
        let range2 = (self as NSString).range(of: "•")
        
        if range1.location != NSNotFound || range2.location != NSNotFound {
            if charactersArray.count < 2 || charactersArray.count > 15 {
                return false
            }
            
            do {
                let regex = try NSRegularExpression.init(pattern: "^[\u{4e00}-\u{9fa5}]+[·•][\u{4e00}-\u{9fa5}]+$", options: NSRegularExpression.Options.caseInsensitive)
                let match = regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange.init(location: 0, length: charactersArray.count))
                let count = match?.numberOfRanges
                return count == 1
            } catch  {
                return false
            }
        } else {
            if charactersArray.count < 2 || charactersArray.count > 8 {
                return false
            }

            do {
                let regex = try NSRegularExpression.init(pattern: "^[\u{4e00}-\u{9fa5}]+$", options: NSRegularExpression.Options.caseInsensitive)
                let match = regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange.init(location: 0, length: charactersArray.count))
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
    func checkWithString(expression:String)->Bool {
        let regextest = NSPredicate.init(format: "SELF MATCHES %@", expression)
        return regextest.evaluate(with: self)
    }

    //MARK: 正則表達式基類(數組)
    ///正則表達式基類(數組)
    /// - Parameters:
    ///   - expression: 正則表達式(數組)
    func checkWithArray(expression:NSArray)->Bool {
        var res = false
        for value in expression {
            let regextest = NSPredicate.init(format: "SELF MATCHES %@", value as! String)
            res = regextest.evaluate(with: self)
            if !res {
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
        if let stringData = data(using: String.Encoding.utf8) {
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
    func chineseTransToMandarinAlphabet()->String {
        let chinese:NSMutableString = nsString.mutableCopy() as! NSMutableString
        CFStringTransform((chinese as CFMutableString), nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform((chinese as CFMutableString), nil, kCFStringTransformStripCombiningMarks, false)
        var newString:NSString = chinese as NSString
        newString = newString.replacingOccurrences(of: " ", with: "") as NSString
        return newString.uppercased
    }
    
    //MARK: 暂时仅限英文换其他
    ///暂时仅限英文换其他
    func toOtherLanguage(otherLanguage:StringTransform)->String {
        stringIsEmpty() ? "" : applyingTransform(otherLanguage, reverse: false)!
    }
    
    //MARK: 時間與當前時間的對比狀態
    ///時間與當前時間的對比狀態
    func timeContrastStatus(timeInterval:TimeInterval)->String {
        let dateFormatter = "yyyy-MM-dd HH:mm:ss"
        let timeString = timeInterval.toTimeString(dateFormat: dateFormatter)
                
        let regions = Region(calendar: Calendars.republicOfChina,zone: Zones.asiaMacau,locale: Locales.chineseChina)
        var timeInterval = timeString.toDate(dateFormatter,region: regions)!.date.timeIntervalSinceNow
        timeInterval = -timeInterval
        var result = ""
        if timeInterval < 60 {
            result = "刚刚"
        } else if (timeInterval/60) < 60 {
            result = "\((timeInterval/60))分钟前"
        } else if (timeInterval/3600) > 1 && (timeInterval/3600) < 24 {
            result = "\((timeInterval/3600))小时前"
        } else if (timeInterval/3600) > 24 && (timeInterval/3600) < 48 {
            result = "昨天"
        } else if (timeInterval/3600) > 48 && (timeInterval/3600) < 72 {
            result = "前天"
        } else {
            result = timeString
        }
        return result
    }
    
    //MARK: JSON字符串轉換成真正的JSON字符串
    ///JSON字符串轉換成真正的JSON字符串
    func jsonToTrueJsonString()->String {
        var validString:NSString = nsString.replacingOccurrences(of: "(\\w+)\\s*:([^A-Za-z0-9_])", with: "\"$1\":$2",options: NSString.CompareOptions.regularExpression,range: NSRange(location: 0, length: nsString.length)) as NSString
        validString = validString.replacingOccurrences(of: "([:\\[,\\{])'", with: "$1\"",options: NSString.CompareOptions.regularExpression, range: NSRange(location: 0, length: validString.length)) as NSString
        validString = validString.replacingOccurrences(of: "'([:\\],\\}])", with: "\"$1",options: NSString.CompareOptions.regularExpression, range: NSRange(location: 0, length: validString.length)) as NSString
        validString = validString.replacingOccurrences(of: "([:\\[,\\{])(\\w+)\\s*:", with: "$1\"$2\":",options: NSString.CompareOptions.regularExpression, range: NSRange(location: 0, length: validString.length)) as NSString
        return validString as String
    }
    
    //MARK: 字符串轉換成UTF8字符串
    ///字符串轉換成UTF8字符串
    func stringToUTF8String(type:UTF8StringType)->NSString {
        switch type {
        case .UTF8StringTypeOC:
            return NSString.init(cString: nsString.utf8String!, encoding: NSUnicodeStringEncoding)!
        case .UTF8StringTypeC:
            return nsString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet(charactersIn: "`#%^{}\"[]|\\<> ").inverted)! as NSString
        }
    }
    
    //MARK: 根據字符串轉換成二維碼圖片
    ///根據字符串轉換成二維碼圖片
    func createQRImage(size:CGFloat)->UIImage {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setDefaults()
        let data = nsString.data(using: String.Encoding.utf8.rawValue)
        filter?.setValue(data, forKey: "inputMessage")
        let image = filter?.outputImage
        return PTUtils.createNoneInterpolatedUIImage(image: image!, imageSize: size)
    }
    
    //MARK: 字符串根据某个字符进行分隔成数组
    ///字符串根据某个字符进行分隔成数组
    /// - Parameter char: 分隔符
    /// - Returns: 分隔后的数组
    func separatedByString(with char: String) -> Array<String> {
        let arraySubstrings = self.components(separatedBy: char)
        let arrayStrings: [String] = arraySubstrings.compactMap { "\($0)" }
        return arrayStrings
    }
    
    //MARK: 获取指定位置和长度的字符串
    ///获取指定位置和大小的字符串
    /// - Parameters:
    ///   - start: 开始位置
    ///   - length: 长度
    /// - Returns: 截取后的字符串
    func sub(start: Int, length: Int = -1) -> String {
        var len = length
        if len == -1 {
            len = self.count - start
        }
        let st = self.index(self.startIndex, offsetBy: start)
        let en = self.index(st, offsetBy: len)
        let range = st ..< en
        return String(self[range])
    }
    
    //MARK: 隐藏手机号中间的几位(保留前几位和后几位)
    ///隐藏手机号中间的几位(保留前几位和后几位)
    /// - Parameters:
    ///   - combine: 中间加密的符号
    ///   - digitsBefore: 前面保留的位数
    ///   - digitsAfter: 后面保留的位数
    /// - Returns: 返回隐藏的手机号
    func hidePhone(combine: String = "*", digitsBefore: Int = 2, digitsAfter: Int = 2) -> String {
        let phoneLength: Int = self.count
        if phoneLength > digitsBefore + digitsAfter {
            let combineCount: Int = phoneLength - digitsBefore - digitsAfter
            var combineContent: String = ""
            for _ in 0..<combineCount {
                combineContent = combineContent + combine
            }
            let pre = self.sub(start: 0, length: digitsBefore)
            let post = self.sub(start: phoneLength - digitsAfter, length: digitsAfter)
            return pre + "\(combineContent)" + post
        } else {
            return self
        }
    }
    
    //MARK:  隐藏邮箱中间的几位(保留前几位和后几位)
    ///隐藏邮箱中间的几位(保留前几位和后几位)
    /// - Parameters:
    ///   - combine: 加密的符号
    ///   - digitsBefore: 前面保留几位
    ///   - digitsAfter: 后面保留几位
    /// - Returns: 返回加密后的字符串
    func hideEmail(combine: String = "*", digitsBefore: Int = 1, digitsAfter: Int = 1) -> String {
        let emailArray = separatedByString(with: "@")
        if emailArray.count == 2 {
            let fistContent = emailArray[0]
            let encryptionContent = fistContent.hidePhone(combine: "*", digitsBefore: 1, digitsAfter: 1)
            return encryptionContent + "@" +  emailArray[1]
        }
        return self
    }

    //MARK: 判断一个Class是否存在
    ///判断一个Class是否存在
    func checkClass() -> Bool {
        if NSClassFromString(self) != nil {
            return true
        } else {
            return false
        }
    }
}

fileprivate extension PTUtils {
    //MARK: 創建一個圖片
    ///創建一個圖片
    class func createNoneInterpolatedUIImage(image:CIImage,imageSize:CGFloat)->UIImage {
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
        data(using: .utf8)?.toModel(type)
    }
}

public extension String {
    static func currencySymbol()->String {
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
    func financeDataString(numberStyle:NumberFormatter.Style)->String {
        var str = self
        if stringIsEmpty() {
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
    func stringIsEmpty()->Bool {
        (self as NSString).length == 0 || (charactersArray.count < 1) ? true : false
    }
    
    //MARK: 轉換成數字字符串
    ///轉換成數字字符串
    /// - Parameters:
    ///   - decimal: 是否帶小數點
    func numberStringFormatter(decimal:Bool)->String {
        let numberFormat = NumberFormatter()
        numberFormat.numberStyle = .decimal
        var outputValue = ""
        if decimal {
            outputValue = numberFormat.string(from: NSDecimalNumber.init(string: self))!
        } else {
            outputValue = numberFormat.string(from: NSNumber.init(value: int!))!
        }
        return outputValue
    }
    
    //MARK: 轉換成金額
    ///轉換成金額
    func toMoney()->String {
        String(format: "%.2f", float() ?? 0.00)
    }
    
    func toSecurityPhone()->String {
        if !(self).stringIsEmpty() && charactersArray.count > 10 && isPooPhoneNum() {
            return (self as NSString).replacingCharacters(in: NSRange.init(location: 3, length: 4), with: "****")
        }
        return self
    }
    
    //MARK: 字符串转Dic
    ///字符串转Dic
    func jsonStringToDic()->NSDictionary? {
        if self.isEmpty {
            return nil
        }
        
        let jsonData = data(using: Encoding.utf8)
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
        
    func jsonStringToArray()->NSArray {
        do {
            let tmp = try JSONSerialization.jsonObject(with: data(using: String.Encoding.utf8)!, options: [JSONSerialization.ReadingOptions.mutableLeaves,JSONSerialization.ReadingOptions.mutableContainers])
            if tmp is NSArray {
                return (tmp as! NSArray)
            } else if (tmp is NSString) || (tmp is NSDictionary) {
                return NSArray.init(array: [tmp])
            }
        } catch {
            return NSArray.init()
        }
        return NSArray.init()
    }
    
    //MARK: 判斷密碼的強度
    ///判斷密碼的強度
    func passwordLevel()->PStrengthLevel {
        let level = checkPasswordStrength()
        if level > 0 && level < 4 {
            return .Easy
        } else if level > 3 && level < 7 {
            return .Midium
        } else if level > 7 && level < 10 {
            return .Strong
        } else if level > 10 && level < 13 {
            return .Very_Strong
        } else {
            return .Extremely_Strong
        }
    }
    
    //MARK: 检查字符的类型，包括数字、大写字母、小写字母等字符。
    ///检查字符的类型，包括数字、大写字母、小写字母等字符。
    /// - Parameters:
    ///   - string: 字符串
    private func checkCharacterType(string:String)->Int {
        let asciiCode = (string as NSString).character(at: 0)
        if asciiCode >= 48 && asciiCode <= 57 {
            return NUM
        } else if asciiCode >= 65 && asciiCode <= 90 {
            return CAPITAL_LETTER
        } else if asciiCode >= 97 && asciiCode <= 122 {
            return SMALL_LETTER
        }
        return OTHER_CHAR
    }
    
    //MARK: 按不同类型计算密码
    ///按不同类型计算密码
    /// - Parameters:
    ///   - type: 類型
    private func countLetter(type:Int)->Int {
        var count = 0
        if (self as NSString).length > 0 {
            for i in 0...((self as NSString).length - 1) {
                let character = (self as NSString).substring(with: NSRange.init(location: i, length: 1))
                if checkCharacterType(string: character) == type {
                    count += 1
                }
            }
        }
        return count
    }
    
    private func checkPasswordStrength()->Int {
        if isNull() && isCharEqual() {
            return 0
        }
        
        let len = (self as NSString).length
        var level : Int = 0
        
        if countLetter(type: NUM) > 0 {
            level += 1
        }
        
        if countLetter(type: SMALL_LETTER) > 0 {
            level += 1
        }
        
        if len > 4 && countLetter(type: CAPITAL_LETTER) > 0 {
            level += 1
        }
        
        if len > 6 && countLetter(type: OTHER_CHAR) > 0 {
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
        
        if len > 12 {
            level += 1
            if len >= 16 {
                level += 1
            }
        }
        
        if "abcdefghijklmnopqrstuvwxyz".contains(self) || "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(self) {
            level -= 1
        }
        
        if "qwertyuiop".contains(self) || "asdfghjkl".contains(self) || "zxcvbnm".contains(self) {
            level -= 1
        }
        
        if isNumeric() && "01234567890".contains(self) || "09876543210".contains(self) {
            level -= 1
        }
        
        if countLetter(type: NUM) == len || countLetter(type: SMALL_LETTER) == len || countLetter(type: CAPITAL_LETTER) == len {
            level -= 1
        }
        
        if len % 2 == 0 {
            let part1 = (self as NSString).substring(with: NSRange.init(location: 0, length: len / 2))
            let part2 = (self as NSString).substring(from: len / 2)
            if part1 == part2 {
                level -= 1
            }
            
            if part1.isCharEqual() && part2.isCharEqual() {
                level -= 1
            }
        }
        
        if len % 3 == 0 {
            let part1 = (self as NSString).substring(with: NSRange.init(location: 0, length: len / 3))
            let part2 = (self as NSString).substring(with: NSRange.init(location: len / 3, length: len / 3))
            let part3 = (self as NSString).substring(from: len / 3)
            if part1 == part2 && part2 == part3 {
                level -= 1
            }
        }
        
        if isNumeric() && len >= 6 {
            var year : Int = 0
            if len == 8 || len == 6 {
                year = (self as NSString).substring(to: (self as NSString).length - 4).int!
            }
            let size = len - 4
            let month = (self as NSString).substring(with: NSRange.init(location: size, length: 2)).int!
            let day = (self as NSString).substring(with: NSRange.init(location: size + 2, length: 2)).int!
            if (year >= 1950 && year < 2050) && (month >= 1 && month <= 12) && (day >= 1 && day <= 31) {
                level -= 1
            }
        }
        
        commonUsers.enumerated().forEach { (index,value) in
            if value == self || (value as NSString).contains(self) {
                level -= 1
            }
        }
            
        if len <= 6 {
            level -= 1
            if len <= 4 {
                level -= 1
                if len <= 3 {
                    level -= 0
                }
            }
        }
        
        if level < 0 {
            level = 0
        }
        return level
    }
    
    private func isNull()->Bool {
        (self).stringIsEmpty()
    }
    
    private func isCharEqual()->Bool {
        if (self as NSString).length < 1 {
            return true
        }
        
        let character = (self as NSString).substring(with: NSRange.init(location: 0, length: 1))
        let string = self.replacingOccurrences(of: character, with: "")
        return ((string as NSString).length < 1)
    }
    
    private func isNumeric()->Bool {
        if (self as NSString).length < 1 {
            return false
        }
        return isNumberString()
    }
    
    //MARK: 根據日期字符串獲取星座名稱
    ///根據日期字符串獲取星座名稱
    func getConstellation(format:String = "yyyy-MM-dd HH:mm:ss")->String {
        let getDate = self.toDate(format)!.date
        let month = getDate.month
        let day = getDate.day
        
        switch (month, day) {
        case (1, 20...31), (2, 1...18):
            ///水瓶
            return "Aquarius"
        case (2, 19...29), (3, 1...20):
            ///双鱼
            return "Pisces"
        case (3, 21...31), (4, 1...19):
            ///白羊
            return "Aries"
        case (4, 20...30), (5, 1...20):
            ///金牛
            return "Taurus"
        case (5, 21...31), (6, 1...20):
            ///双子
            return "Gemini"
        case (6, 21...30), (7, 1...22):
            ///巨蟹
            return "Cancer"
        case (7, 23...31), (8, 1...22):
            ///狮子
            return "Leo"
        case (8, 23...31), (9, 1...22):
            ///处女
            return "Virgo"
        case (9, 23...30), (10, 1...22):
            ///天秤
            return "Libra"
        case (10, 23...31), (11, 1...21):
            ///天蝎
            return "Scorpio"
        case (11, 22...30), (12, 1...21):
            ///射手
            return "Sagittarius"
        case (12, 22...31), (1, 1...19):
            ///摩羯
            return "Capricorn"
        default:
            return ""
        }
    }
    
    func getConstellationChinese(format:String = "yyyy-MM-dd HH:mm:ss") ->String {
        var constellationChinese = ""
        let constellation = getConstellation(format: format)
        switch constellation {
        case "Aquarius":
            constellationChinese = "水瓶座"
        case "Pisces":
            constellationChinese = "双鱼座"
        case "Aries":
            constellationChinese = "白羊座"
        case "Taurus":
            constellationChinese = "金牛座"
        case "Gemini":
            constellationChinese = "双子座"
        case "Cancer":
            constellationChinese = "巨蟹座"
        case "Leo":
            constellationChinese = "狮子座"
        case "Virgo":
            constellationChinese = "处女座"
        case "Libra":
            constellationChinese = "天秤座"
        case "Scorpio":
            constellationChinese = "天蝎座"
        case "Sagittarius":
            constellationChinese = "射手座"
        case "Capricorn":
            constellationChinese = "摩羯座"
        default:
            constellationChinese = ""
        }
        return constellationChinese
    }
    
    func emojiConstellationSign() -> String {
        switch lowercased() {
            case "aries":
                return "♈️"
            case "taurus":
                return "♉️"
            case "gemini":
                return "♊️"
            case "cancer":
                return "♋️"
            case "leo":
                return "♌️"
            case "virgo":
                return "♍️"
            case "libra":
                return "♎️"
            case "scorpio":
                return "♏️"
            case "sagittarius":
                return "♐️"
            case "capricorn":
                return "♑️"
            case "aquarius":
                return "♒️"
            case "pisces":
                return "♓️"
            default:
                return ""
        }
    }

    //MARK: 获取当前时间
    ///获取当前时间
    static func currentDate(dateFormatterString:String? = "yyyy-MM-dd")->String {
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
    func currentTimeInterval(dateFormatter:String = "yyyy-MM-dd")->TimeInterval {
        String.currentDate(dateFormatterString: dateFormatter).dateStrToTimeInterval(dateFormat: dateFormatter)
    }
    
    //MARK: 格式化時間字符串
    ///格式化時間字符串
    func dateStringFormat(calendar:Calendars = Calendars.republicOfChina,zone:Zones = Zones.asiaShanghai,local:Locales = Locales.chineseChina,formatString:String = "yyyy-MM-dd") -> String {
        let regions = Region(calendar: calendar, zone: zone, locale: local)
        return self.toDate(formatString,region: regions)?.toString() ?? ""
    }
    
    //MARK: JavaUnicode转苹果可以用的String
    ///JavaUnicode转苹果可以用的String
    func javaUnicodeToString()->String {
        let string = nsString.mutableCopy()
        CFStringTransform((string as! CFMutableString), nil, "Any-Hex/Java" as NSString, true)
        return (string as! String)
    }
    
    /*
     emoji相关
     */
    //MARK: 是否为单个emoji表情
    /// 是否为单个emoji表情
    var isSingleEmoji: Bool {
        count == 1 && containsEmoji
    }

    //MARK: 包含emoji表情
    /// 包含emoji表情
    var containsEmoji: Bool {
        contains {
            $0.isEmoji
        }
    }

    //MARK: 只包含emoji表情
    /// 只包含emoji表情
    var containsOnlyEmoji: Bool {
        !isEmpty && !contains {
            !$0.isEmoji
        }
    }

    //MARK: 提取emoji表情字符串
    /// 提取emoji表情字符串
    var emojiString: String {
        emojis.map {
                    String($0)
                }
                .reduce("", +)
    }

    //MARK: 提取emoji表情数组
    /// 提取emoji表情数组
    var emojis: [Character] {
        filter {
            $0.isEmoji
        }
    }

    //MARK: 提取单元编码标量
    /// 提取单元编码标量
    var emojiScalars: [UnicodeScalar] {
        filter {
            $0.isEmoji
        }
                .flatMap {
                    $0.unicodeScalars
                }
    }
    
    //MARK: Emoji转图片
    ///Emoji转图片
    /*
     如果使用 UIImage(systemName:) 方法转换Emoji表情为图片返回的 UIImage 对象为空，则可能是由于表情不受支持或无效。这是因为 UIImage(systemName:) 方法是根据系统中内置的 SF Symbol 字体来渲染图像的，SF Symbol 字体包含有限的表情符号，因此并不是所有的 Emoji 表情都能被成功转换。
     所以如何系统 UIImage(systemName:) 的方法返回为空则调用 Core Text来绘制图片
    */
    func emojiToImage(emojiFont:UIFont? = .appfont(size: 24)) -> UIImage {
        if isSingleEmoji {
            if let image = UIImage(systemName: self) {
                return image
            } else {
                let nsText = nsString
                let fontAttributes = [NSAttributedString.Key.font: emojiFont]
                let imageSize = nsText.size(withAttributes: fontAttributes as [NSAttributedString.Key : Any])
                
                UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.main.scale)
                defer { UIGraphicsEndImageContext() }
                
                let _ = UIGraphicsGetCurrentContext()
                
                nsText.draw(at: CGPoint.zero, withAttributes: fontAttributes as [NSAttributedString.Key : Any])
                
                guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
                return image
            }
        } else {
            return UIImage()
        }
    }
    
    //MARK: 获取视频的一个图片
    ///获取视频的一个图片
    func thumbnailImage()->UIImage {
        if self.isEmpty {
            //默认封面图
            return UIColor.randomColor.createImageWithColor()
        }
        
        let image = FileManager.pt.getLocalVideoImage(videoPath: self)
        if image != nil {
            return image!
        } else {
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
        if timeArry.count > 0 && timeArry[0].isNumberString() {
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
    
    //MARK: 根據文件名字拿到Bundle上的顏色
    ///根據文件名字拿到Bundle上的顏色
    /// - Parameters:
    ///   - traitCollection: 當前系統的顯示模式
    ///   - bundle: 顏色所在Bundle
    /// - Returns: 返回顏色,如果獲取不到會返回隨機顏色
    func color(traitCollection:UITraitCollection = (UIApplication.shared.delegate?.window?!.rootViewController!.traitCollection)!,
               bundle:Bundle = PTUtils.cgBaseBundle())->UIColor {
        UIColor(named: self, in: bundle, compatibleWith: traitCollection) ?? .randomColor
    }
    
    //MARK: 根據文件名字拿到Bundle上的圖片
    ///根據文件名字拿到Bundle上的圖片
    /// - Parameters:
    ///   - traitCollection: 當前系統的顯示模式
    ///   - bundle: 圖片所在Bundle
    /// - Returns: 返回顏色,如果獲取不到會返回隨機顏色
    func image(traitCollection:UITraitCollection = (UIApplication.shared.delegate?.window?!.rootViewController!.traitCollection)!,
               bundle:Bundle = PTUtils.cgBaseBundle())->UIImage {
        UIImage(named: self, in: bundle, compatibleWith: traitCollection) ?? UIColor.randomColor.createImageWithColor()
    }
    
    //MARK: 根據文件名字拿到Bundle上的圖片
    ///根據文件名字拿到Bundle上的圖片
    /// - Parameters:
    ///   - bundle: 圖片所在Bundle
    /// - Returns: 返回顏色,如果獲取不到會返回隨機顏色
    func darkModeImage(bundle:Bundle = PTUtils.cgBaseBundle())->UIImage {
        image(bundle: bundle)
    }
}

public extension PTPOP where Base: ExpressibleByStringLiteral {
    //MARK: 字符串的长度
    ///字符串的长度
    var length: Int {
        let string = base as! String
        return string.count
    }
    
    //MARK: 判断是否包含某个子串
    ///判断是否包含某个子串
    /// - Parameters:
    ///  - find: 子串
    /// - Returns: Bool
    func contains(find: String) -> Bool {
        (base as! String).range(of: find) != nil
    }
    
    //MARK: 判断是否包含某个子串(忽略大小写)
    ///判断是否包含某个子串 (忽略大小写)
    /// - Parameters:
    ///  - find: 子串
    /// - Returns: Bool
    func containsIgnoringCase(find: String) -> Bool {
        (base as! String).range(of: find, options: .caseInsensitive) != nil
    }
    
    //MARK: 字符串转Base64
    ///字符串转Base64编码
    var base64Encode: String? {
        guard let codingData = (base as! String).data(using: .utf8) else {
            return nil
        }
        return codingData.base64EncodedString()
    }
    
    //MARK: Base64转字符串转
    ///字符串转Base64编码
    var base64Decode: String? {
        guard let decryptionData = Data(base64Encoded: base as! String, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return String(data: decryptionData, encoding: .utf8)
    }

    //MARK: 字符串转数组
    ///字符串转数组
    /// - Returns: 转化后的数组
    func toArray() -> Array<Any> {
        let a = Array(base as! String)
        return a
    }
    
    //MARK: JSON字符串转Dictionary
    ///JSON字符串转Dictionary
    /// - Returns: Dictionary
    func jsonStringToDictionary() -> Dictionary<String, Any>? {
        let jsonString = base as! String
        let jsonData: Data = jsonString.data(using: .utf8)!
        let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        if dict != nil {
            return (dict as! Dictionary<String, Any>)
        }
        return nil
    }
    
    //MARK: JSON字符串转Array
    ///JSON字符串转Array
    /// - Returns: Array
    func jsonStringToArray() -> Array<Any>? {
        let jsonString = base as! String
        let jsonData:Data = jsonString.data(using: .utf8)!
        let array = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        if array != nil {
            return (array as! Array<Any>)
        }
        return nil
    }
    
    //MARK: JSON字符串转urlencode
    ///JSON字符串转urlencode
    /// - Returns: String
    func jsonStringToQueryString() -> String? {
        let jsonString = base as! String
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                var queryString = ""
                for (key, value) in jsonObject {
                    if let stringValue = value as? String {
                        let encodedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        queryString += "\(key)=\(encodedValue)&"
                    } else {
                        // Handle other value types if needed
                    }
                }
                // Remove the trailing '&' character if present
                if queryString.last == "&" {
                    queryString.removeLast()
                }
                return queryString
            }
        } catch {
            PTNSLogConsole("Error parsing JSON: \(error)")
        }
        return nil
    }
    
    //MARK: 转成拼音
    ///转成拼音
    /// - Parameters:
    ///  - isTone: true：带声调，false：不带声调，默认 false
    /// - Returns: 拼音
    func toLetter(_ isTone: Bool = false) -> String {
        let mutableString = NSMutableString(string: base as! String)
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        if !isTone {
            // 不带声调
            CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        }
        return mutableString as String
    }
    
    //MARK: 中文提取首字母
    ///中文提取首字母
    /// - Parameters:
    ///  - isUpper:  true：大写首字母，false: 小写首字母，默认 true
    /// - Returns: 字符串的首字母
    func letterInitials(_ isUpper: Bool = true) -> String {
        let pinyin = toLetter(false).components(separatedBy: " ")
        let initials = pinyin.compactMap { String(format: "%c", $0.cString(using:.utf8)![0]) }
        return isUpper ? initials.joined().uppercased() : initials.joined()
    }

    //MARK: 提取出字符串中所有的URL链接
    ///提取出字符串中所有的URL链接
    /// - Returns: URL链接数组
    func getUrls() -> [String]? {
        var urls = [String]()
        // 创建一个正则表达式对象
        guard let dataDetector = try? NSDataDetector(types:  NSTextCheckingTypes(NSTextCheckingResult.CheckingType.link.rawValue)) else {
            return nil
        }
        // 匹配字符串，返回结果集
        let res = dataDetector.matches(in: base as! String, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, (base as! String).count))
        // 取出结果
        for checkingRes in res {
            urls.append((base as! NSString).substring(with: checkingRes.range))
        }
        return urls
    }

    //MARK: 计算字符个数（英文 = 1，数字 = 1，汉语 = 2）
    ///计算字符个数（英文 = 1，数字 = 1，汉语 = 2）
    /// - Returns: 返回字符的个数
    func countOfChars() -> Int {
        var count = 0
        guard (base as! String).count > 0 else { return 0 }
        for i in 0...(base as! String).count - 1 {
            let c: unichar = ((base as! String) as NSString).character(at: i)
            if (c >= 0x4E00) {
                count += 2
            } else {
                count += 1
            }
        }
        return count
    }

    //MARK: 将金额字符串转化为带逗号的金额 按照千分位划分，如  "1234567" => 1,234,567   1234567.56 => 1,234,567.56
    ///将金额字符串转化为带逗号的金额 按照千分位划分，如  "1234567" => 1,234,567   1234567.56 => 1,234,567.56
    /// - Returns: 千分位的字符串
    func toThousands() -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .floor
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        if (base as! String).contains(".") {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            formatter.minimumIntegerDigits = 1
        }
        var num = NSDecimalNumber(string: (base as! String))
        if num.doubleValue.isNaN {
            num = NSDecimalNumber(string: "0")
        }
        let result = formatter.string(from: num)
        return result
    }
}

// MARK: AES, AES128, DES, DES3, CAST, RC2, RC4, Blowfish 多种加密
/**
 iOS中填充规则PKCS7,加解密模式ECB(无补码,CCCrypt函数中对应的nil),字符集UTF8,输出base64(可以自己改hex)
 */
//MARK: 加密模式
public enum DDYSCAType {
    case AES, AES128, DES, DES3, CAST, RC2, RC4, Blowfish
    var infoTuple: (algorithm: CCAlgorithm, digLength: Int, keyLength: Int) {
        switch self {
        case .AES:
            return (CCAlgorithm(kCCAlgorithmAES), Int(kCCKeySizeAES128), Int(kCCKeySizeAES128))
        case .AES128:
            return (CCAlgorithm(kCCAlgorithmAES128), Int(kCCBlockSizeAES128), Int(kCCKeySizeAES256))
        case .DES:
            return (CCAlgorithm(kCCAlgorithmDES), Int(kCCBlockSizeDES), Int(kCCKeySizeDES))
        case .DES3:
            return (CCAlgorithm(kCCAlgorithm3DES), Int(kCCBlockSize3DES), Int(kCCKeySize3DES))
        case .CAST:
            return (CCAlgorithm(kCCAlgorithmCAST), Int(kCCBlockSizeCAST), Int(kCCKeySizeMaxCAST))
        case .RC2:
            return (CCAlgorithm(kCCAlgorithmRC2), Int(kCCBlockSizeRC2), Int(kCCKeySizeMaxRC2))
        case .RC4:
            return (CCAlgorithm(kCCAlgorithmRC4), Int(kCCBlockSizeRC2), Int(kCCKeySizeMaxRC4))
        case .Blowfish:return (CCAlgorithm(kCCAlgorithmBlowfish), Int(kCCBlockSizeBlowfish), Int(kCCKeySizeMaxBlowfish))
        }
    }
}

public extension PTPOP where Base: ExpressibleByStringLiteral {
    
    //MARK: 字符串 AES, AES128, DES, DES3, CAST, RC2, RC4, Blowfish 多种加密
    ///字符串 AES, AES128, DES, DES3, CAST, RC2, RC4, Blowfish 多种加密
    /// - Parameters:
    ///   - cryptType: 加密类型
    ///   - key: 加密的key
    ///   - encode: 编码还是解码
    ///   - encryptIV: 偏移量
    /// - Returns: 编码或者解码后的字符串
    func scaCrypt(cryptType: DDYSCAType, key: String?, encode: Bool, encryptIV: String = "1") -> String? {
        
        let strData = encode ? (base as! String).data(using: .utf8) : Data(base64Encoded: (base as! String))
        // 创建数据编码后的指针
        let dataPointer = UnsafeRawPointer((strData! as NSData).bytes)
        // 获取转码后数据的长度
        let dataLength = size_t(strData!.count)
        
        // 2、后台对应的加密key
        // 将加密或解密的密钥转化为Data数据
        guard let keyData = key?.data(using: .utf8) else {
            return nil
        }
        // 创建密钥的指针
        let keyPointer = UnsafeRawPointer((keyData as NSData).bytes)
        // 设置密钥的长度
        let keyLength = cryptType.infoTuple.keyLength
        /// 3、后台对应的加密 IV，这个是跟后台商量的iv偏移量
        let encryptIV = "1"
        let encryptIVData = encryptIV.data(using: .utf8)!
        let encryptIVDataBytes = UnsafeRawPointer((encryptIVData as NSData).bytes)
        // 创建加密或解密后的数据对象
        let cryptData = NSMutableData(length: Int(dataLength) + cryptType.infoTuple.digLength)
        // 获取返回数据(cryptData)的指针
        let cryptPointer = UnsafeMutableRawPointer(mutating: cryptData!.mutableBytes)
        // 获取接收数据的长度
        let cryptDataLength = size_t(cryptData!.length)
        // 加密或则解密后的数据长度
        var cryptBytesLength:size_t = 0
        // 是解密或者加密操作(CCOperation 是32位的)
        let operation = encode ? CCOperation(kCCEncrypt) : CCOperation(kCCDecrypt)
        // 算法类型
        let algoritm: CCAlgorithm = CCAlgorithm(cryptType.infoTuple.algorithm)
        // 设置密码的填充规则（ PKCS7 & ECB 两种填充规则）
        let options: CCOptions = UInt32(kCCOptionPKCS7Padding) | UInt32(kCCOptionECBMode)
        // 执行算法处理
        let cryptStatus = CCCrypt(operation, algoritm, options, keyPointer, keyLength, encryptIVDataBytes, dataPointer, dataLength, cryptPointer, cryptDataLength, &cryptBytesLength)
        // 结果字符串初始化
        var resultString: String?
        // 通过返回状态判断加密或者解密是否成功
        if CCStatus(cryptStatus) == CCStatus(kCCSuccess) {
            cryptData!.length = cryptBytesLength
            if encode {
                resultString = cryptData!.base64EncodedString(options: .lineLength64Characters)
            } else {
                resultString = NSString(data:cryptData! as Data ,encoding:String.Encoding.utf8.rawValue) as String?
            }
        }
        return resultString
    }
}

//MARK: SHA1, SHA224, SHA256, SHA384, SHA512
/**
 - 安全哈希算法（Secure Hash Algorithm）主要适用于数字签名标准（Digital Signature Standard DSS）里面定义的数字签名算法（Digital Signature Algorithm DSA）。对于长度小于2^64位的消息，SHA1会产生一个160位的消息摘要。当接收到消息的时候，这个消息摘要可以用来验证数据的完整性。在传输的过程中，数据很可能会发生变化，那么这时候就会产生不同的消息摘要。当让除了SHA1还有SHA256以及SHA512等。
 - SHA1有如下特性：不可以从消息摘要中复原信息；两个不同的消息不会产生同样的消息摘要
 - SHA1 SHA256 SHA512 这4种本质都是摘要函数，不通在于长度 SHA1是160位，SHA256是256位，SHA512是512位
 */
//MARK: 加密类型
public enum DDYSHAType {
    case SHA1, SHA224, SHA256, SHA384, SHA512
    var infoTuple: (algorithm: CCHmacAlgorithm, length: Int) {
        switch self {
        case .SHA1:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA1), length: Int(CC_SHA1_DIGEST_LENGTH))
        case .SHA224:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA224), length: Int(CC_SHA224_DIGEST_LENGTH))
        case .SHA256:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA256), length: Int(CC_SHA256_DIGEST_LENGTH))
        case .SHA384:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA384), length: Int(CC_SHA384_DIGEST_LENGTH))
        case .SHA512:
            return (algorithm: CCHmacAlgorithm(kCCHmacAlgSHA512), length: Int(CC_SHA512_DIGEST_LENGTH))
        }
    }
}

public extension PTPOP where Base: ExpressibleByStringLiteral {
    
    //MARK: SHA1, SHA224, SHA256, SHA384, SHA512 加密
    ///SHA1, SHA224, SHA256, SHA384, SHA512 加密
    /// - Parameters:
    ///   - cryptType: 加密类型，默认是 SHA1 加密
    ///   - key: 加密的key
    ///   - lower: 大写还是小写，默认小写
    /// - Returns: 加密以后的字符串
    func shaCrypt(cryptType: DDYSHAType = .SHA1, key: String?, lower: Bool = true) -> String? {
        guard let cStr = (base as! String).cString(using: String.Encoding.utf8) else {
            return nil
        }
        let strLen  = strlen(cStr)
        let digLen = cryptType.infoTuple.length
        let buffer = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digLen)
        let hash = NSMutableString()
        
        if let cKey = key?.cString(using: String.Encoding.utf8), key != "" {
            let keyLen = Int(key!.lengthOfBytes(using: String.Encoding.utf8))
            CCHmac(cryptType.infoTuple.algorithm, cKey, keyLen, cStr, strLen, buffer)
        } else {
            switch cryptType {
            case .SHA1:     CC_SHA1(cStr,   (CC_LONG)(strlen(cStr)), buffer)
            case .SHA224:   CC_SHA224(cStr, (CC_LONG)(strlen(cStr)), buffer)
            case .SHA256:   CC_SHA256(cStr, (CC_LONG)(strlen(cStr)), buffer)
            case .SHA384:   CC_SHA384(cStr, (CC_LONG)(strlen(cStr)), buffer)
            case .SHA512:   CC_SHA512(cStr, (CC_LONG)(strlen(cStr)), buffer)
            }
        }
        for i in 0..<digLen {
            if lower {
                hash.appendFormat("%02x", buffer[i])
            } else {
                hash.appendFormat("%02X", buffer[i])
            }
        }
        free(buffer)
        return hash as String
    }
}
