//
//  UINavigationController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UINavigationController {
    convenience init(_ options: Option...) {
        self.init()
        apply(navigationControllerOptions: options)
    }
}

public extension UINavigationController {
    
    func apply(navigationControllerOptions: UINavigationController.Option...) {
        apply(navigationControllerOptions: navigationControllerOptions)
    }
        
    func apply(navigationControllerOptions: UINavigationController.Options) {
        navigationControllerOptions.forEach { option in
            switch option {
            case let .viewControllers(viewControllers):
                self.viewControllers = viewControllers
                
            case let .isNavigationBarHidden(isNavigationBarHidden):
                self.isNavigationBarHidden = isNavigationBarHidden
                
            case let .isToolbarHidden(isToolbarHidden):
                self.isToolbarHidden = isToolbarHidden
                
            case let .navigationControllerDelegate(delegate):
                self.delegate = delegate
                
            case let .hidesBarsWhenKeyboardAppears(hidesBarsWhenKeyboardAppears):
                self.hidesBarsWhenKeyboardAppears = hidesBarsWhenKeyboardAppears
                
            case let .hidesBarsOnSwipe(hidesBarsOnSwipe):
                self.hidesBarsOnSwipe = hidesBarsOnSwipe
                
            case let .hidesBarsWhenVerticallyCompact(hidesBarsWhenVerticallyCompact):
                self.hidesBarsWhenVerticallyCompact = hidesBarsWhenVerticallyCompact
                
            case let .hidesBarsOnTap(hidesBarsOnTap):
                self.hidesBarsOnTap = hidesBarsOnTap
                
            case let .viewControllerOptions(viewControllerOptions):
                apply(viewControllerOptions: viewControllerOptions)
            }
        }
    }
    
    typealias Options = [Option]
    
    enum Option {
        /// The view controllers currently on the navigation stack.
        case viewControllers([UIViewController])
        
        /// A Boolean value that indicates whether the navigation bar is hidden.
        case isNavigationBarHidden(Bool)
        
        /// A Boolean indicating whether the navigation controller’s built-in toolbar is visible.
        case isToolbarHidden(Bool)
        
        /// The delegate of the navigation controller object.
        case navigationControllerDelegate(UINavigationControllerDelegate?)
        
        /// A Boolean value indicating whether the navigation controller hides its bars when the keyboard appears.
        case hidesBarsWhenKeyboardAppears(Bool)

        /// A Boolean value indicating whether the navigation bar hides its bars in response to a swipe gesture.
        case hidesBarsOnSwipe(Bool)
        
        /// A Boolean value indicating whether the navigation controller hides its bars in a vertically compact environment.
        case hidesBarsWhenVerticallyCompact(Bool)
        
        /// A Boolean value indicating whether the navigation controller allows hiding of its bars using a tap gesture.
        case hidesBarsOnTap(Bool)
        
        case viewControllerOptions(UIViewController.Options)
        
        // MARK: - Convenience
        
        public static func viewControllers(_ viewController: UIViewController...) -> Self {
            .viewControllers(viewController)
        }
        
        public static func rootViewController(_ rootViewController: UIViewController) -> Self {
            .viewControllers([rootViewController])
        }
        
        public static func viewControllerOptions(_ options: UIViewController.Option...) -> Self {
            .viewControllerOptions(options)
        }
        
        public static func viewOptions(_ options: UIView.Option...) -> Self {
            .viewControllerOptions(.viewOptions(options))
        }
        
        public static func popoverPresentationControllerOptions(_ options: UIPopoverPresentationController.Option...) -> Self {
            .viewControllerOptions(.popoverPresentationControllerOptions(options))
        }
    }
}
