//
//  PTActiveBuilder.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 31/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

// 优化：在 Swift 6 中，UI 回调通常需要更新 UI，显式声明 @MainActor 更安全
public typealias PTConfigureLinkAttribute = @MainActor (PTActiveType, [NSAttributedString.Key : Any], Bool) -> [NSAttributedString.Key : Any]
typealias PTElementTuple = (range: NSRange, element: PTActiveElement, type: PTActiveType)
public typealias PTActiveDidSelectedHandle = @MainActor (String, PTActiveType) -> ()
public typealias PTActiveStringHandle = @MainActor (String) -> ()
public typealias PTActiveURLHandle = @MainActor (URL) -> ()
public typealias PTActiveStringBoolCallBack = @MainActor (String) -> Bool

@MainActor
struct PTActiveBuilder {
    static func createElements(type: PTActiveType, from text: String, range: NSRange, filterPredicate: PTActiveStringBoolCallBack?) -> [PTElementTuple] {
        switch type {
        case .mention, .hashtag:
            return createElementsIgnoringFirstCharacter(text: text, type: type, range: range, filterPredicate: filterPredicate)
        case .url:
            return createElements(text: text, type: type, range: range, filterPredicate: filterPredicate)
        case .custom:
            return createElements(text: text, type: type, range: range, minLength: 1, filterPredicate: filterPredicate)
        case .email, .chinaCellPhone, .snsId:
            return createElements(text: text, type: type, range: range, filterPredicate: filterPredicate)
        }
    }

    static func createURLElements(text: String, range: NSRange, maximumLength: Int?) -> ([PTElementTuple], String) {
        let type = PTActiveType.url
        let matches = PTRegexParser.getElements(from: text, with: type.pattern, range: range)
        
        var elements: [PTElementTuple] = []
        let mutableText = NSMutableString(string: text)
        
        // 核心修复：引入 offset（偏移量），使用正向遍历
        var offset = 0

        for match in matches where match.range.length > 2 {
            // 计算当前匹配在被修改后的文本中的真实位置（加上之前累积的偏移量）
            var adjustedMatchRange = match.range
            adjustedMatchRange.location += offset
            
            let word = mutableText.substring(with: adjustedMatchRange).trimmingCharacters(in: .whitespacesAndNewlines)

            guard let maxLength = maximumLength, word.count > maxLength else {
                let element = PTActiveElement.create(with: type, text: word)
                // 查找精确的 wordRange 防止正则捕获的前导空格引起的范围偏差
                let wordRange = mutableText.range(of: word, options: [], range: adjustedMatchRange)
                if wordRange.location != NSNotFound {
                    elements.append((wordRange, element, type))
                } else {
                    elements.append((adjustedMatchRange, element, type))
                }
                continue
            }

            // 截断逻辑
            let trimmedWord = String(word.prefix(maxLength)) + "..."
            let wordRange = mutableText.range(of: word, options: [], range: adjustedMatchRange)
            
            if wordRange.location != NSNotFound {
                // 在动态调整后的范围内替换长链接为短链接
                mutableText.replaceCharacters(in: wordRange, with: trimmedWord)
                
                // 记录替换后的新 Range
                let newRange = NSRange(location: wordRange.location, length: (trimmedWord as NSString).length)
                let element = PTActiveElement.url(original: word, trimmed: trimmedWord)
                
                // 正向遍历直接 append 即可保证从左到右的正确顺序
                elements.append((newRange, element, type))
                
                // ⚠️ 关键一步：更新偏移量！
                // 计算差值：新短文本的长度 - 旧长文本的长度 (必然是负数)
                // 这个负数会累积，使得后续元素的 location 向左对齐，永远不会越界
                offset += (trimmedWord as NSString).length - (word as NSString).length
            }
        }
        
        return (elements, mutableText as String)
    }

    private static func createElements(text: String, type: PTActiveType, range: NSRange, minLength: Int = 2, filterPredicate: PTActiveStringBoolCallBack?) -> [PTElementTuple] {
        let matches = PTRegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [PTElementTuple] = []

        for match in matches where match.range.length > minLength {
            let word = nsstring.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
            if filterPredicate?(word) ?? true {
                let element = PTActiveElement.create(with: type, text: word)
                elements.append((match.range, element, type))
            }
        }
        return elements
    }

    private static func createElementsIgnoringFirstCharacter(text: String, type: PTActiveType, range: NSRange, filterPredicate: PTActiveStringBoolCallBack?) -> [PTElementTuple] {
        let matches = PTRegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [PTElementTuple] = []

        for match in matches where match.range.length > 2 {
            var word = nsstring.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
            if word.hasPrefix("@") || word.hasPrefix("#") {
                word.removeFirst()
            }
            if filterPredicate?(word) ?? true {
                let element = PTActiveElement.create(with: type, text: word)
                elements.append((match.range, element, type))
            }
        }
        return elements
    }
}
