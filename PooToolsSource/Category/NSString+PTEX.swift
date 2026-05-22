//
//  NSString+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/11/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

extension NSString:PTProtocolCompatible {}

public extension NSString {
    /*  银行卡号有效性问题Luhm算法
     *  现行 16 位银联卡现行卡号开头 6 位是 622126～622925 之间的，7 到 15 位是银行自定义的，
     *  可能是发卡分行，发卡网点，发卡序号，第 16 位是校验码。
     *  16 位卡号校验位采用 Luhm 校验方法计算：
     *  1，将未带校验位的 15 位卡号从右依次编号 1 到 15，位于奇数位号上的数字乘以 2
     *  2，将奇位乘积的个十位全部相加，再加上所有偶数位上的数字
     *  3，将加法和加上校验位能被 10 整除。
     */
    //MARK: 銀行卡Luhm算法
    ///銀行卡Luhm算法
    /// - Returns: Bool
    func bankCardLuhmCheck() -> Bool {
        // 1. 基本的合法性校验：去除空格，判断是否为空，长度是否符合基本要求
        let trimmedString = self.trimmingCharacters(in: .whitespaces)
        if trimmedString.isEmpty || trimmedString.count < 3 {
            return false
        }
        
        var sum = 0
        var isAlternate = false // 用于标记是否是需要乘以 2 的位
        
        // 2. 从右向左（倒序）直接遍历字符串的每一个字符
        for char in trimmedString.reversed() {
            // 3. 将字符安全地转换为整数 (如果含有非数字字符，则直接返回 false)
            guard let digit = char.wholeNumberValue else {
                return false
            }
            
            // 4. 根据位次应用 Luhn 算法规则
            if isAlternate {
                let doubled = digit * 2
                // 如果乘 2 后大于 9，减去 9 (等同于十位加个位)
                sum += (doubled > 9) ? (doubled - 9) : doubled
            } else {
                // 如果不是交替位，直接把数字加到总和中
                sum += digit
            }
            
            // 5. 切换奇偶位状态
            isAlternate.toggle()
        }
        
        // 6. 最终判断总和是否能被 10 整除
        return sum % 10 == 0
    }
    
    /*
     身份证号:加权因子
     中国大陆个人身份证号验证 Chinese Mainland Personal ID Card Validation
     */
    //MARK: 檢測中國公民新份證
    ///檢測中國公民新份證
    /// - Returns: Bool
    func isValidateIdentity() -> Bool {
        if length != 18 {
            return false
        }
        
        let regex2 = "^(^[1-9]\\d{7}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}$)|(^[1-9]\\d{5}[1-9]\\d{3}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])((\\d{4})|\\d{3}[Xx])$)$"
        let identityStringPredicate = NSPredicate(format: "SELF MATCHES %@", regex2)
        if !identityStringPredicate.evaluate(with: self) {
            return false
        }
        
        let idCardWi = [ "7", "9", "10", "5", "8", "4", "2", "1", "6", "3", "7", "9", "10", "5", "8", "4", "2" ] //将前17位加权因子保存在数组里
        let idCardY = [ "1", "0", "10", "9", "8", "7", "6", "5", "4", "3", "2" ] //这是除以11后，可能产生的11位余数、验证码，也保存成数组
        var idCardWiSum = 0
        for i in 0..<17 {
            let subStringIndex = self.substring(with: NSMakeRange(i, 1)).int!
            let idCardWithIndex = idCardWi[i].int!
            idCardWiSum += (subStringIndex * idCardWithIndex)
        }
        
        let idCardMod = idCardWiSum % 11
        let idCardLast:NSString = self.substring(with: NSMakeRange(17, 1)) as NSString
        if idCardMod == 2 {
            if !idCardLast.isEqual(to: "X") || idCardLast.isEqual(to: "x") {
                return false
            }
        } else {
            if !idCardLast.isEqual(to: idCardY[idCardMod]) {
                return false
            }
        }
        return true
    }
    
    //MARK: 从身份证上获取生日
    ///从身份证上获取生日
    func birthdayFromIdentityCard() -> NSString {
        let result = NSMutableString(capacity: 0)
        var year:NSString = ""
        var month:NSString = ""
        var day:NSString = ""
        if isValidateIdentity() {
            year = self.substring(with: NSMakeRange(6, 4)) as NSString
            month = self.substring(with: NSMakeRange(10, 2)) as NSString
            day = self.substring(with: NSMakeRange(12, 2)) as NSString
            
            result.append(year as String)
            result.append("-")
            result.append(month as String)
            result.append("-")
            result.append(day as String)
            return result
        } else {
            return "1970-01-01"
        }
    }
    
    //MARK: 从身份证上获取年龄
    ///从身份证上获取年龄
    func getIdentityCardAge() -> NSString {
        if isValidateIdentity() {
            let formatterTow = DateFormatter()
            formatterTow.dateFormat = "yyyy-MM-dd"
            let birthday = birthdayFromIdentityCard()
            let bsyDate = formatterTow.date(from: birthday as String)
            let dateDiff = bsyDate!.timeIntervalSinceNow
            let age = trunc(dateDiff / (60 * 60 * 24)) / 365
            return "\(-age)" as NSString
        } else {
            return "99999"
        }
    }
    
    //MARK: 獲取字符串中文件名的格式(媒體)
    ///獲取字符串中文件名的格式(媒體)
    @objc func contentTypeForUrl() -> PTUrlStringVideoType {
        let pathEX = pathExtension.lowercased()
        
        if pathEX.contains("mp4") {
            return .MP4
        } else if pathEX.contains("mov") {
            return .MOV
        } else if pathEX.contains("3gp") {
            return .ThreeGP
        }
        return .UNKNOW
    }
    
    @objc func checkWithString(expression:NSString) -> Bool {
        String(format: "%@", self).checkWithString(expression: String(format: "%@", expression))
    }
    
    @objc func checkWithArray(expression:NSArray) -> Bool {
        String(format: "%@", self).checkWithArray(expression: expression)
    }
    
    //MARK: 檢測字符串是否為空
    ///檢測字符串是否為空
    /// - Returns: Bool
    @objc func stringIsEmpty() -> Bool {
        if let string = self as String?, !string.isEmpty {
            return false
        }
        return true
    }
    
    @objc class func currentDate(dateFormatter:NSString) -> NSString {
        String.currentDate(dateFormatterString: dateFormatter as String).nsString
    }
    
    //MARK: 查找某字符在字符串的位置
    func rangeOfSubString(subStr:NSString) -> [String] {
        var rangeArray = [String]()
        for i in 0..<self.length {
            let temp:NSString = self.substring(with: NSMakeRange(i, subStr.length)) as NSString
            if temp.isEqual(to: subStr as String) {
                let range = NSRange(location: i, length: subStr.length)
                rangeArray.append(NSStringFromRange(range))
            }
        }
        return rangeArray
    }
}

/*
 富文本文字處理
 */
let kWPAttributedMarkupLinkName = "PTAttributedMarkupLinkName"
public extension NSString {
    func setText(color:UIColor,range:NSRange,onAttributedString:NSMutableAttributedString) {
        onAttributedString.removeAttribute(NSAttributedString.Key.foregroundColor, range: range)
        onAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
    }
    
    func setTextStyle(styleName:NSString,value:Any,range:NSRange,onAttributedString:NSMutableAttributedString) {
        onAttributedString.removeAttribute(styleName as NSAttributedString.Key, range: range)
        onAttributedString.addAttribute(styleName as NSAttributedString.Key, value: value, range: range)
    }
    
    func setLink(url:NSURL,range:NSRange,onAttributedString:NSMutableAttributedString) {
        onAttributedString.removeAttribute(NSAttributedString.Key(rawValue: kWPAttributedMarkupLinkName), range: range)
        onAttributedString.addAttribute(NSAttributedString.Key(rawValue: kWPAttributedMarkupLinkName), value: url.absoluteString!, range: range)
    }
    
    func setFont(fontName:NSString,size:CGFloat,range:NSRange,onAttributedString:NSMutableAttributedString) {
        let aFont = CTFontCreateWithName(fontName, size, nil)
        onAttributedString.removeAttribute(kCTFontAttributeName as NSAttributedString.Key, range: range)
        onAttributedString.addAttribute(kCTFontAttributeName as NSAttributedString.Key, value: aFont, range: range)
    }
    
    func setFont(font:UIFont,range:NSRange,onAttributedString:NSMutableAttributedString) {
        self.setFont(fontName: font.fontName.nsString, size: font.pointSize, range: range, onAttributedString: onAttributedString)
    }
    
    func setStyle(style:NSDictionary,range:NSRange,onAttributedString:NSMutableAttributedString) {
        for key in style.allKeys {
            let newKey = NSString(format: "%@", key as! CVarArg)
            if let value = style.value(forKey: newKey as String) {
                setTextStyle(styleName:newKey, value: value, range: range, onAttributedString: onAttributedString)
            }
        }
    }
    
    func style(attributedString:NSMutableAttributedString,range:NSRange,style:Any,styleBook:NSDictionary) {
        switch style {
        case let array as [Any]:
            for subStyle in array {
                self.style(attributedString: attributedString, range: range, style: subStyle, styleBook: styleBook)
            }
        case let dict as [AnyHashable: Any]:
            setStyle(style: dict as NSDictionary, range: range, onAttributedString: attributedString)
        case let font as UIFont:
            setFont(font: font, range: range, onAttributedString: attributedString)
        case let color as UIColor:
            setText(color: color, range: range, onAttributedString: attributedString)
        case let url as NSURL:
            setLink(url: url, range: range, onAttributedString: attributedString)
        case let string as NSString:
            self.style(attributedString: attributedString, range: range, style: string, styleBook: styleBook)
        case let image as UIImage:
            let attachment = NSTextAttachment()
            attachment.image = image
            attributedString.replaceCharacters(in: range, with: NSAttributedString(attachment: attachment))
        default:
            break // 或記錄錯誤、log unsupported type
        }
    }
    
    func attributedString(fontBook:NSDictionary) -> NSAttributedString {
        let tags = [NSDictionary]()
        let ms:NSMutableString = mutableCopy() as! NSMutableString
        ms.replaceOccurrences(of: "<br>", with: "\n",options: .caseInsensitive, range: NSMakeRange(0, ms.length))
        ms.replaceOccurrences(of: "<br />", with: "\n",options: .caseInsensitive, range: NSMakeRange(0, ms.length))
        ms.replaceAllTags(intoArray:tags as! NSMutableArray)
        
        let attributedString = NSMutableAttributedString(string: ms as String)
        attributedString.setAttributes([.underlineStyle:[NSNumber(integerLiteral: 0)]], range: NSMakeRange(0, attributedString.length))
        
        if let bodyStyle = fontBook["body"] {
            style(attributedString: attributedString, range: NSMakeRange(0, attributedString.length), style: bodyStyle, styleBook: fontBook)
        }
        
        for tag in tags {
            if let t = tag["tag"] as? NSString,let loc = tag["loc"] as? NSNumber,let endloc = tag["endloc"] as? NSNumber,let style = fontBook[t] {
                let range = NSMakeRange(loc.intValue, endloc.intValue - loc.intValue)
                self.style(attributedString: attributedString, range: range, style: style, styleBook: fontBook)
            }
        }
        return attributedString
    }
}
