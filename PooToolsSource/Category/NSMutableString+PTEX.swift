//
//  NSMutableString+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 16/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

public extension NSMutableString {
    //MARK: 更改字符串的內部標籤
    ///更改字符串的內部標籤
    func replaceFirstTagItoArray(_ array:NSMutableArray) ->Bool
    {
        let openTagRange = self.range(of: "<")
        if openTagRange.length == 0
        {
            return false
        }
        let closeTagRange = self.range(of: ">",options: .caseInsensitive,range: NSMakeRange(openTagRange.location + openTagRange.length, length - (openTagRange.location + openTagRange.length)))
        if closeTagRange.length == 0
        {
            return false
        }
        let range = NSMakeRange(openTagRange.location, closeTagRange.location - openTagRange.location + 1)
        let tag = substring(with: range).nsString
        self.replaceCharacters(in: range, with: "")
        let isEndTag = tag.range(of: "<").length == 2
        if isEndTag
        {
            let openTag = tag.replacingOccurrences(of: "</", with: "<")
            let count = array.count
            var i = count - 1
            while i >= 0 {
                let dict = array[i] as? [AnyHashable : Any]
                let dtag = dict?["tag"] as? String
                if dtag == openTag {
                    let loc = dict?["loc"] as? NSNumber
                    if loc?.intValue ?? 0 < range.location {
                        array.remove(i)
                        let strippedTag = (openTag as NSString).substring(with: NSRange(location: 1, length: openTag.count - 2))
                        if let loc {
                            array.append([
                                "loc": loc,
                                "tag": strippedTag,
                                "endloc": NSNumber(value: range.location)
                            ] as [String : Any])
                        }
                    }
                    break
                }
                i -= 1
            }
        }
        else
        {
            array.add(["loc": NSNumber(value: range.location),"tag":tag])
        }
        return true
    }
    
    func replaceAllTags(intoArray array: NSMutableArray) {
        while replaceFirstTagItoArray(array) {
        }
    }
}
