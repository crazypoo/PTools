//
//  PTCheckFWords.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/28.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import SwifterSwift

let EXIST = "isExists"

@objcMembers
public class PTCheckFWords: NSObject {
    public static let share = PTCheckFWords()
    
    fileprivate var root:NSMutableDictionary = NSMutableDictionary()
    public var isFilterClose:Bool = false
    
    public override init() {
        super.init()
        self.initFilter()
    }
    
    func initFilter()
    {
        let bundlePath = Bundle.init(path: PTUtils.cgBaseBundle().path(forResource: "PooTools", ofType: "bundle")!)
        let filePath = bundlePath?.path(forResource: "minganci", ofType: "txt")
        var dataFile:NSString?
        do{
            dataFile = try NSString(contentsOfFile: filePath!, encoding: String.Encoding.utf8.rawValue)
            let dataArr = dataFile?.components(separatedBy: "|")
            for item in dataArr!
            {
                if item.count > 0
                {
                    self.insertWords(words: item as NSString)
                }
            }
        }
        catch
        {
            
        }
    }
    
    func insertWords(words:NSString)
    {
        var node:NSMutableDictionary = self.root
        for i in stride(from: 0, to: words.length, by: 1)
        {
            let word = words.substring(with: NSRange(location: i, length: 1))
            if node.object(forKey: word) == nil
            {
                let dict = NSMutableDictionary()
                node.setObject(dict, forKey: word as NSCopying)
            }
            node = node.object(forKey: word) as! NSMutableDictionary
        }
        node.setObject(NSNumber(integerLiteral: 1), forKey: EXIST as NSCopying)
    }
    
    public func haveFWord(str:NSString)->Bool
    {        
        for i in stride(from: 0, to: str.length, by: 1)
        {
            let subString:NSString = str.substring(from: i) as NSString
            var node:NSMutableDictionary = self.root.mutableCopy() as! NSMutableDictionary
            var num = 0
            
            for j in stride(from: 0, to: subString.length, by: 1)
            {
                let word = subString.substring(with: NSRange(location: j, length: 1))
                if node.object(forKey: word) == nil
                {
                    break
                }
                else
                {
                    num += 1
                    node = node.object(forKey: word) as! NSMutableDictionary
                }
                
                if node.object(forKey: EXIST) != nil
                {
                    let nodeObj:NSNumber = node.object(forKey: EXIST) as! NSNumber
                    if nodeObj.intValue == 1
                    {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    public func filter(str:NSString)->NSString
    {
        if self.isFilterClose || self.root.count == 0
        {
            return str
        }
        
        let result:NSMutableString = str.mutableCopy() as! NSMutableString
        for var i in stride(from: 0, to: str.length, by: 1)
        {
            let subString:NSString = str.substring(from: i) as NSString
            var node:NSMutableDictionary = self.root.mutableCopy() as! NSMutableDictionary
            var num = 0
            
            for j in stride(from: 0, to: subString.length, by: 1)
            {
                let word = subString.substring(with: NSRange(location: j, length: 1))
                if node.object(forKey: word) == nil
                {
                    break
                }
                else
                {
                    num += 1
                    node = node.object(forKey: word) as! NSMutableDictionary
                }
                
                if node.object(forKey: EXIST) != nil
                {
                    let nodeObj:NSNumber = node.object(forKey: EXIST) as! NSNumber
                    if nodeObj.intValue == 1
                    {
                        let symbolStr:NSMutableString = NSMutableString()
                        for _ in stride(from: 0, to: num, by: 1)
                        {
                            symbolStr.append("*")
                        }
                        result.replaceCharacters(in: NSRange(location: i, length: num), with: symbolStr as String)
                        i += j
                        break
                    }
                }
            }
        }
        return result
    }
    
    func freeFilter()
    {
        self.root.removeAllObjects()
    }
}
