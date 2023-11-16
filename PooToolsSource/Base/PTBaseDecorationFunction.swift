//
//  PTBaseDecorationFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
open class PTBaseDecorationView: UICollectionReusableView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PTAppBaseConfig.share.decorationBackgroundColor
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objcMembers
open class PTBaseDecorationView_Corner: UICollectionReusableView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PTAppBaseConfig.share.decorationBackgroundColor
        viewCorner(radius: PTAppBaseConfig.share.decorationBackgroundCornerRadius)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
