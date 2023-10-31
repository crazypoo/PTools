//
//  PTActiveBuilder.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 31/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

struct PTActiveBuilder {

    static func createElements(type: PTActiveType, from text: String, range: NSRange, filterPredicate: PTActiveStringBoolCallBack?) -> [PTElementTuple] {
        switch type {
        case .mention, .hashtag:
            return createElementsIgnoringFirstCharacter(text: text, type: type, range: range, filterPredicate: filterPredicate)
        case .url:
            return createElements(text: text, type: type, range: range, filterPredicate: filterPredicate)
        case .custom:
            return createElements(text: text, type: type, range: range, minLength: 1, filterPredicate: filterPredicate)
        case .email:
            return createElements(text: text, type: type, range: range, filterPredicate: filterPredicate)
        }
    }

    static func createURLElements(text: String, range: NSRange, maximumLength: Int?) -> ([PTElementTuple], String) {
        let type = PTActiveType.url
        var text = text
        let matches = PTRegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [PTElementTuple] = []

        for match in matches where match.range.length > 2 {
            let word = nsstring.substring(with: match.range)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            guard let maxLength = maximumLength, word.count > maxLength else {
                let range = maximumLength == nil ? match.range : (text as NSString).range(of: word)
                let element = PTActiveElement.create(with: type, text: word)
                elements.append((range, element, type))
                continue
            }

            let trimmedWord = word.trim(to: maxLength)
            text = text.replacingOccurrences(of: word, with: trimmedWord)

            let newRange = (text as NSString).range(of: trimmedWord)
            let element = PTActiveElement.url(original: word, trimmed: trimmedWord)
            elements.append((newRange, element, type))
        }
        return (elements, text)
    }

    private static func createElements(text: String,
                                       type: PTActiveType,
                                       range: NSRange,
                                       minLength: Int = 2,
                                       filterPredicate: PTActiveStringBoolCallBack?) -> [PTElementTuple] {

        let matches = PTRegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [PTElementTuple] = []

        for match in matches where match.range.length > minLength {
            let word = nsstring.substring(with: match.range)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if filterPredicate?(word) ?? true {
                let element = PTActiveElement.create(with: type, text: word)
                elements.append((match.range, element, type))
            }
        }
        return elements
    }

    private static func createElementsIgnoringFirstCharacter(text: String,
                                                             type: PTActiveType,
                                                             range: NSRange,
                                                             filterPredicate: PTActiveStringBoolCallBack?) -> [PTElementTuple] {
        let matches = PTRegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [PTElementTuple] = []

        for match in matches where match.range.length > 2 {
            let range = NSRange(location: match.range.location + 1, length: match.range.length - 1)
            var word = nsstring.substring(with: range)
            if word.hasPrefix("@") {
                word.remove(at: word.startIndex)
            }
            else if word.hasPrefix("#") {
                word.remove(at: word.startIndex)
            }

            if filterPredicate?(word) ?? true {
                let element = PTActiveElement.create(with: type, text: word)
                elements.append((match.range, element, type))
            }
        }
        return elements
    }
}
