//
//  HTTPURLResponse+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import SwiftDate

extension HTTPURLResponse {
    func expires() -> Date? {
        if let cc = (allHeaderFields["Cache-Control"] as? String)?.lowercased(),
           let range = cc.range(of: "max-age="),
           let s = cc[range.upperBound...].components(separatedBy: ",").first,
           let age = TimeInterval(s) {
            return Date(timeIntervalSinceNow: age)
        }

        if let ex = (allHeaderFields["Expires"] as? String)?.lowercased() {
            return ex.toDate()?.date
        }

        return nil
    }
}
