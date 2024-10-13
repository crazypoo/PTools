//
//  UIImage+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation

extension UIImage {
    func withOptions(_ imageOptions: UIImage.Option...) -> UIImage {
        withOptions(imageOptions)
    }
    
    func withOptions(_ imageOptions: UIImage.Options) -> UIImage {
        var newImage = self
        
        imageOptions.forEach { option in
            switch option {
            case let .renderingMode(renderingMode):
                newImage = newImage.withRenderingMode(renderingMode)
                
            #if swift(>=5.0)
            case let .tintColor(tintColor, renderingMode):
                newImage = newImage.withTintColor(tintColor, renderingMode: renderingMode)
            #endif
                
            case let .size(size):
                newImage = newImage.resized(size)
            }
        }
        
        return newImage
    }
    
    typealias Options = [Option]
    
    enum Option {
        /// The rendering mode controls how UIKit uses color information to display an image.
        case renderingMode(RenderingMode)
        
        #if swift(>=5.0)
        case tintColor(_ tintColor: UIColor, renderingMode: RenderingMode = .automatic)
        #endif

        case size(CGSize)
        
    }
}

public extension UIImage {
    
    func resized(_ newSize: CGSize) -> UIImage {
        guard newSize != size else {
            return self
        }
        
        let aspectRect = AVMakeRect(
            aspectRatio: size,
            insideRect: CGRect(
                origin: .zero,
                size: newSize
            )
        )
        
        let renderer = UIGraphicsImageRenderer(size: aspectRect.size)
        
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: aspectRect.size))
        }.withRenderingMode(renderingMode)
        
    }
    
}
