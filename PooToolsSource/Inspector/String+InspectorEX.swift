//
//  String+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension String {
    static let newLine = "\n"
    static let singleSpace = " "

    public static let systemFontFamilyName = "System Font"

//    var trimmed: String? {
//        let trimmedString = trimmingCharacters(in: .whitespacesAndNewlines)
//        return trimmedString.isEmpty ? .none : trimmedString
//    }

    func string(prepending: String? = .none, appending: String? = .none, separator: String? = .singleSpace) -> String {
        [prepending,
         self,
         appending]
            .compactMap { $0 }
            .joined(
                separator: separator ?? .init()
            )
    }

    func camelCaseToWords() -> String {
        String(
            unicodeScalars
                .enumerated()
                .reduce("") { string, item in
                    let (offset, character) = item
                    let isUppercase = CharacterSet.uppercaseLetters.contains(character)
                    var nextCharacter: UnicodeScalarView.Element? {
                        guard offset < unicodeScalars.count - 1 else { return .none }
                        let nextIndex = index(startIndex, offsetBy: offset + 1)
                        return unicodeScalars[nextIndex]
                    }
                    guard
                        isUppercase,
                        let nextCharacter = nextCharacter,
                        CharacterSet.lowercaseLetters.contains(nextCharacter)
                    else {
                        return string + String(character)
                    }

                    return "\(string) \(character)"
                }
        )
    }

    func removingRegexMatches(
        pattern: String,
        options: NSRegularExpression.MatchingOptions = [],
        replaceWith: String = ""
    ) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: .zero, length: count)
            return regex
                .stringByReplacingMatches(
                    in: self,
                    options: options,
                    range: range,
                    withTemplate: replaceWith
                )
        }
        catch {
            return self
        }
    }

    /// Generates a `UIImage` instance from this string using a specified
    /// attributes and size.
    ///
    /// - Parameters:
    ///     - attributes: to draw this string with. Default is `nil`.
    ///     - size: of the image to return.
    /// - Returns: a `UIImage` instance from this string using a specified
    /// attributes and size, or `nil` if the operation fails.
    func image(withAttributes attributes: [NSAttributedString.Key: Any]? = nil, size: CGSize? = nil) -> UIImage? {
        let size = size ?? (self as NSString).size(withAttributes: attributes)
        return UIGraphicsImageRenderer(size: size).image { _ in
            (self as NSString)
                .draw(
                    in: CGRect(origin: .zero, size: size),
                    withAttributes: attributes
                )
        }
    }
}

