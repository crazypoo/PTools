//
//  PTCallStackParser.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class PTCallStackParser {
    
    // 获取当前 Bundle 的名称
    static var bundleName: String? {
        let key = kCFBundleNameKey as String
        if let name = Bundle.main.infoDictionary?[key] as? String {
            return name
        } else if let name = Bundle(for: self).infoDictionary?[key] as? String {
            return name
        }
        return nil
    }

    // 清理并格式化方法名字符串
    private static func cleanMethod(method: String) -> String {
        var result = method
        
        // 修复：正确地移除开头的 "(" 字符
        if result.hasPrefix("(") && result.count > 1 {
            result = String(result.dropFirst())
        }
        
        // 确保方法名以 ")" 结尾
        if !result.hasSuffix(")") {
            result += ")"
        }
        
        return result
    }

    /**
     从 'Thread.callStackSymbols' 中提取特定的堆栈项，并解析出类名和方法名。

     - Parameters:
        - stackSymbol: 'Thread.callStackSymbols' 数组中的一条特定字符串
        - includeImmediateParentClass: 在遇到内部类（Inner Class）的情况下，是否需要包含它的直接父类名称。

     - Returns: 一个包含 (类名, 方法名) 的元组。如果解析失败则返回 nil。
     */
    class func classAndMethodForStackSymbol(_ stackSymbol: String, includeImmediateParentClass: Bool = false) -> (String, String)? {
        // 优化：使用 Swift 原生的 isWhitespace 进行分割，比使用正则表达式性能更好
        let components = stackSymbol.split(whereSeparator: \.isWhitespace)
        
        guard components.count >= 4 else { return nil }
        
        // 尝试解析 Swift 的混淆符号（假设 parseMangledSwiftSymbol 在其他地方已定义）
        guard var packageClassAndMethodStr = try? parseMangledSwiftSymbol(String(components[3])).description else {
            return nil
        }
        
        // 清理多余的空格
        packageClassAndMethodStr = packageClassAndMethodStr.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        guard let packageComponent = packageClassAndMethodStr.split(separator: " ").first else {
            return nil
        }
        
        let packageClassAndMethod = packageComponent.split(separator: ".")
        let numberOfComponents = packageClassAndMethod.count
        
        if numberOfComponents >= 2 {
            let method = PTCallStackParser.cleanMethod(method: String(packageClassAndMethod[numberOfComponents - 1]))
            
            // 处理包含父类的情况
            if includeImmediateParentClass, numberOfComponents >= 4 {
                let parentClass = packageClassAndMethod[numberOfComponents - 3]
                let currentClass = packageClassAndMethod[numberOfComponents - 2]
                return ("\(parentClass).\(currentClass)", method)
            }
            
            return (String(packageClassAndMethod[numberOfComponents - 2]), method)
        }
        
        return nil
    }

    /**
     从堆栈符号中解析出闭包（Closure）信息。
     */
    class func closureForStackSymbol(_ stackSymbol: String, includeImmediateParentClass: Bool = false) -> String? {
        // 优化：同样使用 isWhitespace 进行高效分割
        let components = stackSymbol.split(whereSeparator: \.isWhitespace)
        
        guard components.count >= 4 else { return nil }
        
        guard var packageClassAndMethodStr = try? parseMangledSwiftSymbol(String(components[3])).description else {
            return nil
        }
        
        packageClassAndMethodStr = packageClassAndMethodStr.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        guard let packageComponent = packageClassAndMethodStr.split(separator: " ").first else {
            return nil
        }
        
        let packageClassAndMethod = packageComponent.split(separator: ".")
        
        if packageClassAndMethod.count == 1 {
            return packageClassAndMethodStr
        }
        
        return nil
    }

    /**
     分析 'Thread.callStackSymbols'，并返回调用当前方法的那一层（调用方）的类名和方法名。

     - Parameters:
        - includeImmediateParentClass: 在遇到内部类时，是否包含父类名称。

     - Returns: 一个包含调用方 (类名, 方法名) 的元组。如果解析失败则返回 nil。
     */
    class func getCallingClassAndMethodInScope(includeImmediateParentClass: Bool = false) -> (String, String)? {
        let stackSymbols = Thread.callStackSymbols
        // 索引 2 代表调用方（0 是当前内部方法，1 是调用当前堆栈的方法，2 就是外层调用方）
        guard stackSymbols.count >= 3 else { return nil }
        return PTCallStackParser.classAndMethodForStackSymbol(stackSymbols[2], includeImmediateParentClass: includeImmediateParentClass)
    }

    /**
     分析 'Thread.callStackSymbols'，并返回当前执行代码所在的类名和方法名。

     - Parameters:
        - includeImmediateParentClass: 在遇到内部类时，是否包含父类名称。

     - Returns: 一个包含当前 (类名, 方法名) 的元组。如果解析失败则返回 nil。
     */
    class func getThisClassAndMethodInScope(includeImmediateParentClass: Bool = false) -> (String, String)? {
        let stackSymbols = Thread.callStackSymbols
        // 索引 1 代表当前正在执行的方法所在的作用域
        guard stackSymbols.count >= 2 else { return nil }
        return PTCallStackParser.classAndMethodForStackSymbol(stackSymbols[1], includeImmediateParentClass: includeImmediateParentClass)
    }
}
