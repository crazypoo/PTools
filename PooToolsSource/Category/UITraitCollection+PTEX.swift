//
//  UITraitCollection+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/2/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UITraitCollection {
    /// A trait collection containing only the light user interface style trait.
    static let light: UITraitCollection = .init(userInterfaceStyle: .light)

    /// A trait collection containing only the dark user interface style trait.
    static let dark: UITraitCollection = .init(userInterfaceStyle: .dark)

    /// Calls the passed closure only if iOS 13 or tvOS 13 SDKs are available.
    /// - Parameters:
    ///   - traitCollection: A trait collection that you want to compare to the current trait collection.
    ///   - closure: The closure for updating component appearance.
    func performForDifferentColorAppearance(comparedTo traitCollection: UITraitCollection?, closure: (() -> Void)) {
        closure()
    }
}
