//
//  PTImageEditorSticker.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public class PTBaseStickertState: NSObject {
    public let id: String
    public let image: UIImage
    public let originScale: CGFloat
    public let originAngle: CGFloat
    public let originFrame: CGRect
    public let gesScale: CGFloat
    public let gesRotation: CGFloat
    public let totalTranslationPoint: CGPoint
    
    public init(id: String,
         image: UIImage,
         originScale: CGFloat,
         originAngle: CGFloat,
         originFrame: CGRect,
         gesScale: CGFloat,
         gesRotation: CGFloat,
         totalTranslationPoint: CGPoint) {
        self.id = id
        self.image = image
        self.originScale = originScale
        self.originAngle = originAngle
        self.originFrame = originFrame
        self.gesScale = gesScale
        self.gesRotation = gesRotation
        self.totalTranslationPoint = totalTranslationPoint
        super.init()
    }
}

public class PTImageStickerState: PTBaseStickertState { }

public class PTTextStickerState: PTBaseStickertState {
    let text: String
    let textColor: UIColor
    let font: UIFont?
    let style: PTInputTextStyle
    
    init(id: String,
         text: String,
         textColor: UIColor,
         font: UIFont?,
         style: PTInputTextStyle,
         image: UIImage,
         originScale: CGFloat,
         originAngle: CGFloat,
         originFrame: CGRect,
         gesScale: CGFloat,
         gesRotation: CGFloat,
         totalTranslationPoint: CGPoint) {
        self.text = text
        self.textColor = textColor
        self.font = font
        self.style = style
        super.init(id: id,
                   image: image,
                   originScale: originScale,
                   originAngle: originAngle,
                   originFrame: originFrame,
                   gesScale: gesScale,
                   gesRotation: gesRotation,
                   totalTranslationPoint: totalTranslationPoint)
    }
}
