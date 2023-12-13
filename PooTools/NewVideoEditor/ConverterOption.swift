//
//  ConverterOption.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVKit

public struct ConverterOption {
    public var trimRange: (Double,Double) = (0.0,1.0)
    public var convertCrop: ConverterCrop?
    public var rotate: CGFloat?
    public var quality: String?
    public var isMute: Bool
    public var speed:Double = 1

    public init(trimRange: (Double,Double), convertCrop: ConverterCrop?, rotate: CGFloat?, quality: String?, isMute: Bool = false,speed:Double = 1) {
        self.trimRange = trimRange
        self.convertCrop = convertCrop
        self.rotate = rotate
        self.quality = quality
        self.isMute = isMute
        self.speed = speed
    }
}
