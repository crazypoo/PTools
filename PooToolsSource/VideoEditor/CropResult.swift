//
//  CropResult.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public struct CropResult {
    public var error: Error?
    public var image: UIImage?
    public var cropFrame: CGRect?
    public var imageSize: CGSize?

    public init() { }

    public init(error: Error, cropFrame: CGRect? = nil, imageSize: CGSize? = nil) {
        self.error = error
        self.cropFrame = cropFrame
        self.imageSize = imageSize
    }

    public init(image: UIImage, cropFrame: CGRect? = nil, imageSize: CGSize? = nil) {
        self.image = image
        self.cropFrame = cropFrame
        self.imageSize = imageSize
    }
}
