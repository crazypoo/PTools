//
//  PTLocale.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public enum PTLocale: String {
    
    case ru = "ru"                      // Russian
    case en = "en"                      // English
    case uk = "uk"                      // Ukrainian
    case es = "es"                      // Spanish
    case ar = "ar"                      // Arabic
    case fa = "fa"                      // Persian
    case de = "de"                      // German
    case fr = "fr"                      // French
    case it = "it"                      // Italian
    case nl = "nl"                      // Dutch
    case id = "id"                      // Indonesian
    case ms = "ms"                      // Malay
    case tr = "tr"                      // Turkish
    case hy = "hy"                      // Armenian
    case zh = "zh"                      // Chinese
    case ja = "ja"                      // Japanese
    case ur = "ur"                      // Urdu
    case be = "be"                      // Belarusian
    case pt = "pt"                      // Portuguese
    case pl = "pl"                      // Polish
    case gsw = "gsw"                    // Swiss German
    case fil = "fil"                    // Filipino
    
    /**
        Uniq identifier.
     */
    public var identifier: String { rawValue }
    
    /**
        Code if language which using Apple without split.
     */
    public var languageCode: String { rawValue }
    
    /**
        Current locale, which using in app
     */
    public static var current: PTLocale {
        get {
            var code = Locale.preferredLanguages.first ?? "en"
            var locale = PTLocale(rawValue: code)
            if locale == nil {
                code = String(code.split(separator: "-").first ?? "en")
                locale = PTLocale(rawValue: code)
            }
            return locale ?? .en
        }
    }
    
    /**
        Localize description of language.
     */
    @available(iOS 11.0, tvOS 11.0, macOS 10.11, *)
    public func description(in locale: PTLocale) -> String {
        let locale = NSLocale(localeIdentifier: locale.languageCode)
        let text = locale.displayName(forKey: NSLocale.Key.identifier, value: languageCode) ?? .empty
        return text.localizedCapitalized
    }
}
