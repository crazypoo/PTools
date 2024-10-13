//
//  UIEdgeInsets+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIEdgeInsets {
    
    init(top: CGFloat? = nil, left: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil) {
        self.init(
            top: top ?? .zero,
            left: left ?? .zero,
            bottom: bottom ?? .zero,
            right: right ?? .zero
        )
    }
    
    init(_ insets: CGFloat) {
        self.init(top: insets, left: insets, bottom: insets, right: insets)
    }
    
    init(horizontal: CGFloat? = nil, vertical: CGFloat? = nil) {
        self.init(
            top: vertical ?? .zero,
            left: horizontal ?? .zero,
            bottom: vertical ?? .zero,
            right: horizontal ?? .zero
        )
    }
    
    init<T: RawRepresentable>(top: T? = nil, left: T? = nil, bottom: T? = nil, right: T? = nil) where T.RawValue == CGFloat {
        self.init(
            top: top?.rawValue ?? .zero,
            left: left?.rawValue ?? .zero,
            bottom: bottom?.rawValue ?? .zero,
            right: right?.rawValue ?? .zero
        )
    }
    
    init<T: RawRepresentable>(_ insets: T) where T.RawValue == CGFloat {
        self.init(
            top: insets.rawValue,
            left: insets.rawValue,
            bottom: insets.rawValue,
            right: insets.rawValue
        )
    }
    
    init<T: RawRepresentable>(horizontal: T? = nil, vertical: T? = nil) where T.RawValue == CGFloat {
        self.init(
            top: vertical?.rawValue ?? .zero,
            left: horizontal?.rawValue ?? .zero,
            bottom: vertical?.rawValue ?? .zero,
            right: horizontal?.rawValue ?? .zero
        )
    }
    
    var verticalInsets: CGFloat { top + bottom }
    
    var horizontalInsets: CGFloat { left + right }
    
    func directionalEdgeInsets() -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
    
    func rightToLeftDirectionalEdgeInsets() -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: top, leading: right, bottom: bottom, trailing: left)
    }
}
