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
        default:
            return nil
        }
    }
}
