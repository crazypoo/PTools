//
//  PTBaseModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/1.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import KakaJSON

open class PTBaseModel: Convertible {
    required public init() {}
        
    // 实现kj_modelKey方法
    // 会传入模型的属性`property`作为参数，返回值就是属性对应的key
    open func kj_modelKey(from property: KakaJSON.Property) -> ModelPropertyKey {
        property.name
    }
    
    open func kj_modelValue(from jsonValue:Any?,_ property:KakaJSON.Property) -> Any? {
        return jsonValue
    }
}
