//
//  PTBaseButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/9/23.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

open class PTBaseButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.expandClickEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
