//
//  UIImageView+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIImageView {
    convenience init(_ options: Option...) {
        self.init(options)
    }
    
    convenience init(_ options: Options) {
        self.init()
        apply(imageViewOptions: options)
    }
}

public extension UIImageView {
    
    func apply(imageViewOptions: Options) {
        imageViewOptions.forEach { option in
            switch option {
            case let .image(image):
                self.image = image
                
            case let .highlightedImage(highlightedImage):
                self.highlightedImage = highlightedImage
                
            case let .isHighlighted(isHighlighted):
                self.isHighlighted = isHighlighted
                
            case let .highlightedAnimationImages(highlightedAnimationImages):
                self.highlightedAnimationImages = highlightedAnimationImages
                
            case let .animationImages(animationImages):
                self.animationImages = animationImages
                
            case let .animationDuration(animationDuration):
                self.animationDuration = animationDuration
                
            case let .animationRepeatCount(animationRepeatCount):
                self.animationRepeatCount = animationRepeatCount
                
            case let .viewOptions(viewOptions):
                apply(viewOptions: viewOptions)
                
            }
        }
    }

    typealias Options = [Option]
    
    enum Option {
        case image(UIImage?)
        case highlightedImage(UIImage?)
        case isHighlighted(Bool)
        case highlightedAnimationImages([UIImage]?)
        case animationImages([UIImage]?)
        case animationDuration(TimeInterval)
        case animationRepeatCount(Int)
        
        /// The options for the stack view.
        case viewOptions(UIView.Options)
        
        // MARK: - Convenience
        
        /// The image view’s background color.
        public static func backgroundColor(_ color: UIColor?) -> Self {
            .viewOptions(.backgroundColor(color))
        }
        
        /// The image view’s tint color.
        public static func tintColor(_ color: UIColor) -> Self {
            .viewOptions(.tintColor(color))
        }
        
        /// The options for the stack view.
        public static func viewOptions(_ options: UIView.Option...) -> Self {
            .viewOptions(options)
        }
        
        /// Describes the stack view layer's appearance.
        public static func layerOptions(_ options: CALayer.Option...) -> Self {
            .viewOptions(.layerOptions(options))
        }
        
        /// The priority with which a view resists being made smaller than its intrinsic width or height.
        public static func compressionResistance(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
            .viewOptions(.layoutCompression(.compressionResistance(priority, for: axis)))
        }
        
        /// The priority with which a view resists being made larger than its intrinsic width or height.
        public static func huggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
            .viewOptions(.layoutCompression(.huggingPriority(priority, for: axis)))
        }
    }
    
}
