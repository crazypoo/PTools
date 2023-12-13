//
//  ConverterCrop.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public struct ConverterCrop {
    public var frame: CGRect
    public var contrastSize: CGSize

    public init(frame: CGRect, contrastSize: CGSize) {
        self.frame = frame
        self.contrastSize = contrastSize
    }
}
