//
//  PTBaseDecorationFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

open class PTBaseDecorationView: UICollectionReusableView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PTAppBaseConfig.share.decorationBackgroundColor
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class PTBaseDecorationView_Corner: UICollectionReusableView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PTAppBaseConfig.share.decorationBackgroundColor
        self.viewCorner(radius: PTAppBaseConfig.share.decorationBackgroundCornerRadius)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
