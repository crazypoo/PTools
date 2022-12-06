//
//  NSData+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/12/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension NSData
{
    @objc func getImageDataType() -> PTAboutImageType {
        var c: UInt8 = 0
        self.getBytes(&c, length: 1)
        switch c {
        case 0xff:
            return .JPEG
        case 0x89:
            return .PNG
        case 0x47:
            return .GIF
        case 0x49, 0x4d:
            return .TIFF
        case 0x52:
            if (self.count) < 12 {
                return .UNKNOW
            }
            var testString = NSString(data: self.subdata(with: NSMakeRange(0, 12)), encoding: NSASCIIStringEncoding)
    
            if testString?.hasPrefix("RIFF") ?? false && testString?.hasSuffix("WEBP") ?? false {
                return .WEBP
            }
            return .UNKNOW
        default:
            break
        }
        return .UNKNOW
    }
}
