//
//  PTCallStackParser.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

class PTCallStackParser {
    static var bundleName: String? {
        if let name: String = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String {
            return name
        } else if let name: String = Bundle(for: self).infoDictionary?[kCFBundleNameKey as String] as? String {
            return name
        } else {
            return nil
        }
    }

    private static func cleanMethod(method: String) -> String {
        var result = method
        if result.count > 1 {
            let firstChar: Character = result[result.startIndex]
            if firstChar == "(" {
                result = String(result[result.startIndex...])
            }
        }
        if !result.hasSuffix(")") {
            result = result + ")" // add closing bracket
        }
        return result
    }

    /**
     Takes a specific item from 'NSThread.callStackSymbols()' and returns the class and method call contained within.

     - Parameters:
     - stackSymbol: a specific item from 'NSThread.callStackSymbols()'
     - includeImmediateParentClass: Whether or not to include the parent class in an innerclass situation.

     - Returns: a tuple containing the (class,method) or nil if it could not be parsed
     */
    class func classAndMethodForStackSymbol(_ stackSymbol: String, includeImmediateParentClass: Bool? = false) -> (String, String)? {
        let replaced: String = stackSymbol.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
        let components: [Substring] = replaced.split(separator: " ")
        if components.count >= 4 {
            guard var packageClassAndMethodStr = try? parseMangledSwiftSymbol(String(components[3])).description else {
                return nil
            }
            packageClassAndMethodStr = packageClassAndMethodStr.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
            let packageComponent = String(packageClassAndMethodStr.split(separator: " ").first!)
            let packageClassAndMethod = packageComponent.split(separator: ".")
            let numberOfComponents = packageClassAndMethod.count
            if numberOfComponents >= 2 {
                let method = PTCallStackParser.cleanMethod(method: String(packageClassAndMethod[numberOfComponents - 1]))
                if includeImmediateParentClass != nil {
                    if includeImmediateParentClass == true, numberOfComponents >= 4 {
                        return (packageClassAndMethod[numberOfComponents - 3] + "." + packageClassAndMethod[numberOfComponents - 2], method)
                    }
                }
                return (String(packageClassAndMethod[numberOfComponents - 2]), method)
            }
        }
        return nil
    }

    class func closureForStackSymbol(_ stackSymbol: String, includeImmediateParentClass: Bool? = false) -> String? {
        let replaced: String = stackSymbol.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
        let components: [Substring] = replaced.split(separator: " ")
        if components.count >= 4 {
            guard var packageClassAndMethodStr = try? parseMangledSwiftSymbol(String(components[3])).description else {
                return nil
            }
            packageClassAndMethodStr = packageClassAndMethodStr.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
            let packageComponent = String(packageClassAndMethodStr.split(separator: " ").first!)
            let packageClassAndMethod = packageComponent.split(separator: ".")
            let numberOfComponents = packageClassAndMethod.count
            if numberOfComponents == 1 {
                return packageClassAndMethodStr
            }
        }
        return nil
    }

    /**
     Analyses the 'NSThread.callStackSymbols()' and returns the calling class and method in the scope of the caller.

     - Parameters:
     - includeImmediateParentClass: Whether or not to include the parent class in an innerclass situation.

     - Returns: a tuple containing the (class,method) or nil if it could not be parsed
     */
    class func getCallingClassAndMethodInScope(includeImmediateParentClass: Bool? = false) -> (String, String)? {
        let stackSymbols: [String] = Thread.callStackSymbols
        if stackSymbols.count >= 3 {
            return PTCallStackParser.classAndMethodForStackSymbol(stackSymbols[2], includeImmediateParentClass: includeImmediateParentClass)
        }
        return nil
    }

    /**
     Analyses the 'NSThread.callStackSymbols()' and returns the current class and method in the scope of the caller.

     - Parameters:
     - includeImmediateParentClass: Whether or not to include the parent class in an inner class situation.

     - Returns: a tuple containing the (class,method) or nil if it could not be parsed
     */
    class func getThisClassAndMethodInScope(includeImmediateParentClass: Bool? = false) -> (String, String)? {
        let stackSymbols: [String] = Thread.callStackSymbols
        if stackSymbols.count >= 2 {
            return PTCallStackParser.classAndMethodForStackSymbol(stackSymbols[1], includeImmediateParentClass: includeImmediateParentClass)
        }
        return nil
    }
}
