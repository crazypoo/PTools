//
//  PTContrastDisplayContext.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif

public extension DynamicColor {
    /**
     Used to describe the context of display of 2 colors.

     Based on WCAG: https://www.w3.org/TR/2008/REC-WCAG20-20081211/#visual-audio-contrast-contrast
     */
    enum ContrastDisplayContext {
        /**
         A standard text in a normal context.
         */
        case standard
        /**
         A large text in a normal context.
         You can look here for the definition of "large text":
         https://www.w3.org/TR/2008/REC-WCAG20-20081211/#larger-scaledef
         */
        case standardLargeText
        /**
         A standard text in an enhanced context.
         Enhanced means that you want to be accessible (and AAA compliant in WCAG)
         */
        case enhanced
        /**
         A large text in an enhanced context.
         Enhanced means that you want to be accessible (and AAA compliant in WCAG)
         You can look here for the definition of "large text":
         https://www.w3.org/TR/2008/REC-WCAG20-20081211/#larger-scaledef
         */
        case enhancedLargeText

        var minimumContrastRatio: CGFloat {
            switch self {
            case .standard:
              return 4.5
            case .standardLargeText:
              return 3.0
            case .enhanced:
              return 7.0
            case .enhancedLargeText:
              return 4.5
            }
        }
    }
}

