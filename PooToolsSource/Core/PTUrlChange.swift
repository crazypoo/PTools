//
//  PTUrlChange.swift
//  Diou
//
//  Created by ken lam on 2021/10/16.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

@objcMembers
public class PTUrlChange: NSObject {

    public class func getRange(text: String, findText: String) -> [Int] {
        // 如果 text 是空字符串，直接返回空数组
        if text.stringIsEmpty() {
            return []
        }

        var arrayRanges: [Int] = []
        var searchRange = text.startIndex..<text.endIndex
        
        while let range = text.range(of: findText, options: .caseInsensitive, range: searchRange) {
            // 获取匹配文本的起始位置
            let location = text.distance(from: text.startIndex, to: range.lowerBound)
            arrayRanges.append(location)

            // 更新搜索范围，继续查找后续的匹配项
            searchRange = range.upperBound..<text.endIndex
        }

        return arrayRanges
    }}
