//
//  PTLanguage.swift
//  Diou
//
//Created by ken lam on 2021/6/30.
//Copyright © 2021 DO. All rights reserved.
//

import UIKit

/**
 工程配置
 1、Xcode》选择你的项目》PROJECT》info 》Localizations 》 添加要支持的语言
 2、新建Localizable.strings文件（Localizable固定值）
 3、选择Localizable.strings 》在Xcode右边的 Inspectors（Xcode右上角的按钮）》找到 Localizations 》 勾选需要的语言，此时Xcode会在你的Localizable.strings里面生成对应的文件。
 4、在对应的语言文件里添加
    "Home_follow" = "关注";
    ...
 5、使用BKLanguage类，管理语言的切换。
 */


/**
 PTLanguage 的使用方法
1、设置语言
 PTLanguage.share.language = "zh-Hans"
2、根据key获取语言包中对应的文本
 PTLanguage.text(forKey:"Home_follow")
3、监听语言切换
 1）、开发者可以监听 LanguageDidChangedKey，最后记得移除监听。
 2）、本文件扩展了 UIViewController，开发者也可以使用 pt_observerLangauge 来监听，使用 pt_removeObserverLangauge 来移除监听。
*/

func LocalizedString(_ key: String) -> String {
    PTLanguage.share.text(forKey: key)
}

// Noti Key: 语言已切换
let LanguageDidChangedKey = PTLanguage.didChangedKey

// MARK: - BKLanguage 语言切换管理类
public class PTLanguage: NSObject {
    public static let share = PTLanguage()
    
    fileprivate static let didChangedKey = NSNotification.Name("LanguageDidChanged")
    
    private let LanguageKey: String = "MyLanguage"
    
    public var language: String {
        get {
            if let lang = UserDefaults.standard.value(forKey: LanguageKey) as? String {
                return lang
            } else {
                // 默认的语言，可以根据需求来进行默认。zh-Hans.lproj
                return "zh-Hans"
            }
        }
        set {
            // 保存当前的语言
            UserDefaults.standard.set(newValue, forKey: LanguageKey)
            UserDefaults.standard.synchronize()
            // 发通知，语言已发生改变
            NotificationCenter.default.post(name: LanguageDidChangedKey, object: nil)
        }
    }
    
    public func text(forKey key: String) -> String {
        
        guard let path = Bundle.main.path(forResource: PTLanguage.share.language, ofType: "lproj"), let bundle = Bundle(path: path) else {
            
            // Base.lproj
            guard let path = Bundle.main.path(forResource: "Base", ofType: "lproj"), let bundle = Bundle(path: path) else {
                return ""
            }
            return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
        }
        
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
    }
}

// MARK: - 扩展UIViewController
/**
 1、增加方法快速监听语言切换
 2、增加方法快速移动监听
 */
public extension UIViewController {
    
    private static let key = "BLOCKL_KEY"
    private typealias ChangedBlock = () -> ()
    // 动态添加block属性
    private var block: ChangedBlock? {
        get {
            objc_getAssociatedObject(self, UIViewController.key) as? ChangedBlock
        }
        set {
            objc_setAssociatedObject(self, UIViewController.key, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }
    
    @objc private func notiLanguageChange(_ noti: Notification) {
        block?()
    }
    
    /// 监听切换语言
    func pt_observerLanguage(didChanged block: @escaping () -> ()) {
        
        self.block = block
        
        NotificationCenter.default.addObserver(self, selector: #selector(notiLanguageChange(_:)), name: LanguageDidChangedKey, object: nil)
    }
    
    /// 移除监听
    func pt_removeObserverLanguage() {
        NotificationCenter.default.removeObserver(self, name: LanguageDidChangedKey, object: self)
    }
}
