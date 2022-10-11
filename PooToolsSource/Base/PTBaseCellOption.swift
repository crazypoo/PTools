//
//  PTBaseCellOption.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwipeCellKit

public class PTBaseNormalCell: UICollectionViewCell {
    override init(frame:CGRect)
    {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func cellSize() -> CGSize
    {
        return CGSize(width: 1, height: 1)
    }
    
    class func cellIdentifier() -> String?
    {
        return "\(type(of: self))"
    }
    
    class func cellSizeByClass() -> NSNumber?
    {
        return NSNumber(value: true)
    }
    
    class func cellSizeValue() -> NSValue?
    {
        return NSValue(cgSize: cellSize())
    }
}

public class PTBaseSwipeCell: SwipeCollectionViewCell {
    override init(frame:CGRect)
    {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func cellSize() -> CGSize
    {
        return CGSize(width: 1, height: 1)
    }
    
    class func cellIdentifier() -> String?
    {
        return "\(type(of: self))"
    }
    
    class func cellSizeByClass() -> NSNumber?
    {
        return NSNumber(value: true)
    }
    
    class func cellSizeValue() -> NSValue?
    {
        return NSValue(cgSize: cellSize())
    }
}
