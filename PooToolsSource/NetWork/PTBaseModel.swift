//
//  PTBaseModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/1.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import HandyJSON
import KakaJSON

open class PTBaseModel: HandyJSON,Convertible {
    required public init() {}
    
    open func mapping(mapper: HelpingMapper) {   //自定义解析规则，日期数字颜色，如果要指定解析格式，子类实现重写此方法即可
        //        mapper <<<
        //            date <-- CustomDateFormatTransform(formatString: "yyyy-MM-dd")
        //
        //        mapper <<<
        //            decimal <-- NSDecimalNumberTransform()
        //
        //        mapper <<<
        //            url <-- URLTransform(shouldEncodeURLString: false)
        //
        //        mapper <<<
        //            data <-- DataTransform()
        //
        //        mapper <<<
        //            color <-- HexColorTransform()
    }
    
    // 实现kj_modelKey方法
    // 会传入模型的属性`property`作为参数，返回值就是属性对应的key
    open func kj_modelKey(from property: KakaJSON.Property) -> ModelPropertyKey {
        return property.name
    }
}
