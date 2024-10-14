//
//  CGSize+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension CGSize {
    static var regularIconSize: CGSize { Inspector.sharedInstance.appearance.regularIconSize }

    static var elementIconSize: CGSize { Inspector.sharedInstance.appearance.elementIconSize }

    static var actionIconSize: CGSize { Inspector.sharedInstance.appearance.actionIconSize }
}

extension CGSize {
    init(_ size: CGFloat) {
        self.init(width: size, height: size)
    }
}
