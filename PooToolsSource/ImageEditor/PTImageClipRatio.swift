//
//  PTImageClipRatio.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public struct PTClipStatus {
    var angle: CGFloat = 0
    var editRect: CGRect
    var ratio: PTImageClipRatio?
}

// MARK: 裁剪比例
public class PTImageClipRatio: NSObject {
    @objc public var title: String
    
    @objc public let whRatio: CGFloat
    
    @objc public let isCircle: Bool
    
    @objc public init(title: String, whRatio: CGFloat, isCircle: Bool = false) {
        self.title = title
        self.whRatio = isCircle ? 1 : whRatio
        self.isCircle = isCircle
        super.init()
    }
}

extension PTImageClipRatio {
    static func == (lhs: PTImageClipRatio, rhs: PTImageClipRatio) -> Bool {
        lhs.whRatio == rhs.whRatio && lhs.title == rhs.title
    }
}

public extension PTImageClipRatio {
    @objc static let custom = PTImageClipRatio(title: "custom", whRatio: 0)
    
    @objc static let circle = PTImageClipRatio(title: "circle", whRatio: 1, isCircle: true)
    
    @objc static let wh1x1 = PTImageClipRatio(title: "1 : 1", whRatio: 1)
    
    @objc static let wh3x4 = PTImageClipRatio(title: "3 : 4", whRatio: 3.0 / 4.0)
    
    @objc static let wh4x3 = PTImageClipRatio(title: "4 : 3", whRatio: 4.0 / 3.0)
    
    @objc static let wh2x3 = PTImageClipRatio(title: "2 : 3", whRatio: 2.0 / 3.0)
    
    @objc static let wh3x2 = PTImageClipRatio(title: "3 : 2", whRatio: 3.0 / 2.0)
    
    @objc static let wh9x16 = PTImageClipRatio(title: "9 : 16", whRatio: 9.0 / 16.0)
    
    @objc static let wh16x9 = PTImageClipRatio(title: "16 : 9", whRatio: 16.0 / 9.0)
}
