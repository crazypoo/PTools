//
//  Locale+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public extension Locale {
    
    //MARK: 判断当前是否12小时格式
    var is12HourTimeFormat: Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none
        dateFormatter.locale = self
        let dateString = dateFormatter.string(from: Date())
        return dateString.contains(dateFormatter.amSymbol) || dateString.contains(dateFormatter.pmSymbol)
    }
    
    var languageID: String? {
        if #available(iOS 16.0, tvOS 16.0, watchOS 9.0, macOS 13.0, *) {
            return self.language.languageCode?.identifier
        } else {
            return self.languageCode
        }
    }
    
    func localised(in locale: Locale) -> String? {
        guard let currentLanguageCode = self.languageID else { return nil }
        guard let toLanguageCode = locale.languageID else { return nil }
        let nslocale = NSLocale(localeIdentifier: toLanguageCode)
        let text = nslocale.displayName(forKey: NSLocale.Key.identifier, value: currentLanguageCode)
        return text?.localizedCapitalized
    }
}
