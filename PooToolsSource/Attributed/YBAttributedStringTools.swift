//
//  YBAttributedStringTools.swift
//  MinaTicket
//
//  Created by 林勇彬 on 2022/6/8.
//  Copyright © 2022 Hola. All rights reserved.
//

import Foundation
import UIKit

fileprivate var ChangeStrKey = "getChangeStr"

public extension NSMutableAttributedString {
    
    private func changeStr() -> String {
        return (objc_getAssociatedObject(self, &ChangeStrKey) as? String) ?? ""
    }
    
    private func changeStr(changeStr:String) {
        objc_setAssociatedObject(self, &ChangeStrKey, changeStr, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// 设置段落属性
    /// - Parameters:
    ///   - lineSpacing: 行距
    ///   - paragraphSpacing: 段落距
    ///   - alignment: 对其方式
    ///   - lineBreakMode: 内容显示不完全时的省略方式
    /// - Returns: 本身
    @discardableResult func yb_paragraphStyle(lineSpacing: CGFloat = 0,paragraphSpacing:CGFloat = 0,alignment:NSTextAlignment = .left,lineBreakMode: NSLineBreakMode = .byTruncatingTail) -> Self {
       self.getParagraphStyle(range: NSMakeRange(0, self.string.count)) { paragraphStyle,range in
           paragraphStyle.lineSpacing = lineSpacing
           paragraphStyle.paragraphSpacing = paragraphSpacing
           paragraphStyle.alignment = alignment
           paragraphStyle.lineBreakMode = lineBreakMode
           self.addAttributes([NSAttributedString.Key.paragraphStyle:paragraphStyle], range: range)
       }
       return self
   }
    
    @discardableResult func yb_lineSpacing(spacing: CGFloat) -> Self {
        self.getParagraphStyle(range: NSMakeRange(0, self.string.count)) { paragraphStyle,range in
            paragraphStyle.lineSpacing = spacing
            self.addAttributes([NSAttributedString.Key.paragraphStyle:paragraphStyle], range: range)
        }
        return self
    }
    
    /// 设置对齐方式
    /// - Parameter alignment: 对齐方式
    /// - Returns: 本身
    @discardableResult func yb_alignment(alignment:NSTextAlignment) -> Self {
        self.getParagraphStyle(range: NSMakeRange(0, self.string.count)) { paragraphStyle,range in
            paragraphStyle.alignment = alignment
            self.addAttributes([NSAttributedString.Key.paragraphStyle:paragraphStyle], range: range)
        }
        return self
    }
    
    /// 设置字符间距
    /// - Parameter spacing: 间距
    /// - Returns: 本身
    @discardableResult func yb_kern(spacing: CGFloat) -> Self {
        self.addAttributes([NSAttributedString.Key.kern:spacing], range: NSMakeRange(0, self.string.count))
        return self
    }
    
    /// 设置删除线
    /// - Parameters:
    ///   - changeStr: 需要修改的文字
    ///   - style: 删除线的样式
    /// - Returns: 本身
    @discardableResult func yb_strikethrough(changeStr: String? = nil,style: NSUnderlineStyle = .single) -> Self {
        let changeString = changeStr ?? self.changeStr()
        self.changeStr(changeStr: changeString)
        self.addAttribute(NSAttributedString.Key.strikethroughStyle, value: style.rawValue, range: (self.string as NSString).range(of: changeString))
        return self
    }
    
    /// 设置下划线
    /// - Parameters:
    ///   - changeStr: 需要修改的文字
    ///   - style: 删除线的样式
    /// - Returns: 本身
    @discardableResult func yb_underline(changeStr: String? = nil,style: NSUnderlineStyle = .single) -> Self {
        let changeString = changeStr ?? self.changeStr()
        self.changeStr(changeStr: changeString)
        self.addAttribute(NSAttributedString.Key.underlineStyle, value: style.rawValue, range: (self.string as NSString).range(of: changeString))
        return self
    }
    
    
    /// 设置字体描边
    /// - Parameters:
    ///   - changeStr: 需要修改的文字
    ///   - color: 描边颜色
    ///   - value: 描边大小
    /// - Returns: 本身
    @discardableResult func yb_stroke(changeStr: String? = nil,color: UIColor, value: CGFloat = 0) -> Self {
        let changeString = changeStr ?? self.changeStr()
        self.changeStr(changeStr: changeString)
        self.addAttributes([NSAttributedString.Key.strokeColor: color,
                            NSAttributedString.Key.strokeWidth: value], range: (self.string as NSString).range(of: changeString))
        return self
    }
    
    @discardableResult func yb_font(font:UIFont,changeStr:String? = nil) -> Self {
        let changeString = changeStr ?? self.changeStr()
        self.changeStr(changeStr: changeString)
        self.addAttribute(NSAttributedString.Key.font, value: font, range: (self.string as NSString).range(of: changeString))
        return self
    }
    
    @discardableResult func yb_color(color:UIColor,changeStr:String? = nil) -> Self {
        let changeString = changeStr ?? self.changeStr()
        self.changeStr(changeStr: changeString)
        self.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: (self.string as NSString).range(of: changeString))
        return self
    }
    
    @discardableResult func yb_mutableColor(color:UIColor,changeStr:String? = nil) -> Self {
        let changeString = changeStr ?? self.changeStr()
        self.changeStr(changeStr: changeString)
        
        var replaceString = ""
        for _ in changeString {
            replaceString.append(" ")
        }
        var copyTotalString = self.string
        while copyTotalString.contains(changeString) {
            guard let range = copyTotalString.range(of: changeString, options: .caseInsensitive) else { return self}
            self.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(range,in:changeString))
            copyTotalString = copyTotalString.replacingCharacters(in: range, with: replaceString)
        }
        return self
    }
    
    @discardableResult func yb_mutableFont(font:UIFont,changeStr:String? = nil) -> Self {
        let changeString = changeStr ?? self.changeStr()
        self.changeStr(changeStr: changeString)
        
        var replaceString = ""
        for _ in changeString {
            replaceString.append(" ")
        }
        var copyTotalString = self.string
        while copyTotalString.contains(changeString) {
            guard let range = copyTotalString.range(of: changeString, options: .caseInsensitive) else { return self}
            self.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(range,in:changeString))
            copyTotalString = copyTotalString.replacingCharacters(in: range, with: replaceString)
        }
        return self
    }
    
    func getParagraphStyle(range:NSRange, reslut:((NSMutableParagraphStyle,NSRange)->())) {
        self.enumerateAttribute(NSAttributedString.Key.paragraphStyle, in: range, options: NSAttributedString.EnumerationOptions.init(rawValue: 0)) { value, subRange, stop in
            var style:NSMutableParagraphStyle?
            if (value != nil) {
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                }else {
                    style = NSMutableParagraphStyle()
                }
            }else {
                style = NSMutableParagraphStyle()
            }
            reslut(style ?? NSMutableParagraphStyle(),range)
        }
    }
}

public extension UILabel {
    @discardableResult func yb_text(text:String?) -> Self {
        self.text = text
        return self
    }
    
    @discardableResult func yb_color(color:UIColor) -> Self {
        self.textColor = color
        return self
    }
    
    @discardableResult func yb_font(font:CGFloat) -> Self {
        self.font = UIFont.systemFont(ofSize: font)
        return self
    }
    
    @discardableResult func yb_blodFont(blodFont:CGFloat) -> Self {
        self.font = UIFont.boldSystemFont(ofSize: blodFont)
        return self
    }
    
    @discardableResult func yb_alignment(alignment:NSTextAlignment) -> Self {
        self.textAlignment = alignment
        return self
    }
    
    @discardableResult func yb_attribute(text:String? = nil) -> NSMutableAttributedString {
        let subText = text ?? (self.text ?? "")
        let attriString = NSMutableAttributedString(string: subText)
        return attriString
    }
}
