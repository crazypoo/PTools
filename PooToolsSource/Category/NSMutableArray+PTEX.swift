//
//  NSMutableArray+ShuffleEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public extension NSMutableArray {
    //MARK: 打亂原始內部數據的內容排序
    ///打亂原始內部數據的內容排序
    func shuffle() {
        for i in (0...(count - 1)).reversed() {
            let j = arc4random() % UInt32(i)
            exchangeObject(at: Int(j), withObjectAt: i)
        }
    }
    
    func randomizedArray() -> NSMutableArray {
        let results = NSMutableArray(array: self)
        var i = results.count
        i -= 1
        while i > 0 {
            let j = arc4random() % UInt32(i + 1)
            results.exchangeObject(at: i, withObjectAt: Int(j))
        }
        return results
    }
}
