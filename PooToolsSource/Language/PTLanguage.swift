//
//  PTLanguage.swift
//  Diou
//
//Created by ken lam on 2021/6/30.
//Copyright © 2021 DO. All rights reserved.
//

import Foundation
import os.lock
import UIKit

/**
 English: Add languages in the target's Localization settings. Use either a legacy
 Localizable.strings table or an Xcode String Catalog (Localizable.xcstrings), then
 use PTLanguage to manage the runtime language selection.
 Español: Añade los idiomas en la configuración de Localization del target. Puedes usar
 una tabla Localizable.strings antigua o un catálogo de cadenas de Xcode
 (Localizable.xcstrings), y después usar PTLanguage para seleccionar el idioma.
 中文：在 target 的 Localization 设置中添加语言。可以继续使用旧版
 Localizable.strings，也可以使用 Xcode 的 String Catalog（Localizable.xcstrings），
 然后通过 PTLanguage 管理运行时语言切换。
 */


/**
 PTLanguage 的使用方法
1、设置语言
 PTLanguage.share.language = "zh-Hans"
2、根据 key 获取语言包中对应的文本
 "PT Button cancel".localized()
3、监听语言切换
 1）、开发者可以监听 LanguageDidChangedKey，最后记得移除监听。
  2）、本文件扩展了 UIViewController，开发者也可以使用 pt_observerLanguage 来监听，使用 pt_removeObserverLanguage 来移除监听。
*/

// MARK: - 1. 全局常量与配置
/// 默认语言
public let PTDefaultLanguage = "zh-Hans"
/// 语言切换的通知 Key
public let LanguageDidChangedKey = Notification.Name("LanguageDidChanged")
/// 语言切换回调闭包
public typealias ChangedBlock = () -> Void
public let PTBaseBundle = "Base"

public enum PTLocale: String, CaseIterable, Sendable {

    // MARK: - 亚洲语言
    case zh_Hans = "zh-Hans"            // 简体中文
    case zh_Hant = "zh-Hant"            // 繁体中文
    case zh_HK = "zh-HK"                // 香港繁体中文
    case ja = "ja"                      // 日语
    case ko = "ko"                      // 韩语
    case th = "th"                      // 泰语
    case vi = "vi"                      // 越南语
    case id = "id"                      // 印尼语
    case ms = "ms"                      // 马来语
    case fil = "fil"                    // 菲律宾语
    case hi = "hi"                      // 印地语
    case bn = "bn"                      // 孟加拉语
    case pa = "pa"                      // 旁遮普语
    case ur = "ur"                      // 乌尔都语
    
    // MARK: - 欧洲语言 (西欧/北欧)
    case en = "en"                      // 英语
    case fr = "fr"                      // 法语
    case de = "de"                      // 德语
    case es = "es"                      // 西班牙语
    case pt = "pt"                      // 葡萄牙语
    case it = "it"                      // 意大利语
    case nl = "nl"                      // 荷兰语
    case sv = "sv"                      // 瑞典语
    case da = "da"                      // 丹麦语
    case no = "no"                      // 挪威语
    case fi = "fi"                      // 芬兰语
    case gsw = "gsw"                    // 瑞士德语
    
    // MARK: - 欧洲语言 (东欧/中欧/俄语区)
    case ru = "ru"                      // 俄语
    case uk = "uk"                      // 乌克兰语
    case be = "be"                      // 白俄罗斯语
    case pl = "pl"                      // 波兰语
    case cs = "cs"                      // 捷克语
    case sk = "sk"                      // 斯洛伐克语
    case hu = "hu"                      // 匈牙利语
    case ro = "ro"                      // 罗马尼亚语
    case bg = "bg"                      // 保加利亚语
    case sr = "sr"                      // 塞尔维亚语
    case hr = "hr"                      // 克罗地亚语
    case el = "el"                      // 希腊语
    
    // MARK: - 中东及非洲语言
    case ar = "ar"                      // 阿拉伯语
    case fa = "fa"                      // 波斯语
    case tr = "tr"                      // 土耳其语
    case he = "he"                      // 希伯来语
    case hy = "hy"                      // 亚美尼亚语
    case sw = "sw"                      // 斯瓦希里语

    /// 唯一标识符
    public var identifier: String { rawValue }
    
    /// 苹果使用的语言代码
    public var languageCode: String { rawValue }
    
    /// 获取当前 App 或系统的默认语言
    public static var current: PTLocale {
        let available = allCases.map(\.rawValue)
        let matchedLanguage = Bundle.preferredLocalizations(from: available,
                                                             forPreferences: Locale.preferredLanguages).first
        return matchedLanguage.flatMap(PTLocale.init(rawValue:)) ?? .en
    }

    /// 获取该语言的本地化描述 (例如在当前环境下返回 "English" 或 "英语")
    @available(iOS 11.0, tvOS 11.0, macOS 10.11, *)
    public func description(in locale: PTLocale) -> String {
        let displayLocale = Locale(identifier: locale.languageCode)
        let text = displayLocale.localizedString(forIdentifier: languageCode) ?? languageCode
        return text.localizedCapitalized
    }
}

private final class PTLanguageBundleToken: NSObject {}

// MARK: - 2. 本地化解析器
private enum PTLocalizationResolver {
    static let coreBundle: Bundle = {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        let frameworkBundle = Bundle(for: PTLanguageBundleToken.self)
        let candidateBundles = [frameworkBundle, Bundle.main]
        for bundle in candidateBundles {
            if let resourceURL = bundle.url(forResource: CorePodBundleName, withExtension: "bundle"),
               let resourceBundle = Bundle(url: resourceURL) {
                return resourceBundle
            }
        }
        return frameworkBundle
#endif
    }()

    static let coreLanguageBundles: [String: Bundle] = {
        var result = [String: Bundle]()
        for identifier in coreBundle.localizations {
            guard let path = coreBundle.path(forResource: identifier, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                continue
            }
            result[normalized(identifier)] = bundle
        }
        return result
    }()

    static func availableLanguages(excludeBase: Bool) -> [String] {
        var result = [String]()
        var seen = Set<String>()
        let bundles = [Bundle.main, coreBundle]

        for bundle in bundles {
            for identifier in bundle.localizations {
                let normalizedIdentifier = normalized(identifier)
                guard !normalizedIdentifier.isEmpty,
                      !(excludeBase && isBase(normalizedIdentifier)),
                      seen.insert(normalizedIdentifier).inserted else {
                    continue
                }
                result.append(normalizedIdentifier)
            }
        }
        return result
    }

    static func normalized(_ identifier: String) -> String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
    }

    static func matchingLanguage(_ requested: String, available: [String]) -> String? {
        let normalizedRequested = normalized(requested)
        guard !normalizedRequested.isEmpty else { return nil }

        if let exactMatch = available.first(where: { normalized($0) == normalizedRequested }) {
            return normalized(exactMatch)
        }

        guard let requestedLanguageCode = languageCode(for: normalizedRequested) else {
            return nil
        }

        let preferred = Bundle.preferredLocalizations(from: available,
                                                       forPreferences: [normalizedRequested])
        return preferred.first(where: {
            languageCode(for: normalized($0)) == requestedLanguageCode
        }).map(normalized)
    }

    static func fallbackLanguage(available: [String]) -> String {
        if let defaultLanguage = matchingLanguage(PTDefaultLanguage, available: available) {
            return defaultLanguage
        }
        if let developmentLanguage = Bundle.main.developmentLocalization,
           let matchedDevelopmentLanguage = matchingLanguage(developmentLanguage, available: available) {
            return matchedDevelopmentLanguage
        }
        if let english = matchingLanguage("en", available: available) {
            return english
        }
        return normalized(available.first ?? PTDefaultLanguage)
    }

    static func localized(key: String,
                          tableName: String?,
                          bundle: Bundle,
                          language: String) -> String {
        let normalizedTableName = tableName.flatMap { tableName in
            let trimmedTableName = tableName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedTableName.isEmpty ? nil : trimmedTableName
        }

        // English: A caller may still pass a concrete .lproj bundle. Keep that legacy path intact.
        // Español: Un caller todavía puede pasar un bundle .lproj concreto; conserva esa ruta.
        // 中文：调用方可能仍会传入具体的 .lproj bundle，这里保留旧路径。
        if bundle.bundleURL.pathExtension.caseInsensitiveCompare("lproj") == .orderedSame {
            return bundle.localizedString(forKey: key,
                                          value: key,
                                          table: normalizedTableName)
        }

        // English: Let Foundation resolve compiled String Catalogs and legacy string tables.
        // Español: Deja que Foundation resuelva los catálogos compilados y las tablas antiguas.
        // 中文：交给 Foundation 解析编译后的 String Catalog 和旧版字符串表。
        let resource = LocalizedStringResource(
            String.LocalizationValue(key),
            table: normalizedTableName,
            locale: Locale(identifier: language),
            bundle: .atURL(bundle.bundleURL),
            comment: ""
        )
        let catalogValue = String(localized: resource)

        // English: Fall back only when a legacy table has the value but the catalog lookup does not.
        // Español: Usa la tabla antigua solo cuando contiene el valor y el catálogo no lo encuentra.
        // 中文：仅当旧字符串表存在值而 Catalog 没有解析到时，才回退到旧路径。
        if catalogValue == key {
            let localizedBundle = languageBundle(for: language, in: bundle)
            let legacyValue = localizedBundle.localizedString(forKey: key,
                                                              value: key,
                                                              table: normalizedTableName)
            if legacyValue != key {
                return legacyValue
            }
        }
        return catalogValue
    }

    private static func languageBundle(for language: String, in bundle: Bundle) -> Bundle {
        let normalizedLanguage = normalized(language)
        if bundle === coreBundle,
           let cachedBundle = coreLanguageBundles[normalizedLanguage] {
            return cachedBundle
        }

        let available = bundle.localizations
        if let matchedLanguage = matchingLanguage(normalizedLanguage, available: available),
           let matchedBundle = bundleForLocalization(matchedLanguage, in: bundle) {
            return matchedBundle
        }
        if let baseBundle = bundleForLocalization(PTBaseBundle, in: bundle) {
            return baseBundle
        }
        if let developmentLanguage = bundle.developmentLocalization,
           let developmentBundle = bundleForLocalization(developmentLanguage, in: bundle) {
            return developmentBundle
        }
        return bundle
    }

    private static func bundleForLocalization(_ identifier: String, in bundle: Bundle) -> Bundle? {
        let resourceIdentifier = bundle.localizations.first {
            normalized($0) == normalized(identifier)
        } ?? identifier
        guard let path = bundle.path(forResource: resourceIdentifier, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }

    private static func languageCode(for identifier: String) -> String? {
        Locale(identifier: identifier).language.languageCode?.identifier.lowercased()
    }

    private static func isBase(_ identifier: String) -> Bool {
        normalized(identifier).caseInsensitiveCompare(PTBaseBundle) == .orderedSame
    }
}

// MARK: - 3. 核心语言管理类
public final class PTLanguage: NSObject, Sendable {
    public static let share = PTLanguage()
    private static let languageLock = OSAllocatedUnfairLock<Void>(initialState: ())

    /// 当前App语言，修改此属性会自动触发全App的UI刷新
    public var language: String {
        get {
            Self.languageLock.withLock {
                let storedLanguage = PTCoreUserDefultsWrapper.shared.AppLanguage
                let selectedLanguage = Self.resolvedLanguage(for: storedLanguage)
                if storedLanguage != selectedLanguage {
                    PTCoreUserDefultsWrapper.shared.AppLanguage = selectedLanguage
                }
                return selectedLanguage
            }
        } set {
            let selectedLanguage = Self.resolvedLanguage(for: newValue)
            let didChange = Self.languageLock.withLock {
                let storedLanguage = PTCoreUserDefultsWrapper.shared.AppLanguage
                let currentLanguage = Self.resolvedLanguage(for: storedLanguage)
                if storedLanguage != currentLanguage {
                    PTCoreUserDefultsWrapper.shared.AppLanguage = currentLanguage
                }
                guard selectedLanguage != currentLanguage else { return false }

                PTCoreUserDefultsWrapper.shared.AppLanguage = selectedLanguage
                return true
            }
            if didChange {
                Self.postLanguageDidChange()
            }
        }
    }

    /// 当前选中语言对应的 Locale。
    public var locale: Locale {
        Locale(identifier: language)
    }

    /// 使用类型安全的语言枚举切换语言。
    public func setLanguage(_ locale: PTLocale) {
        language = locale.rawValue
    }
    
    /// 获取支持的语言列表
    public class func availableLanguages(_ excludeBase: Bool = false) -> [String] {
        PTLocalizationResolver.availableLanguages(excludeBase: excludeBase)
    }
    
    /// 获取默认语言
    public class func defaultLanguage() -> String {
        resolvedLanguage(for: PTDefaultLanguage)
    }
    
    /// 获取某种语言的本地化显示名称 (例如在英文环境下显示 "English", 中文环境下显示 "英语")
    public class func displayNameForLanguage(_ language: String) -> String {
        let locale = Locale(identifier: PTLanguage.share.language)
        let identifier = PTLocalizationResolver.normalized(language)
        return locale.localizedString(forIdentifier: identifier) ?? identifier
    }

    private class func resolvedLanguage(for identifier: String) -> String {
        let availableLanguages = availableLanguages(true)
        return PTLocalizationResolver.matchingLanguage(identifier,
                                                        available: availableLanguages)
            ?? PTLocalizationResolver.fallbackLanguage(available: availableLanguages)
    }

    private static func postLanguageDidChange() {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: LanguageDidChangedKey, object: nil)
        } else {
            Task { @MainActor in
                guard !Task.isCancelled else { return }
                NotificationCenter.default.post(name: LanguageDidChangedKey, object: nil)
            }
        }
    }
}

public extension String {
    
    /// 核心的底层翻译方法。
    func localized(tableName: String? = nil, bundle: Bundle?) -> String {
        let targetBundle = bundle ?? Bundle.main
        return PTLocalizationResolver.localized(key: self,
                                                tableName: tableName,
                                                bundle: targetBundle,
                                                language: PTLanguage.share.language)
    }

    /// 基础本地化
    func localized() -> String {
        localized(tableName: nil, bundle: PTLocalizationResolver.coreBundle)
    }

    /// 带格式化参数的本地化
    func localizedFormat(_ arguments: CVarArg...) -> String {
        String(format: localized(), locale: PTLanguage.share.locale, arguments: arguments)
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
    return String(format: string.localized(), locale: PTLanguage.share.locale, arguments: arguments)
}

public func LocalizedPlural(_ string: String, argument: CVarArg) -> String {
    return string.localizedPlural(argument)
}

// MARK: - 5. UIViewController & UIView 扩展 (UI 监听优化)

// English: Keep language observation state independent from the observed UIKit object.
// Español: Mantén el estado de observación del idioma independiente del objeto UIKit observado.
// 中文：让语言监听状态独立于被监听的 UIKit 对象。
@MainActor
private enum AssociatedKeys {
    static var vcLanguageObservationKey: UInt8 = 0
    static var viewLanguageObservationKey: UInt8 = 0
}

// English: A block observer keeps its own token so unrelated removeObserver(self) calls cannot remove it.
// Español: El observador de bloque conserva su propio token para que removeObserver(self) no lo elimine por accidente.
// 中文：块观察者保存独立 token，避免无关的 removeObserver(self) 调用误删语言监听。
@MainActor
private final class PTLanguageChangeObservation: NSObject {
    private let action: ChangedBlock
    private var token: NSObjectProtocol?

    init(action: @escaping ChangedBlock) {
        self.action = action
        super.init()
    }

    deinit {
        MainActor.gcdRunUnsafely({
            if let token {
                NotificationCenter.default.removeObserver(token)
            }
        })
    }

    func start() {
        guard token == nil else { return }
        token = NotificationCenter.default.addObserver(forName: LanguageDidChangedKey,
                                                       object: nil,
                                                       queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.action()
            }
        }
    }

    func stop() {
        guard let token else { return }
        NotificationCenter.default.removeObserver(token)
        self.token = nil
    }
}

public extension UIViewController {
    private var languageChangeObservation: PTLanguageChangeObservation? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.vcLanguageObservationKey) as? PTLanguageChangeObservation }
        set { objc_setAssociatedObject(self, &AssociatedKeys.vcLanguageObservationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// 监听切换语言
    func pt_observerLanguage(didChanged block: ChangedBlock?) {
        languageChangeObservation?.stop()
        languageChangeObservation = nil
        guard let block else { return }

        let observation = PTLanguageChangeObservation(action: block)
        languageChangeObservation = observation
        observation.start()
        block()
    }

    /// 移除监听
    func pt_removeObserverLanguage() {
        languageChangeObservation?.stop()
        languageChangeObservation = nil
    }
}

public extension UIView {
    private var languageChangeObservation: PTLanguageChangeObservation? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.viewLanguageObservationKey) as? PTLanguageChangeObservation }
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewLanguageObservationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// 监听切换语言
    func pt_viewObserverLanguage(didChanged block: ChangedBlock?) {
        languageChangeObservation?.stop()
        languageChangeObservation = nil
        guard let block else { return }

        let observation = PTLanguageChangeObservation(action: block)
        languageChangeObservation = observation
        observation.start()
        block()
    }

    /// 移除监听
    func pt_removeObserverLanguage() {
        languageChangeObservation?.stop()
        languageChangeObservation = nil
    }
}

/**
    Localized
 */
public extension String {
    /**
     Swift 2 friendly localization syntax, replaces NSLocalizedString.
     
     - parameter bundle: The receiver’s bundle to search. If bundle is `nil`,
     the method attempts to use main bundle.
     
     - returns: The localized string.
     */
    func localized(in bundle: Bundle?) -> String {
        localized(using: nil, in: bundle)
    }
    
    /**
     Swift 2 friendly localization syntax with format arguments, replaces String(format:NSLocalizedString).
     
     - parameter arguments: arguments values for temlpate (substituted according to the user’s default locale).
     
     - parameter bundle: The receiver’s bundle to search. If bundle is `nil`,
     the method attempts to use main bundle.
     
     - returns: The formatted localized string with arguments.
     */
    func localizedFormat(arguments: CVarArg..., in bundle: Bundle?) -> String {
        String(format: localized(in: bundle),
               locale: PTLanguage.share.locale,
               arguments: arguments)
    }
    
    /**
     Swift 2 friendly plural localization syntax with a format argument.
     
     - parameter argument: Argument to determine pluralisation.
     
     - parameter bundle: The receiver’s bundle to search. If bundle is `nil`,
     the method attempts to use main bundle.
     
     - returns: Pluralized localized string.
     */
    func localizedPlural(argument: CVarArg, in bundle: Bundle?) -> String {
        NSString.localizedStringWithFormat(localized(in: bundle) as NSString, argument) as String
    }

    //MARK: bundle & tableName friendly extension
    /**
     Swift 2 friendly localization syntax, replaces NSLocalizedString.
     
     - parameter tableName: The receiver’s string table to search. If tableName is `nil`
     or is an empty string, the method attempts to use `Localizable.strings`.
     
     - parameter bundle: The receiver’s bundle to search. If bundle is `nil`,
     the method attempts to use main bundle.
     
     - returns: The localized string.
     */
    func localized(using tableName: String?, in bundle: Bundle?) -> String {
        localized(tableName: tableName, bundle: bundle)
    }
    
    /**
     Swift 2 friendly localization syntax with format arguments, replaces String(format:NSLocalizedString).
     
     - parameter arguments: arguments values for temlpate (substituted according to the user’s default locale).
     
     - parameter tableName: The receiver’s string table to search. If tableName is `nil`
     or is an empty string, the method attempts to use `Localizable.strings`.
     
     - parameter bundle: The receiver’s bundle to search. If bundle is `nil`,
     the method attempts to use main bundle.
     
     - returns: The formatted localized string with arguments.
     */
    func localizedFormat(arguments: CVarArg..., using tableName: String?, in bundle: Bundle?) -> String {
        String(format: localized(using: tableName, in: bundle),
               locale: PTLanguage.share.locale,
               arguments: arguments)
    }
    
    /**
     Swift 2 friendly plural localization syntax with a format argument.
     
     - parameter argument: Argument to determine pluralisation.
     
     - parameter tableName: The receiver’s string table to search. If tableName is `nil`
     or is an empty string, the method attempts to use `Localizable.strings`.
     
     - parameter bundle: The receiver’s bundle to search. If bundle is `nil`,
     the method attempts to use main bundle.
     
     - returns: Pluralized localized string.
     */
    func localizedPlural(argument: CVarArg, using tableName: String?, in bundle: Bundle?) -> String {
        NSString.localizedStringWithFormat(localized(using: tableName, in: bundle) as NSString, argument) as String
    }

    //MARK: tableName friendly extension
    /**
     Swift 2 friendly localization syntax, replaces NSLocalizedString.
     
     - parameter tableName: The receiver’s string table to search. If tableName is `nil`
     or is an empty string, the method attempts to use `Localizable.strings`.
     
     - returns: The localized string.
     */
    func localized(using tableName: String?) -> String {
        localized(using: tableName, in: .main)
    }
    
    /**
     Swift 2 friendly localization syntax with format arguments, replaces String(format:NSLocalizedString).
     
     - parameter arguments: arguments values for temlpate (substituted according to the user’s default locale).

     - parameter tableName: The receiver’s string table to search. If tableName is `nil`
     or is an empty string, the method attempts to use `Localizable.strings`.
     
     - returns: The formatted localized string with arguments.
     */
    func localizedFormat(arguments: CVarArg..., using tableName: String?) -> String {
        String(format: localized(using: tableName),
               locale: PTLanguage.share.locale,
               arguments: arguments)
    }
    
    /**
     Swift 2 friendly plural localization syntax with a format argument.
     
     - parameter argument: Argument to determine pluralisation.

     - parameter tableName: The receiver’s string table to search. If tableName is `nil`
     or is an empty string, the method attempts to use `Localizable.strings`.
     
     - returns: Pluralized localized string.
     */
    func localizedPlural(argument: CVarArg, using tableName: String?) -> String {
        NSString.localizedStringWithFormat(localized(using: tableName) as NSString, argument) as String
    }
}
