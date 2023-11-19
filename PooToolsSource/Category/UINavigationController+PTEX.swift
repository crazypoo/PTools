//
//  UINavigationController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit
import SwifterSwift

public extension UINavigationController {
    
    convenience init(rootViewController: UIViewController, prefersLargeTitles: Bool) {
        self.init(rootViewController: rootViewController)
        #if os(iOS)
        navigationBar.prefersLargeTitles = prefersLargeTitles
        #endif
    }    
}
#endif
