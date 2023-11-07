//
//  UINavigationBar+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

// MARK: - UINavigationBar扩展,获得渐变颜色效果
public extension UINavigationBar {
    
    /// Applies a background gradient with the given colors
    func apply(gradient colors : [UIColor]) {
        var frameAndStatusBar: CGRect = bounds
        frameAndStatusBar.size.height += CGFloat.statusBarHeight() // add 20 to account for the status bar
        setBackgroundImage(UINavigationBar.gradient(size: frameAndStatusBar.size, colors: colors), for: .default)
    }
    
    /// Creates a gradient image with the given settings
    static func gradient(size : CGSize, 
                         colors : [UIColor]) -> UIImage? {
        // Turn the colors into CGColors
        let cgcolors = colors.map { $0.cgColor }
        
        // Begin the graphics context
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        
        // If no context was retrieved, then it failed
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // From now on, the context gets ended if any return happens
        defer { UIGraphicsEndImageContext() }
        
        // Create the Coregraphics gradient
        var locations : [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgcolors as NSArray as CFArray, locations: &locations) else { return nil }
        
        // Draw the gradient
        context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: size.width, y: 0.0), options: [])
        
        // Generate the image (the defer takes care of closing the context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /**
        Set appearance for navigation bar.
     */
    @available(iOS 13.0, tvOS 13.0, *)
    func setAppearance(_ value: NavigationBarAppearance) {
        self.standardAppearance = value.standardAppearance
        self.scrollEdgeAppearance = value.scrollEdgeAppearance
    }
    
    /**
        Appearance cases.
     */
    @available(iOS 13.0, tvOS 13.0, *)
    enum NavigationBarAppearance {
        
        case transparentAlways
        case transparentStandardOnly
        case opaqueAlways
        
        var standardAppearance: UINavigationBarAppearance {
            switch self {
            case .transparentAlways:
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                return appearance
            case .transparentStandardOnly:
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                return appearance
            case .opaqueAlways:
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                return appearance
            }
        }
        
        var scrollEdgeAppearance: UINavigationBarAppearance {
            switch self {
            case .transparentAlways:
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                return appearance
            case .transparentStandardOnly:
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                return appearance
            case .opaqueAlways:
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                return appearance
            }
        }
    }
}
