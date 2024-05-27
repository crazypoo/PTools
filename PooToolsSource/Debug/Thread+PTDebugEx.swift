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
     An array of string containing parsed class names and method names
     */
    public class func simpleCallStackSymbols(
        _ stack: [String] = Thread.callStackSymbols
    ) -> [String] {
        let symbols: [String] = Thread.callStackSymbols
            .dropFirst()
            .map {
                guard
                    let module: String = $0.replacingOccurrences(
                        of: "\\s+",
                        with: " ",
                        options: .regularExpression,
                        range: nil
                    ).components(
                        separatedBy: " "
                    )[safe: 1],
                    !module.hasPrefix("PooTools")
                else {
                    return ""
                }
                if let symbol: (
                    String,
                    String
                ) = PTCallStackParser.classAndMethodForStackSymbol(
                    $0
                ) {
                    return "\(symbol.0) \(symbol.1)"
                }
                if let closure = PTCallStackParser.closureForStackSymbol(
                    $0
                ) {
                    return closure
                }
                return ""
            }
            .filter {
                !$0.isEmpty
            }

        let count: Int = symbols.count
        let digit: Int = String(
            count
        ).count

        return symbols
            .reversed()
            .enumerated()
            .map {
                let index = String(
                    $0.0 + 1
                ).leftPadding(
                    toLength: digit,
                    withPad: "0"
                )
                let head = "[CallStack:\(index)/\(count)]"
                return "\(head) \($0.1)"
            }
            .reversed()
    }

    /**
     A formatted string containing parsed class names and method names
     */
    public class var simpleCallStackString: String {
        simpleCallStackSymbols().joined(
            separator: "\n"
        )
    }
}
