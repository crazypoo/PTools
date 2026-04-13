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
            // 注意：因为原版的 createURLElements 返回元组，这里的调用如果是统一入口，
            // 建议 URL 不做截断处理，或者另写统一逻辑。这里保持你原有的分支路由。
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
        // 优化 1：使用 NSMutableString 进行安全的局部替换
        let mutableText = NSMutableString(string: text)

        // ⚠️ 关键修复：倒序遍历！
        // 因为截断 URL 会改变字符串的长度，如果正向遍历，前面替换后，后面的 NSRange 就会全部错位甚至越界崩溃。
        for match in matches.reversed() where match.range.length > 2 {
            let word = mutableText.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)

            guard let maxLength = maximumLength, word.count > maxLength else {
                let element = PTActiveElement.create(with: type, text: word)
                // 因为是倒序遍历，所以需要插入到数组头部，保证最终返回的元素顺序是从左到右
                elements.insert((match.range, element, type), at: 0)
                continue
            }

            // 假设 word 有 trim(to:) 扩展方法
            let trimmedWord = word.trim(to: maxLength)
            
            // 在原始匹配范围内，将具体的长 URL 替换为短 URL。避免了 replacingOccurrences 导致的全局误杀
            let wordRange = mutableText.range(of: word, options: [], range: match.range)
            if wordRange.location != NSNotFound {
                mutableText.replaceCharacters(in: wordRange, with: trimmedWord)
                
                // 计算替换后新的 Range
                let newRange = NSRange(location: wordRange.location, length: (trimmedWord as NSString).length)
                let element = PTActiveElement.url(original: word, trimmed: trimmedWord)
                elements.insert((newRange, element, type), at: 0)
            }
        }
        
        return (elements, mutableText as String)
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
            let word = nsstring.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
            
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
            // 优化 2：直接提取，不使用位置 + 1，避免因正则捕获到前导空格/符号导致截断错误
            var word = nsstring.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 安全移除首字符 @ 或 #
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
