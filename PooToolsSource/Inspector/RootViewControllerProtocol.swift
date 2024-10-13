//
//  RootViewControllerProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@available(*, deprecated, renamed: "RootViewControllerProtocol")
typealias ContainerViewControllerProtocol = RootViewControllerProtocol

/// Navigation controllers, split view controller, and tab bar controllers conform to this protocol by defauilt.
public protocol RootViewControllerProtocol: UIViewController {}

extension UINavigationController: RootViewControllerProtocol {}

extension UISplitViewController: RootViewControllerProtocol {}

extension UITabBarController: RootViewControllerProtocol {}

extension UIAlertController: RootViewControllerProtocol {}

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
extension UIHostingController: RootViewControllerProtocol {}
#endif
