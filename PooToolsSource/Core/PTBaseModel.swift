//
//  PTBaseModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/1.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SmartCodable

open class PTBaseModel: SmartCodableX {
    required public init() {}
    
    open func didFinishMapping() {}
}

extension PTBaseModel: PTDiffableModel {
    
    public var diffId: String {
        return "\(type(of: self))_\(ObjectIdentifier(self))"
    }
    
    public var diffHash: Int {
        return 0 // 默认不参与 diff（避免性能问题）
    }
}
