//
//  PTActiveType.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 31/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

// 优化：添加 Sendable 以符合 Swift 6 并发安全
@MainActor
public enum PTActiveType: Hashable, Equatable, Sendable {
    case mention
    case hashtag
    case url
    case email
    case chinaCellPhone
    case snsId
    case custom(pattern: String)
    
    var pattern: String {
        switch self {
        case .mention: return PTRegexParser.mentionPattern
        case .hashtag: return PTRegexParser.hashtagPattern
        case .url: return PTRegexParser.urlPattern
        case .email: return PTRegexParser.emailPattern
        case .chinaCellPhone: return PTRegexParser.chinaCellPhone
        case .snsId: return PTRegexParser.snsID
        case .custom(let regex): return regex
        }
    }
}

// 优化：添加 Sendable
enum PTActiveElement: Sendable {
    case mention(String)
    case hashtag(String)
    case email(String)
    case url(original: String, trimmed: String)
    case chinaCellPhone(String)
    case snsId(String)
    case custom(String)
    
    static func create(with activeType: PTActiveType, text: String) -> PTActiveElement {
        switch activeType {
        case .mention: return mention(text)
        case .hashtag: return hashtag(text)
        case .email: return email(text)
        case .url: return url(original: text, trimmed: text)
        case .chinaCellPhone: return chinaCellPhone(text)
        case .snsId: return snsId(text)
        case .custom: return custom(text)
        }
    }
}

@MainActor
struct PTRegexParser {
    static let hashtagPattern = "(?:^|\\s|$)#[\\p{L}0-9_]*"
    static let mentionPattern = "(?:^|\\s|$|[.])@[\\p{L}0-9_]*"
    static let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    static let urlPattern = "(^|[\\s.:;?\\-\\]<\\(])" +
        "((https?://|www\\.|pic\\.)[-\\w;/?:@&=+$\\|\\_.!~*\\|'()\\[\\]%#,☺]+[\\w/#](\\(\\))?)" +
    "(?=$|[\\s',\\|\\(\\).:;?\\-\\[\\]>\\)])"
    static let chinaCellPhone = "1[3456789]\\d{9}"
    static let snsID = "([a-zA-Z]+\\d*)"

    // 修复/优化：Swift 6 中，只要标注了 @MainActor，且只在 MainActor 访问，
    private static var cachedRegularExpressions: [String : NSRegularExpression] = [:]

    static func getElements(from text: String, with pattern: String, range: NSRange) -> [NSTextCheckingResult] {
        guard let elementRegex = regularExpression(for: pattern) else { return [] }
        return elementRegex.matches(in: text, options: [], range: range)
    }

    private static func regularExpression(for pattern: String) -> NSRegularExpression? {
        if let regex = cachedRegularExpressions[pattern] {
            return regex
        } else if let createdRegex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            cachedRegularExpressions[pattern] = createdRegex
            return createdRegex
        }
        return nil
    }
}
