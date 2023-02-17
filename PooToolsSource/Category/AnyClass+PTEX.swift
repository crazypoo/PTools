//
//  AnyClass+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 17/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit


public extension NSObject
{
    //MARK: 獲取一個Class中的Keys
    ///獲取一個Class中的Keys
    class func getClassName()
    {
        var count:UInt32 = 0
        let ivars = class_copyIvarList((self as AnyClass), &count)
        
        for i in 0..<count
        {
            let ivar = ivars![Int(i)]
            let cName = ivar_getName(ivar)!
            let keysName = String(utf8String: cName)
            PTLocalConsoleFunction.share.pNSLog(keysName!)
        }
        free(ivars)
    }
}
