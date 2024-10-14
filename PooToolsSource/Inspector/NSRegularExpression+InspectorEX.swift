//
//  NSRegularExpression+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension NSRegularExpression {
    func matches(in string: String, options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        matches(in: string, options: options, range: NSMakeRange(.zero, string.count))
    }

    func firstMatch(in string: String, options: NSRegularExpression.MatchingOptions = []) -> NSTextCheckingResult? {
        firstMatch(in: string, options: options, range: NSMakeRange(.zero, string.count))
    }
}

extension String {
    func replacingCharacters(in range: NSRange, with string: String) -> String {
        (self as NSString).replacingCharacters(in: range, with: string)
    }

    func substring(with range: NSRange) -> String {
        (self as NSString).substring(with: range)
    }
}
