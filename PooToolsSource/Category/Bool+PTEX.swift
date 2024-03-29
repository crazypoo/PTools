//
//  Bool+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

extension Bool: PTProtocolCompatible {}
public extension PTPOP where Base == Bool {
    //MARK: Swift的Bool轉Int
    ///Swift的Bool轉Int
    var boolToInt:Int {
        base ? 1 : 0
    }
}
