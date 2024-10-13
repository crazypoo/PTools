//
//  UIFont+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIFont {
    static func preferredFont(
        forTextStyle textStyle: TextStyle,
        with symbolicTraits: UIFontDescriptor.SymbolicTraits,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIFont {
        UIFont.preferredFont(forTextStyle: textStyle, compatibleWith: traitCollection).withTraits(symbolicTraits)
    }
    
    func bold() -> UIFont {
        withTraits(.traitBold)
    }

    func italic() -> UIFont {
        withTraits(.traitItalic)
    }
    
    func monoSpace() -> UIFont {
        withTraits(.traitMonoSpace)
    }
    
    func withTraits(_ symbolicTraits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) else {
            assertionFailure("Could not resolve the specified symbolic traits: \(symbolicTraits)")
            return self
        }
        
        //size `zero` means keep the size as it is
        return UIFont(descriptor: descriptor, size: .zero)
    }
}
