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
 5、使用PTLanguage类，管理语言的切换。
 */


/**
 PTLanguage 的使用方法
1、设置语言
 PTLanguage.share.language = "zh-Hans"
2、根据key获取语言包中对应的文本
 "Home_follow".localize
3、监听语言切换
 1）、开发者可以监听 LanguageDidChangedKey，最后记得移除监听。
 2）、本文件扩展了 UIViewController，开发者也可以使用 pt_observerLangauge 来监听，使用 pt_removeObserverLangauge 来移除监听。
*/

// MARK: - 1. 全局常量与配置
/// 默认语言
public let PTDefaultLanguage = "zh-Hans"
/// 语言切换的通知 Key
public let LanguageDidChangedKey = Notification.Name("LanguageDidChanged")
/// 语言切换回调闭包
public typealias ChangedBlock = () -> Void
public let PTBaseBundle = "Base"

// MARK: - 2. 核心语言管理类 (整合 PTLanguage 和 Localize)
public class PTLanguage: NSObject {
    public static let share = PTLanguage()
    /// 当前App语言，修改此属性会自动触发全App的UI刷新
    public var language: String {
        get {
            PTCoreUserDefultsWrapper.AppLanguage
        } set {
            let selectedLanguage = PTLanguage.availableLanguages().contains(newValue) ? newValue : PTLanguage.defaultLanguage()
            guard selectedLanguage != language else { return } // 如果语言没变，不发通知
            
            PTCoreUserDefultsWrapper.AppLanguage = selectedLanguage
            NotificationCenter.default.post(name: LanguageDidChangedKey, object: nil)
        }
    }
    
    /// 获取支持的语言列表
    public class func availableLanguages(_ excludeBase: Bool = false) -> [String] {
        var availableLanguages = Bundle.main.localizations
        if excludeBase, let indexOfBase = availableLanguages.firstIndex(of: "Base") {
            availableLanguages.remove(at: indexOfBase)
        }
        return availableLanguages
    }
    
    /// 获取默认语言
    public class func defaultLanguage() -> String {
        guard let preferredLanguage = Bundle.main.preferredLocalizations.first else {
            return PTDefaultLanguage
        }
        return availableLanguages().contains(preferredLanguage) ? preferredLanguage : PTDefaultLanguage
    }
    
    /// 获取某种语言的本地化显示名称 (例如在英文环境下显示 "English", 中文环境下显示 "英语")
    public class func displayNameForLanguage(_ language: String) -> String {
        let locale = Locale(identifier: PTLanguage.share.language)
        return locale.localizedString(forIdentifier: language) ?? ""
    }
}

public extension String {
    
    /// 【补全】核心的底层翻译方法
    func localized(tableName: String? = nil, bundle: Bundle?) -> String {
        let targetBundle = bundle ?? Bundle.main
        // 根据当前语言获取对应的语言包路径（.lproj）
        guard let path = targetBundle.path(forResource: PTLanguage.share.language, ofType: "lproj"),
              let langBundle = Bundle(path: path) else {
            // 找不到对应语言包则回退到原生翻译
            return NSLocalizedString(self, tableName: tableName, bundle: targetBundle, value: self, comment: "")
        }
        return NSLocalizedString(self, tableName: tableName, bundle: langBundle, value: self, comment: "")
    }

    /// 基础本地化
    func localized() -> String {
        return localized(tableName: nil, bundle: Bundle.podCoreBundle())
    }

    /// 带格式化参数的本地化
    func localizedFormat(_ arguments: CVarArg...) -> String {
        return String(format: localized(), arguments: arguments)
    }
    
    /// 复数形式的本地化
    func localizedPlural(_ argument: CVarArg) -> String {
        return String.localizedStringWithFormat(localized(), argument)
    }
}

public func Localized(_ string: String) -> String {
    return string.localized()
}

public func Localized(_ string: String, arguments: CVarArg...) -> String {
    return String(format: string.localized(), arguments: arguments)
}

public func LocalizedPlural(_ string: String, argument: CVarArg) -> String {
    return string.localizedPlural(argument)
}

// MARK: - 5. UIViewController & UIView 扩展 (UI 监听优化)

// 定义规范的 Runtime Keys
private struct AssociatedKeys {
    static var vcBlockKey: UInt8 = 0
    static var viewBlockKey: UInt8 = 0
}

public extension UIViewController {
    // 【修复】改用 as? 安全解包
    private var block: ChangedBlock? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.vcBlockKey) as? ChangedBlock }
        set { objc_setAssociatedObject(self, &AssociatedKeys.vcBlockKey, newValue, .OBJC_ASSOCIATION_COPY) }
    }
    
    @objc private func notiLanguageChange(_ noti: Notification) {
        block?()
    }
    
    /// 监听切换语言
    func pt_observerLanguage(didChanged block: ChangedBlock?) {
        NotificationCenter.default.addObserver(self, selector: #selector(notiLanguageChange(_:)), name: LanguageDidChangedKey, object: nil)
        self.block = block
        // 建议：添加监听时立即执行一次，确保初始 UI 加载正确
        block?()
    }
    
    /// 移除监听
    func pt_removeObserverLanguage() {
        // 【修复】将 object: self 改为 object: nil
        NotificationCenter.default.removeObserver(self, name: LanguageDidChangedKey, object: nil)
    }
}

public extension UIView {
    private var block: ChangedBlock? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.viewBlockKey) as? ChangedBlock }
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewBlockKey, newValue, .OBJC_ASSOCIATION_COPY) }
    }
    
    @objc private func notiLanguageChange(_ noti: Notification) {
        block?()
    }
    
    /// 监听切换语言
    func pt_viewObserverLanguage(didChanged block: ChangedBlock?) {
        NotificationCenter.default.addObserver(self, selector: #selector(notiLanguageChange(_:)), name: LanguageDidChangedKey, object: nil)
        self.block = block
        block?()
    }
    
    /// 移除监听
    func pt_removeObserverLanguage() {
        NotificationCenter.default.removeObserver(self, name: LanguageDidChangedKey, object: nil)
    }
}
