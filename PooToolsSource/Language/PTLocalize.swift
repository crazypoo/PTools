//
//  PTLocalize.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

/// Default language. English. If English is unavailable defaults to base localization.
let PTDefaultLanguage = "en"

/// Base bundle as fallback.
let PTBaseBundle = "Base"

// MARK: Localization Syntax

/**
Swift 1.x friendly localization syntax, replaces NSLocalizedString
- Parameter string: Key to be localized.
- Returns: The localized string.
*/
public func Localized(_ string: String) -> String {
    string.localized()
}

/**
 Swift 1.x friendly localization syntax with format arguments, replaces String(format:NSLocalizedString)
 - Parameter string: Key to be localized.
 - Parameter arguments:
 - Returns: The formatted localized string with arguments.
 */
public func Localized(_ string: String, arguments: CVarArg...) -> String {
    String(format: string.localized(), arguments: arguments)
}

/**
 Swift 1.x friendly plural localization syntax with a format argument
 
 - parameter string:   String to be formatted
 - parameter argument: Argument to determine pluralisation
 
 - returns: Pluralized localized string.
 */
public func LocalizedPlural(_ string: String, argument: CVarArg) -> String {
    string.localizedPlural(argument)
}


public extension String {
    /**
     Swift 2 friendly localization syntax, replaces NSLocalizedString
     - Returns: The localized string.
     */
    func localized() -> String {
        localized(using: nil, in: Bundle.podCoreBundle())
    }

    /**
     Swift 2 friendly localization syntax with format arguments, replaces String(format:NSLocalizedString)
     - Returns: The formatted localized string with arguments.
     */
    func localizedFormat(_ arguments: CVarArg...) -> String {
        String(format: localized(), arguments: arguments)
    }
    
    /**
     Swift 2 friendly plural localization syntax with a format argument
     
     - parameter argument: Argument to determine pluralisation
     
     - returns: Pluralized localized string.
     */
    func localizedPlural(_ argument: CVarArg) -> String {
        NSString.localizedStringWithFormat(localized() as NSString, argument) as String
    }

    /**
     Add comment for NSLocalizedString
     - Returns: The localized string.
    */
    func commented(_ argument: String) -> String {
        self
    }
}



// MARK: Language Setting Functions
@objcMembers
open class Localize: NSObject {
    
    /**
     List available languages
     - Returns: Array of available languages.
     */
    open class func availableLanguages(_ excludeBase: Bool = false) -> [String] {
        var availableLanguages = Bundle.main.localizations
        // If excludeBase = true, don't include "Base" in available languages
        if let indexOfBase = availableLanguages.firstIndex(of: "Base") , excludeBase == true {
            availableLanguages.remove(at: indexOfBase)
        }
        return availableLanguages
    }
    
    /**
     Current language
     - Returns: The current language. String.
     */
    open class func currentLanguage() -> String {
        PTCoreUserDefultsWrapper.AppLanguage
    }
    
    /**
     Change the current language
     - Parameter language: Desired language.
     */
    open class func setCurrentLanguage(_ language: String) {
        let selectedLanguage = availableLanguages().contains(language) ? language : defaultLanguage()
        if (selectedLanguage != currentLanguage()){
            PTCoreUserDefultsWrapper.AppLanguage = selectedLanguage
            NotificationCenter.default.post(name: LanguageDidChangedKey, object: nil)
        }
    }
    
    /**
     Default language
     - Returns: The app's default language. String.
     */
    open class func defaultLanguage() -> String {
        var defaultLanguage: String = String()
        guard let preferredLanguage = Bundle.main.preferredLocalizations.first else {
            return PTDefaultLanguage
        }
        let availableLanguages: [String] = availableLanguages()
        if (availableLanguages.contains(preferredLanguage)) {
            defaultLanguage = preferredLanguage
        } else {
            defaultLanguage = PTDefaultLanguage
        }
        return defaultLanguage
    }
    
    /**
     Resets the current language to the default
     */
    open class func resetCurrentLanguageToDefault() {
        setCurrentLanguage(defaultLanguage())
    }
    
    /**
     Get the current language's display name for a language.
     - Parameter language: Desired language.
     - Returns: The localized string.
     */
    open class func displayNameForLanguage(_ language: String) -> String {
        let locale : NSLocale = NSLocale(localeIdentifier: currentLanguage())
        if let displayName = locale.displayName(forKey: NSLocale.Key.identifier, value: language) {
            return displayName
        }
        return String()
    }
}
