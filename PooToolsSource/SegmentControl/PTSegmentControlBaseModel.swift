//
//  PTSegmentControlBaseModel.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/12.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public final class PTSegmentControlBaseModel: NSObject,@unchecked Sendable {
    public var categoryName:String = ""
    public var subTitle:String = ""
    public var imageURL:String = ""
    
    public override init() {
        super.init()
    }
}
