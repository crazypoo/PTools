//
//  MovieFileType.swift
//  KakaposExamples
//
//  Created by Condy on 2023/7/31.
//

import Foundation
import AVFoundation

enum MovieFileType {
    case mov
    case mp4
    case m4a
    case m4v
    case gp
    case gp2
}

extension MovieFileType {
    var avFileType: AVFileType {
        switch self {
        case .mov:
            return .mov
        case .mp4:
            return .mp4
        case .m4a:
            return .m4a
        case .m4v:
            return .m4v
        case .gp:
            return .mobile3GPP
        case .gp2:
            return .mobile3GPP2
        }
    }
    
    static func from(url: URL) -> MovieFileType? {
        switch url.pathExtension.lowercased() {
        case "mp4":
            return .mp4
        case "mov":
            return .mov
        case "m4a":
            return .m4a
        case "m4v":
            return .m4v
        case "3gp":
            return .gp
        case "3gp2":
            return .gp2
        default:
            return nil
        }
    }
}
