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
            top: T(vertical ?? .zero),
            leading: T(horizontal ?? .zero),
            bottom: T(vertical ?? .zero),
            trailing: T(horizontal ?? .zero)
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
            top: CGFloat(T(top ?? .zero)),
            leading: CGFloat(T(leading ?? .zero)),
            bottom: CGFloat(T(bottom ?? .zero)),
            trailing: CGFloat(T(trailing ?? .zero))
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
    
    mutating func update(
        top: CGFloat? = nil,
        leading: CGFloat? = nil,
        bottom: CGFloat? = nil,
        trailing: CGFloat? = nil
    ) {
        if let top = top {
            self.top = top
        }
        if let leading = leading {
            self.leading = leading
        }
        if let bottom = bottom {
            self.bottom = bottom
        }
        if let trailing = trailing {
            self.trailing = trailing
        }
    }

    func with(
        top: CGFloat? = nil,
        leading: CGFloat? = nil,
        bottom: CGFloat? = nil,
        trailing: CGFloat? = nil
    ) -> NSDirectionalEdgeInsets {
        var copy = self

        if let top = top {
            copy.top = top
        }
        if let leading = leading {
            copy.leading = leading
        }
        if let bottom = bottom {
            copy.bottom = bottom
        }
        if let trailing = trailing {
            copy.trailing = trailing
        }

        return copy
    }

}
