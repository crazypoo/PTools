//
//  PT.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
open class PTBaseCollectionReusableView: UICollectionReusableView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open class func cellSize() -> CGSize {
        CGSize(width: 1, height: 1)
    }

    open class func cellIdentifier() -> String {
        "\(type(of: self))"
    }
    
    open class func cellSizeByClass() -> NSNumber {
        NSNumber(value: true)
    }

    open class func cellSizeValue() -> NSValue {
        NSValue(cgSize: cellSize())
    }
}
