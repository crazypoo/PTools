//
//  NSDirectionalEdgeInsets+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension NSDirectionalEdgeInsets {
    // MARK: - init(insets:)
    
    init(insets: UIEdgeInsets) {
        self.init(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right
        )
    }
    
    init<T: BinaryFloatingPoint>(insets: T) {
        self.init(
            top: insets,
            leading: insets,
            bottom: insets,
            trailing: insets
        )
    }
    
    init<T: RawRepresentable>(insets: T) where T.RawValue: BinaryFloatingPoint {
        self.init(
            top: CGFloat(insets.rawValue),
            leading: CGFloat(insets.rawValue),
            bottom: CGFloat(insets.rawValue),
            trailing: CGFloat(insets.rawValue)
        )
    }
    
    // MARK: - init(horizontal:vertical:)
    
    init<T: BinaryFloatingPoint>(horizontal: T? = nil, vertical: T? = nil) {
        self.init(
            top: vertical ?? .zero,
            leading: horizontal ?? .zero,
            bottom: vertical ?? .zero,
            trailing: horizontal ?? .zero
        )
    }
    
    init<T: RawRepresentable>(horizontal: T? = nil, vertical: T? = nil) where T.RawValue: BinaryFloatingPoint {
        self.init(
            top: vertical?.rawValue ?? .zero,
            leading: horizontal?.rawValue ?? .zero,
            bottom: vertical?.rawValue ?? .zero,
            trailing: horizontal?.rawValue ?? .zero
        )
    }
    
    // MARK: - init(top:leading:bottom:trailing)

    init<T: BinaryFloatingPoint>(top: T? = nil, leading: T? = nil, bottom: T? = nil, trailing: T? = nil) {
        self.init(
            top: CGFloat(top ?? .zero),
            leading: CGFloat(leading ?? .zero),
            bottom: CGFloat(bottom ?? .zero),
            trailing: CGFloat(trailing ?? .zero)
        )
    }
    
    init<T: RawRepresentable>(top: T? = nil, leading: T? = nil, bottom: T? = nil, trailing: T? = nil) where T.RawValue: BinaryFloatingPoint {
        self.init(
            top: top?.rawValue ?? .zero,
            leading: leading?.rawValue ?? .zero,
            bottom: bottom?.rawValue ?? .zero,
            trailing: trailing?.rawValue ?? .zero
        )
    }
    
    func verticalInsets() -> CGFloat {
        top + bottom
    }
    
    func horizontalInsets() -> CGFloat {
        leading + trailing
    }
    
    func edgeInsets() -> UIEdgeInsets {
        UIEdgeInsets(
            top: top,
            left: leading,
            bottom: bottom,
            right: trailing
        )
    }
    
    func rightToLeftEdgeInsets() -> UIEdgeInsets {
        UIEdgeInsets(
            top: top,
            left: trailing,
            bottom: bottom,
            right: leading
        )
    }
}
