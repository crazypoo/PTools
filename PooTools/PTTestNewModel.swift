//
//  PTTestNewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/8.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
//import MetaCodable
//import HelperCoders
import KakaJSON

//@Codable
//struct PTTestNewSubModel {
//    var bkey:String
//}
//
//@Codable
//struct PTTestNewSub1Model {
//    var ckey:String
// }
//
//@Codable
//struct PTTestNewModel {
//    var msg:[PTTestNewSubModel]
//    @Default("")
//    var akey:String
//    @CodedBy(ValueCoder<Bool>())
//    var abool:Bool
//    var dkey:PTTestNewSub1Model
//    
//    @CodedAt("hello.b")
//    var helloB:String
//}


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
