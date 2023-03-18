//
//  CGSize+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension CGSize
{
    static func from(archivedData data: Data) throws -> CGSize {
        var sizeObj = CGSize.zero
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        if let size = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? NSValue
        {
            sizeObj =  size.cgSizeValue
        }
        unarchiver.finishDecoding()
        return sizeObj
    }
    
    static func archiveData() throws -> Data
    {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
        return data ?? Data()
    }
}
