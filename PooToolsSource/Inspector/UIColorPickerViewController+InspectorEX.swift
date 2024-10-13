//
//  UIColorPickerViewController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

#if swift(>=5.3)
public extension UIColorPickerViewController {
    convenience init(_ options: Option...) {
        self.init(options)
    }
    
    convenience init(_ options: Options) {
        self.init()
        apply(colorPickerOptions: options)
    }
}

public extension UIColorPickerViewController {
    
    func apply(colorPickerOptions: Option...) {
        apply(colorPickerOptions: colorPickerOptions)
    }
    
    func apply(colorPickerOptions: Options) {
        colorPickerOptions.forEach { option in
            switch option {
            case let .colorPickerDelegate(delegate):
                self.delegate = delegate
                
            case let .selectedColor(selectedColor):
                self.selectedColor = selectedColor
                
            case let .supportsAlpha(supportsAlpha):
                self.supportsAlpha = supportsAlpha
                
            case let .viewControllerOptions(viewControllerOptions):
                self.apply(viewControllerOptions: viewControllerOptions)
            }
        }
    }
    
    typealias Options = [Option]
    
    enum Option {
        /// A view controller that handles the delegate actions.
        case colorPickerDelegate(UIColorPickerViewControllerDelegate?)
        
        /// The color selected by the user.
        case selectedColor(UIColor)
        
        /// A Boolean value that enables alpha value control.
        case supportsAlpha(Bool)
        
        case viewControllerOptions(UIViewController.Options)
        
        // MARK: - Convenience
        
        public static func viewOptions(_ options: UIView.Option...) -> Self {
            .viewControllerOptions(.viewOptions(options))
        }
        
        public static func viewControllerOptions(_ options: UIViewController.Option...) -> Self {
            .viewControllerOptions(options)
        }
        
        public static func popoverPresentationControllerOptions(_ options: UIPopoverPresentationController.Option...) -> Self {
            .viewControllerOptions(.popoverPresentationControllerOptions(options))
        }
    }
}

#endif
