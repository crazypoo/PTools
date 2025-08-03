//
//  UIToolbar+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && os(iOS)
import UIKit

public extension UIToolbar {
    
    /**
        Set appearance for tab bar.
     */
    func setAppearance(_ value: ToolbarAppearance) {
        self.standardAppearance = value.standardAppearance
        if #available(iOS 15.0, tvOS 15.0, *) {
            self.scrollEdgeAppearance = value.scrollEdgeAppearance
        }
    }
    
    /**
        Appearance cases.
     */
    enum ToolbarAppearance {
        
        case transparentAlways
        case transparentStandardOnly
        case opaqueAlways
        
        public var standardAppearance: UIToolbarAppearance {
            let appearance = UIToolbarAppearance()
            switch self {
            case .transparentAlways:
                appearance.configureWithTransparentBackground()
                return appearance
            case .transparentStandardOnly:
                appearance.configureWithDefaultBackground()
                return appearance
            case .opaqueAlways:
                appearance.configureWithDefaultBackground()
                return appearance
            }
        }
        
        public var scrollEdgeAppearance: UIToolbarAppearance {
            let appearance = UIToolbarAppearance()
            switch self {
            case .transparentAlways:
                appearance.configureWithTransparentBackground()
                return appearance
            case .transparentStandardOnly:
                appearance.configureWithTransparentBackground()
                return appearance
            case .opaqueAlways:
                appearance.configureWithDefaultBackground()
                return appearance
            }
        }
    }
}
#endif
