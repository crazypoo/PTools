//
//  HTTPURLResponse+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
    func expires() -> Date? {
        if let cc = (allHeaderFields["Cache-Control"] as? String)?.lowercased(),
           let range = cc.range(of: "max-age="),
           let s = cc[range.upperBound...].components(separatedBy: ",").first,
           let age = TimeInterval(s) {
            return Date(timeIntervalSinceNow: age)
        }

        let expiresValue = allHeaderFields.first { key, _ in
            String(describing: key).caseInsensitiveCompare("Expires") == .orderedSame
        }?.value as? String
        if let expiresValue {
            // English: HTTP dates are GMT protocol values, not user-local dates.
            // Español: Las fechas HTTP son valores de protocolo GMT, no fechas locales del usuario.
            // 中文：HTTP 日期是 GMT 协议值，不是用户本地日期。
            let context = PTDateContext(calendar: Calendar(identifier: .gregorian),
                                         timeZone: .gmt,
                                         locale: Locale(identifier: "en_US_POSIX"))
            return try? PTDateParser.parse(expiresValue,
                                           strategy: .patterns([
                                               "EEE, dd MMM yyyy HH:mm:ss zzz",
                                               "EEEE, dd-MMM-yy HH:mm:ss zzz",
                                               "EEE MMM d HH:mm:ss yyyy"
                                           ]),
                                           context: context)
        }

        return nil
    }
}
