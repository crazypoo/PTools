//
//  UIPopoverPresentationController+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIPopoverPresentationController {
    
    func apply(popoverPresentationControllerOptions: Option...) {
        apply(popoverPresentationControllerOptions: popoverPresentationControllerOptions)
    }
    
    func apply(popoverPresentationControllerOptions: Options) {
        popoverPresentationControllerOptions.forEach { option in
            switch option {
            case let .popoverPresentationDelegate(delegate):
                self.delegate = delegate
                
            case let .permittedArrowDirections(permittedArrowDirections):
                self.permittedArrowDirections = permittedArrowDirections
                
            case let .sourceView(sourceView):
                self.sourceView = sourceView
                
            case let .sourceRect(sourceRect):
                self.sourceRect = sourceRect
                
            case let .canOverlapSourceViewRect(canOverlapSourceViewRect):
                self.canOverlapSourceViewRect = canOverlapSourceViewRect
                
            case let .barButtonItem(barButtonItem):
                self.barButtonItem = barButtonItem
                
            case let .passthroughViews(passthroughViews):
                self.passthroughViews = passthroughViews
                
            case let .backgroundColor(backgroundColor):
                self.backgroundColor = backgroundColor
                
            case let .popoverLayoutMargins(popoverLayoutMargins):
                self.popoverLayoutMargins = popoverLayoutMargins
                
            case let .containerViewOptions(containerViewOptions):
                containerView?.apply(viewOptions: containerViewOptions)
            }
        }
    }
    
    typealias Options = [Option]
    
    enum Option {
        /// The delegate that handles popover-related messages.
        case popoverPresentationDelegate(UIPopoverPresentationControllerDelegate?)
        
        /// The arrow directions that you allow for the popover.
        case permittedArrowDirections(UIPopoverArrowDirection)
        
        /// The view containing the anchor rectangle for the popover.
        case sourceView(UIView?)
        
        /// The rectangle in the specified view in which to anchor the popover.
        case sourceRect(CGRect)
        
        /// A Boolean value indicating whether the popover can overlap its view rectangle.
        case canOverlapSourceViewRect(Bool)
        
        /// The bar button item on which to anchor the popover.
        case barButtonItem(UIBarButtonItem?)
        
        /// An array of views that the user can interact with while the popover is visible.
        case passthroughViews([UIView]?)
        
        /// The color of the popover’s backdrop view.
        case backgroundColor(UIColor?)
        
        /// The margins that define the portion of the screen in which it is permissible to display the popover.
        case popoverLayoutMargins(UIEdgeInsets)
        
        /// The appearance options of the container view.
        case containerViewOptions(UIView.Options)
        
        // MARK: - Convenience
        
        public static func containerViewOptions(_ options: UIView.Option...) -> Self {
            .containerViewOptions(options)
        }
    }
}
