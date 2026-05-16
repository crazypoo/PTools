//
//  ConverterOption.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVKit

public struct PTConverterOptionOutputType: Sendable {
    
    public var type: AVFileType
    
    // 提供一个默认构造，使行为与原来一致
    public init(type: AVFileType = .mov) {
        self.type = type
    }
    
    // 优化 2：省略冗余的 `get {}`，直接返回 switch 结果
    public var name: String {
        switch type {
        case .mov: return "mov"
        case .mp4: return "mp4"
        case .m4v: return "m4v"
        case .mobile3GPP: return "3gp"
        case .mobile3GPP2: return "3gp2"
        case .m4a: return "m4a"
        case .caf: return "caf"
        case .wav: return "wav"
        case .aiff: return "aiff"
        case .aifc: return "aifc"
        case .amr: return "amr"
        // case .mp3: return "mp3" // AVFileType 默认没有直接暴露 mp3，保持注释
        case .au: return "au"
        case .ac3: return "ac3"
        case .eac3: return "eac3"
        default: return "Unknown" // 优化 3：修复了原来的拼写错误 (Unknow -> Unknown)
        }
    }
}

public struct ConverterOption: Sendable {
    
    // 提示：元组 (Double, Double) 在 Swift 中是天然支持 Sendable 的
    public var trimRange: (Double, Double) = (0.0, 1.0)
    public var convertCrop: ConverterCrop?
    public var rotate: CGFloat?
    public var quality: String?
    public var isMute: Bool = false
    public var speed: Double = 1.0
    public var outputModel: PTConverterOptionOutputType = PTConverterOptionOutputType()    
}
