//
//  UITabBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

public extension UITabBar {
    
    /**
        Set appearance for tab bar.
     */
    func setAppearance(_ value: TabBarAppearance) {
        self.standardAppearance = value.standardAppearance
        if #available(iOS 15.0, tvOS 15.0, *) {
            self.scrollEdgeAppearance = value.scrollEdgeAppearance
        }
    }
    
    /**
        Appearance cases.
     */
    enum TabBarAppearance {
        
        case transparentAlways
        case transparentStandardOnly
        case opaqueAlways
        
        public var standardAppearance: UITabBarAppearance {
            let appearance = UITabBarAppearance()
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
        
        public var scrollEdgeAppearance: UITabBarAppearance {
            let appearance = UITabBarAppearance()
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
