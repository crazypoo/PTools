//
//  PTActiveType.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 31/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

enum PTActiveElement {
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

struct PTRegexParser {

    static let hashtagPattern = "(?:^|\\s|$)#[\\p{L}0-9_]*"
    static let mentionPattern = "(?:^|\\s|$|[.])@[\\p{L}0-9_]*"
    static let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    static let urlPattern = "(^|[\\s.:;?\\-\\]<\\(])" +
        "((https?://|www\\.|pic\\.)[-\\w;/?:@&=+$\\|\\_.!~*\\|'()\\[\\]%#,☺]+[\\w/#](\\(\\))?)" +
    "(?=$|[\\s',\\|\\(\\).:;?\\-\\[\\]>\\)])"
    static let chinaCellPhone = "1[3456789]\\d{9}"
    static let snsID = "([a-zA-Z]+\\d*)"

    // 优化 2：添加 NSLock 保证线程安全
    private static var cachedRegularExpressions: [String : NSRegularExpression] = [:]
    private static let cacheLock = NSLock()

    static func getElements(from text: String, with pattern: String, range: NSRange) -> [NSTextCheckingResult]{
        guard let elementRegex = regularExpression(for: pattern) else { return [] }
        let result = elementRegex.matches(in: text, options: [], range: range)
        return result
    }

    private static func regularExpression(for pattern: String) -> NSRegularExpression? {
        // 使用锁来保护字典的读写操作
        cacheLock.lock()
        defer { cacheLock.unlock() } // 无论以何种方式 return，defer 都会确保锁被释放
        
        if let regex = cachedRegularExpressions[pattern] {
            return regex
        } else if let createdRegex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            cachedRegularExpressions[pattern] = createdRegex
            return createdRegex
        } else {
            return nil
        }
    }
}

// 优化 1：直接声明遵循 Hashable 和 Equatable，无需手写扩展
public enum PTActiveType: Hashable, Equatable {
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

// ⚠️ 注意：之前的 extension PTActiveType: Hashable, Equatable { ... }
// 和 public func ==(lhs: PTActiveType, rhs: PTActiveType) -> Bool { ... }
// 已经可以安全地全部删除了！
