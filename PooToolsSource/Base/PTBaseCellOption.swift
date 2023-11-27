//
//  PTBaseCellOption.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
#if POOTOOLS_SWIPECELL
import SwipeCellKit
#endif

@objcMembers
open class PTBaseNormalCell: UICollectionViewCell {
    override public init(frame:CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
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

#if POOTOOLS_SWIPECELL
@objcMembers
open class PTBaseSwipeCell: SwipeCollectionViewCell {
    override public init(frame:CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
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
#endif
