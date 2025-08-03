//
//  UIFont+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

//MARK: 全局统一字体
public extension UIFont {
    @objc class func appfont(size:CGFloat,
                             bold:Bool = false,
                             scale:Bool = false) -> UIFont {
        var setFont:UIFont
        if !bold {
            setFont = UIFont.systemFont(ofSize: size)
        } else {
            setFont = UIFont.boldSystemFont(ofSize: size)
        }
        
        if scale {
            setFont = setFont.adapter
        }
        return setFont
    }
        
    @objc class func appCustomFont(size:CGFloat,
                                   customFont:String = "",
                                   scale:Bool = false) -> UIFont {
        
        if customFont.stringIsEmpty() {
            fatalError("自定義需要有字體名字")
        } else {
            if let setFont = UIFont(name: customFont, size: size) {
                if scale {
                    return setFont.adapter
                }
                return setFont
            } else {
                fatalError("無法讀取該字體")
            }
        }
    }
        
    @objc class func systemFont(ofSize size: CGFloat, 
                                weight: UIFont.Weight,
                                design: UIFontDescriptor.SystemDesign,
                                scale:Bool = false) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).addingAttributes([UIFontDescriptor.AttributeName.traits : [UIFontDescriptor.TraitKey.weight : weight]]).withDesign(design)
        
        let setFont = UIFont(descriptor: descriptor!, size: size)
        return scale ? setFont.adapter : setFont
    }
    
    fileprivate class func text(_ ofSize: CGFloat, W Weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: ofSize, weight: Weight)
    }
    
    //MARK: 常规字体
    ///常规字体
    /// - Parameters:
    ///  - ofSize: 字体大小
    /// - Returns: 字体
    static func textRegular(_ ofSize: CGFloat) -> UIFont {
        text(ofSize, W: .regular)
    }
    
    //MARK: 中等的字体
    ///中等的字体
    /// - Parameters:
    ///  - ofSize: 字体大小
    /// - Returns: 字体
    static func textMedium(_ ofSize: CGFloat) -> UIFont {
        text(ofSize, W: .medium)
    }
    
    //MARK: 加粗的字体
    ///加粗的字体
    /// - Parameters:
    ///  - ofSize: 字体大小
    /// - Returns: 字体
    static func textBold(_ ofSize: CGFloat) -> UIFont {
        text(ofSize, W: .bold)
    }
    
    //MARK: 半粗体的字体
    ///半粗体的字体
    /// - Parameters:
    ///  - ofSize: 字体大小
    /// - Returns: 字体
    static func textSemibold(_ ofSize: CGFloat) -> UIFont {
        text(ofSize, W: .semibold)
    }
    
    //MARK: 超细的字体
    ///超细的字体
    /// - Parameters:
    ///  - ofSize: 字体大小
    /// - Returns: 字体
    static func textUltraLight(_ ofSize: CGFloat) -> UIFont {
        text(ofSize, W: .ultraLight)
    }
    
    //MARK: 纤细的字体
    ///纤细的字体
    /// - Parameters:
    ///  - ofSize: 字体大小
    /// - Returns: 字体
    static func textThin(_ ofSize: CGFloat) -> UIFont {
        text(ofSize, W: .thin)
    }
    
    //MARK: 亮字体
    ///亮字体
    /// - Parameters:
    ///  - ofSize: 字体大小
    /// - Returns: 字体
    static func textLight(_ ofSize: CGFloat) -> UIFont {
        text(ofSize, W: .light)
    }
    
    //MARK: 介于Bold和Black之间
    ///介于Bold和Black之间
    /// - Parameters:
    ///  - ofSize: 字体大小
    /// - Returns: 字体
    static func textHeavy(_ ofSize: CGFloat) -> UIFont {
        text(ofSize, W: .heavy)
    }
    
    //MARK: 最粗字体
    ///最粗字体
    /// - Parameters:
    ///  - ofSize: 字体大小
    /// - Returns: 字体
    static func textBlack(_ ofSize: CGFloat) -> UIFont {
        text(ofSize, W: .black)
    }

    // MARK: 查看所有字体的名字
    ///查看所有字体的名字
    static func showAllFont() {
        var i = 0
        for family in UIFont.familyNames {
            PTNSLogConsole("\(i)---项目字体---\(family)", levelType: PTLogMode,loggerType: .Font)
            for names in UIFont.fontNames(forFamilyName: family) {
                PTNSLogConsole("== \(names)", levelType: PTLogMode,loggerType: .Font)
            }
            i += 1
        }
    }
    
    var rounded: UIFont {
        if #available(iOS 13, tvOS 13, *) {
            guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
            return UIFont(descriptor: descriptor, size: 0)
        } else {
            return self
        }
    }
    
    var monospaced: UIFont {
        if #available(iOS 13, tvOS 13, *) {
            guard let descriptor = fontDescriptor.withDesign(.monospaced) else { return self }
            return UIFont(descriptor: descriptor, size: 0)
        } else {
            return self
        }
    }
    
    var serif: UIFont {
        if #available(iOS 13, tvOS 13, *) {
            guard let descriptor = fontDescriptor.withDesign(.serif) else { return self }
            return UIFont(descriptor: descriptor, size: 0)
        } else {
            return self
        }
    }
    
    static func preferredFont(forTextStyle style: TextStyle, 
                              addPoints: CGFloat = .zero) -> UIFont {
        let referensFont = UIFont.preferredFont(forTextStyle: style)
        return referensFont.withSize(referensFont.pointSize + addPoints)
    }

    static func preferredFont(forTextStyle style: TextStyle,
                              weight: Weight,
                              addPoints: CGFloat = .zero) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: descriptor.pointSize + addPoints, weight: weight)
        let metrics = UIFontMetrics(forTextStyle: style)
        return metrics.scaledFont(for: font)
    }
}

extension UIFont:PTNumberValueAdapterable {
    public typealias PTNumberValueAdapterType = UIFont
    public var adapter: UIFont {
        let adjustedSize = adapterScale() * self.pointSize
        return UIFont(descriptor: self.fontDescriptor, size: adjustedSize)
    }
}
