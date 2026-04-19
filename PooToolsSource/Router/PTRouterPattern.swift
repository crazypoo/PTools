//
//  PTRouterPattern.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public class PTRouterPattern {
    public var patternString: String
    public var classString: String
    public var priority: UInt
    
    // MARK: - 正则引擎核心属性
    private var regex: NSRegularExpression?
    /// 按顺序记录 URL 中的参数名称 (例如 "id", "type")
    private var paramNames: [String] = []

    public init(_ string: String, classString: String, priority: UInt = 0) {
        self.patternString = string
        self.classString = classString
        self.priority = priority
        
        self.compileRegex(from: string)
    }
    
    /// 将 scheme://user/:id/detail/:type 编译为正则表达式
    private func compileRegex(from pattern: String) {
        // 1. 查找所有形如 :name 的参数占位符
        let paramRegex = try? NSRegularExpression(pattern: ":([a-zA-Z0-9_]+)", options: [])
        let nsString = pattern as NSString
        let matches = paramRegex?.matches(in: pattern, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        // 保存提取出的参数名
        self.paramNames = matches.map { nsString.substring(with: $0.range(at: 1)) }
        
        // 2. 构造最终的匹配正则表达式
        var finalRegexString = pattern
        for name in paramNames {
            // 将 :name 替换为正则表达式中的捕获组 ([^/]+) ，表示匹配到下一个斜杠前的内容
            finalRegexString = finalRegexString.replacingOccurrences(of: ":\(name)", with: "([^/]+)")
        }
        
        // 加上 ^ 和 $ 确保是全字匹配
        finalRegexString = "^\(finalRegexString)$"
        
        // 编译并缓存正则表达式，提升后续匹配效率
        self.regex = try? NSRegularExpression(pattern: finalRegexString, options: [])
    }
    
    /// 匹配传入的真实 URL，并返回提取的参数字典
    public func matchResult(for requestURL: String) -> (matched: Bool, queries: [String: Any]) {
        guard let regex = self.regex else { return (false, [:]) }
        
        let nsString = requestURL as NSString
        // 尝试匹配
        guard let match = regex.firstMatch(in: requestURL, options: [], range: NSRange(location: 0, length: nsString.length)) else {
            return (false, [:]) // 匹配失败
        }
        
        // 匹配成功，开始提取参数
        var extractedQueries: [String: Any] = [:]
        
        // NSRegularExpression 的 range(at: 0) 是整个匹配串，捕获组从 1 开始
        for (index, name) in paramNames.enumerated() {
            let range = match.range(at: index + 1)
            if range.location != NSNotFound {
                extractedQueries[name] = nsString.substring(with: range)
            }
        }
        
        return (true, extractedQueries)
    }
}
