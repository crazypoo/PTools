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

public extension String
{
    static let URLCHECKSTRING = "(https|http|ftp|rtsp|igmp|file|rtspt|rtspu)://((((25[0-5]|2[0-4]\\d|1?\\d?\\d)\\.){3}(25[0-5]|2[0-4]\\d|1?\\d?\\d))|([0-9a-z_!~*'()-]*\\.?))([0-9a-z][0-9a-z-]{0,61})?[0-9a-z]\\.([a-z]{2,6})(:[0-9]{1,4})?([a-zA-Z/?_=]*)\\.\\w{1,5}"
    static let IpAddress = "^(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|[1-9])\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)\\.(1\\d{2}|2[0-4]\\d|25[0-5]|[1-9]\\d|\\d)$"
    static let URL = "[a-zA-z]+://.*"
    static let COLTDCode = "^([0-9A-HJ-NPQRTUWXY]{2}\\d{6}[0-9A-HJ-NPQRTUWXY]{10}|[1-9]\\d{14})$"
    static let POOPHONE = "^1[3|4|5|7|8][0-9]\\d{8}$"
    static let HomePhone = "^\\d{3}-?\\d{8}|\\d{4}-?\\d{8}$"
    static let ISNUMBER = "^[0-9]*$"
    
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
    
    func isNumberString()->Bool
    {
        return self.checkWithString(expression:String.ISNUMBER)
    }
    
    func isHomePhone()->Bool
    {
        return self.checkWithString(expression:String.HomePhone)
    }

    func isPooPhoneNum()->Bool
    {
        return self.checkWithString(expression:String.POOPHONE)
    }

    func isCOLTDCode()->Bool
    {
        return self.checkWithString(expression: String.COLTDCode)
    }
    
    func isURL()->Bool
    {
        return self.checkWithString(expression: String.URL)
    }
    
    func isIP()->Bool
    {
        return self.checkWithString(expression: String.IpAddress)
    }
    
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
    
    func checkWithString(expression:String)->Bool
    {
        let regextest = NSPredicate.init(format: "SELF MATCHES %@", expression)
        return regextest.evaluate(with: self)
    }

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

    /// base64 解码
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
    
    /// base64 编码
    var base64Encoded: String? {
        let plainData = data(using: .utf8)
        return plainData?.base64EncodedString()
    }
    
    var md5555:String
    {
        let utf8 = cString(using: .utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(utf8, CC_LONG(utf8!.count - 1), &digest)
        return digest.reduce("") { $0 + String(format:"%02X", $1) }
    }
    
    /// 是否包含emoji
    var isContainEmoji: Bool {
        for scalar in unicodeScalars {
            return self.containEmoji(scalar)
        }
        return false
    }
    
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
    
    /// 移除表情
    func removeEmoji() -> String {
        var scalars = self.unicodeScalars
        scalars.removeAll(where: containEmoji(_:))
        return String(scalars)
    }
    
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
    func stringIsEmpty()->Bool
    {
        return (self.charactersArray.count < 1) ? true : false
    }
    
    func toMoney()->String
    {
        return String(format: "%.2f", self.float()!)
    }
    
    func toSecurityPhone()->String
    {
        if (self).stringIsEmpty() && self.charactersArray.count > 10
        {
            return (self as NSString).replacingCharacters(in: NSRange.init(location: 3, length: 4), with: "****")
        }
        return self
    }
    
    //MARK:字符串转Dic
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
    
    /**
     检查字符的类型，包括数字、大写字母、小写字母等字符。
     
     @param character 字符
     @return 字符类型
     */
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
    
    /**
     按不同类型计算密码
     
     @param password 密码
     @param type 类型
     @return countLetter
     */
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
}
