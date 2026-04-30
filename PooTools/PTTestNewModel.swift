//
//  PTTestNewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/8.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SmartCodable


class LXSiwftBaseModel:SmartCodableX {
    var code:String = ""
    var tip:String = ""
    required init() {}
}

//MARK: Popover
class LXHomePopoverModel:LXSiwftBaseModel {
    var image:String = ""
    var couponId:String = ""
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}

class LXHomePopoverMainModel:LXSiwftBaseModel {
    @SmartFlat var msg:LXHomePopoverModel?
}

//MARK: 首頁Banner
class YDSBaseModelEX: PTModelProtocol {
    var code:String = ""
    var tips:String = ""
    var error:String = ""
    var status:Int = 0
    var timestamp:String = ""
    var path:String = ""
    required init() {}
}

class YDSBaseResultModel: PTModelProtocol {
    var pages: Int = 0
    var startRow: String = ""
    var endRow: String = ""
    var recordsFiltered: String = ""
    var recordsTotal: Int = 0
    var pageNum: String = ""
    required init() {}
}

/*
 继承用聪明子分类
 */
@SmartSubclass
class YDSBaseModel: YDSBaseModelEX {
    var msg:String = ""
}

@SmartSubclass
class YDSHomeBannerMainModel:YDSBaseModel {
    @SmartAny var result:YDSHomeBannerResultModel?
}

@SmartSubclass
class YDSHomeBannerResultModel:YDSBaseResultModel {
    @SmartAny var data:[YDSHomeBannerModel] = []
}

class YDSHomeBannerModel: SmartCodableX {
    var id:String = ""
    var content:String = ""
    var name:String = ""
    var pic:String = ""
    var createdDate:String = ""
    ///1商品2消息3网址4其他5开屏6商品7兑换码
    var type:Int = 0
    var sort:Int = 0
    required init() {}
}
