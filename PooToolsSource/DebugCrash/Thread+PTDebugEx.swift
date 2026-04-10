//
//  Thread+PTDebugEx.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension Thread {
    /**
     获取一个包含已解析的类名和方法名的字符串数组
     
     - Parameter stack: 调用堆栈数组，默认为当前线程的堆栈
     - Returns: 格式化并按层级编号的堆栈符号数组
     */
    public class func simpleCallStackSymbols(_ stack: [String] = Thread.callStackSymbols) -> [String] {
        // 优化1 & 3：使用传入的 `stack` 参数，并用 `compactMap` 替代 `map` + `filter` 的组合
        let symbols: [String] = stack.dropFirst().compactMap { symbolStr in
            
            // 优化4：使用 Swift 原生的 `split` 高效处理多个空格，代替耗时的正则表达式
            let components = symbolStr.split(whereSeparator: \.isWhitespace)
            
            // 确保能安全取到模块名（组件索引 1 通常是 Module Name）
            // 注意：这里也移除了原有的 `[safe: 1]` 依赖，让代码更纯净
            guard components.count > 1 else { return nil }
            let module = String(components[1])
            
            // 过滤掉 PooTools 框架内部的调用堆栈
            if module.hasPrefix("PooTools") {
                return nil
            }
            
            // 尝试解析类和方法
            if let symbol = PTCallStackParser.classAndMethodForStackSymbol(symbolStr) {
                return "\(symbol.0) \(symbol.1)"
            }
            
            // 尝试解析闭包
            if let closure = PTCallStackParser.closureForStackSymbol(symbolStr) {
                return closure
            }
            
            // 解析失败则返回 nil，compactMap 会自动忽略它
            return nil
        }

        let count: Int = symbols.count
        let digit: Int = String(count).count

        // 优化2：移除耗性能的两次 `reversed()` 操作，通过数学计算直接得出倒序的序号
        // 原逻辑是最底部的堆栈序号为 1，最顶部的为 count
        return symbols.enumerated().map { index, symbol in
            // 直接计算出当前堆栈对应的编号 (例如 count 为 5，index 为 0 时，stackIndex 为 5)
            let stackIndex = count - index
            
            // 假定 `leftPadding` 是你在其他地方写好的 String 扩展方法
            let indexString = String(stackIndex).leftPadding(toLength: digit, withPad: "0")
            let head = "[CallStack:\(indexString)/\(count)]"
            
            return "\(head) \(symbol)"
        }
    }

    /**
     获取一个包含已解析的类名和方法名的格式化多行字符串
     */
    public class var simpleCallStackString: String {
        // 直接将数组拼接为带换行符的字符串
        simpleCallStackSymbols().joined(separator: "\n")
    }
}
