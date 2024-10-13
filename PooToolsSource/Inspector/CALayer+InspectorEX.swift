//
//  CALayer+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension CALayer {
    /// Applies the appearance options to the layer instance.
    /// - Parameter options: The layer appearance options.
    func apply(layerOptions: Option...) {
        apply(layerOptions: layerOptions)
    }
    
    /// Applies the appearance options to the layer instance.
    /// - Parameter options: The layer appearance options.
    func apply(layerOptions: Options) {
        layerOptions.forEach { option in
            switch option {
            case let .anchorPoint(anchorPoint):
                self.anchorPoint = anchorPoint
                
            case let .borderWidth(borderWidth):
                self.borderWidth = borderWidth
                
            case let .borderColor(borderColor):
                self.borderColor = borderColor
                
            case let .backgroundColor(backgroundColor):
                self.backgroundColor = backgroundColor
                
            case let .cornerRadius(cornerRadius):
                self.cornerRadius = cornerRadius
                
            case let .masksToBounds(masksToBounds):
                self.masksToBounds = masksToBounds
                
            case let .maskedCorners(maskedCorners):
                self.maskedCorners = maskedCorners
                
            case let .shadowOffset(shadowOffset):
                self.shadowOffset = shadowOffset
                
            case let .shadowColor(shadowColor):
                self.shadowColor = shadowColor
                
            case let .shadowRadius(shadowRadius):
                self.shadowRadius = shadowRadius
                
            case let .shadowOpacity(shadowOpacity):
                self.shadowOpacity = shadowOpacity
                
            case let .shadowPath(shadowPath):
                self.shadowPath = shadowPath
                
            case let .isOpaque(isOpaque):
                self.isOpaque = isOpaque
                
            case let .opacity(opacity):
                self.opacity = opacity
                
            case let .shouldRasterize(shouldRasterize):
                self.shouldRasterize = shouldRasterize
                
            case let .rasterizationScale(rasterizationScale):
                self.rasterizationScale = rasterizationScale
            }
        }
    }
    
    typealias Options = [Option]
    
    /// Describes the layer's appearance.
    enum Option {
        /// Defines the anchor point of the layer's bounds rectangle. Animatable.
        case anchorPoint(CGPoint)
        
        /// The width of the layer’s border. Animatable.
        case borderWidth(CGFloat)
        
        /// The color of the layer’s border. Animatable.
        case borderColor(CGColor)
        
        ///The background color of the receiver. Animatable.
        case backgroundColor(CGColor)
        
        /// The radius to use when drawing rounded corners for the layer’s background. Animatable.
        case cornerRadius(CGFloat)
        
        /// A Boolean indicating whether sublayers are clipped to the layer’s bounds. Animatable.
        case masksToBounds(Bool)
        
        /// Defines which of the four corners receives the masking when using `cornerRadius' property. Defaults to all four corners.
        case maskedCorners(CACornerMask)
        
        /// The offset (in points) of the layer’s shadow. Animatable.
        case shadowOffset(CGSize)
        
        /// The color of the layer’s shadow. Animatable.
        case shadowColor(CGColor)
        
        /// The blur radius (in points) used to render the layer’s shadow. Animatable.
        case shadowRadius(CGFloat)
        
        /// The opacity of the layer’s shadow. Animatable.
        case shadowOpacity(Float)
        
        /// The shape of the layer’s shadow. Animatable.
        case shadowPath(CGPath)
        
        /// A Boolean value indicating whether the layer contains completely opaque content.
        case isOpaque(Bool)
        
        /// The opacity of the receiver. Animatable.
        case opacity(Float)
        
        /// A Boolean that indicates whether the layer is rendered as a bitmap before compositing. Animatable
        case shouldRasterize(Bool)
        
        /// The scale at which to rasterize content, relative to the coordinate space of the layer. Animatable
        case rasterizationScale(CGFloat)
        
        // MARK: - Convenience
        public static func borderColor(_ color: UIColor) -> Self {
            .borderColor(color.cgColor)
        }
        
        public static func backgroundColor(_ color: UIColor) -> Self {
            .backgroundColor(color.cgColor)
        }
        
        public static func shadowColor(_ color: UIColor) -> Self {
            .shadowColor(color.cgColor)
        }
    }
}
