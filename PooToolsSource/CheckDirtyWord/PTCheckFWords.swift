//
//  PTCheckFWords.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/28.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import Foundation

let EXIST = "isExists"

@objcMembers
public class PTCheckFWords: NSObject {
    @MainActor public static let share = PTCheckFWords()
    
    fileprivate var root:NSMutableDictionary = NSMutableDictionary()
    open var isFilterClose:Bool = false
    
    public override init() {
        super.init()
        initFilter()
    }
    
    public func initFilter(filePath: String = "") {
        let resolvedPath = filePath.isEmpty ? Self.defaultFilterFilePath() : filePath
        guard let resolvedPath else {
            print("PTCheckFWords: 无法找到敏感词资源文件 / No filter resource found / No se encontró el recurso de palabras sensibles")
            return
        }

        var dataFile: NSString?
        do {
            dataFile = try NSString(contentsOfFile: resolvedPath, encoding: String.Encoding.utf8.rawValue)
            let dataArr = dataFile?.components(separatedBy: "|")
            for item in dataArr ?? [] {
                if item.count > 0 {
                    insertWords(words: item as NSString)
                }
            }
        } catch {
            print("PTCheckFWords: \(error.localizedDescription)")
        }
    }
    
    func insertWords(words:NSString) {
        var node:NSMutableDictionary = root
        for i in stride(from: 0, to: words.length, by: 1) {
            let word = words.substring(with: NSRange(location: i, length: 1))
            if node.object(forKey: word) == nil {
                let dict = NSMutableDictionary()
                node.setObject(dict, forKey: word as NSCopying)
            }
            guard let child = node.object(forKey: word) as? NSMutableDictionary else {
                return
            }
            node = child
        }
        node.setObject(NSNumber(integerLiteral: 1), forKey: EXIST as NSCopying)
    }
    
    public func haveFWord(str:NSString) -> Bool {
        for i in stride(from: 0, to: str.length, by: 1) {
            let subString:NSString = str.substring(from: i) as NSString
            var node: NSMutableDictionary = root
            var num = 0
            
            for j in stride(from: 0, to: subString.length, by: 1) {
                let word = subString.substring(with: NSRange(location: j, length: 1))
                if node.object(forKey: word) == nil {
                    break
                } else {
                    num += 1
                    guard let child = node.object(forKey: word) as? NSMutableDictionary else {
                        break
                    }
                    node = child
                }
                
                if let nodeObj = node.object(forKey: EXIST) as? NSNumber, nodeObj.intValue == 1 {
                    return true
                }
            }
        }
        return false
    }
    
    public func filter(str:NSString) -> NSString {
        if isFilterClose || root.count == 0 {
            return str
        }
        
        let result = NSMutableString(string: str as String)
        for var i in stride(from: 0, to: str.length, by: 1) {
            let subString:NSString = str.substring(from: i) as NSString
            var node: NSMutableDictionary = root
            var num = 0
            
            for j in stride(from: 0, to: subString.length, by: 1) {
                let word = subString.substring(with: NSRange(location: j, length: 1))
                if node.object(forKey: word) == nil {
                    break
                } else {
                    num += 1
                    guard let child = node.object(forKey: word) as? NSMutableDictionary else {
                        break
                    }
                    node = child
                }
                
                if let nodeObj = node.object(forKey: EXIST) as? NSNumber, nodeObj.intValue == 1 {
                    let symbolStr: NSMutableString = NSMutableString()
                    for _ in stride(from: 0, to: num, by: 1) {
                        symbolStr.append("*")
                    }
                    result.replaceCharacters(in: NSRange(location: i, length: num), with: symbolStr as String)
                    i += j
                    break
                }
            }
        }
        return result
    }

    private static func defaultFilterFilePath() -> String? {
        #if SWIFT_PACKAGE
        return Bundle.module.path(forResource: "minganci", ofType: "txt")
        #else
        let bundles = [Bundle.main, Bundle(for: PTCheckFWords.self)]
        for bundle in bundles {
            if let resourceBundleURL = bundle.url(forResource: "PooToolsCheckDirtyWordResource", withExtension: "bundle"),
               let resourceBundle = Bundle(url: resourceBundleURL),
               let path = resourceBundle.path(forResource: "minganci", ofType: "txt") {
                return path
            }
            if let path = bundle.path(forResource: "minganci", ofType: "txt") {
                return path
            }
        }
        return nil
        #endif
    }
    
    func freeFilter() {
        root.removeAllObjects()
    }
}
