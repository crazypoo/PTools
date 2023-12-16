//
//  ConverterOption.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVKit

public class PTConverterOptionOutputType:NSObject {

    public var type:AVFileType = .mov
    public var name:String {
        get {
            switch type {
            case .mov:
                return "mov"
            case .mp4:
                return "mp4"
            case .m4v:
                return "m4v"
            case .mobile3GPP:
                return "3gp"
            case .mobile3GPP2:
                return "3gp2"
            default:
                return "Unknow"
            }
        }
    }
}

public struct ConverterOption {
    public var trimRange: (Double,Double) = (0.0,1.0)
    public var convertCrop: ConverterCrop?
    public var rotate: CGFloat?
    public var quality: String?
    public var isMute: Bool
    public var speed:Double = 1
    public var outputModel:PTConverterOptionOutputType = PTConverterOptionOutputType()

    public init(trimRange: (Double,Double), convertCrop: ConverterCrop?, rotate: CGFloat?, quality: String?, isMute: Bool = false,speed:Double = 1,outputModel:PTConverterOptionOutputType = PTConverterOptionOutputType()) {
        self.trimRange = trimRange
        self.convertCrop = convertCrop
        self.rotate = rotate
        self.quality = quality
        self.isMute = isMute
        self.speed = speed
        self.outputModel = outputModel
    }
}
