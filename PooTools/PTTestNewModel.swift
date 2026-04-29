//
//  PTTestNewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/8.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import KakaJSON


//MARK: Popover
class LXSwiftBaseModel: Convertible {
    var code:String = ""
    var tip:String = ""
    required init() {
    }
}

class LXHomePopoverModel:Convertible {
    required init() {
    }
    var image:String = ""
    var couponId:String = ""
}

class LXHomePopoverMainModel:LXSwiftBaseModel {
    var msg:LXHomePopoverModel?
}
