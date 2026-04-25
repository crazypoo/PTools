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
    
    // MARK: - Computed Properties
    
    /// 垂直方向总间距
    var verticalInsets: CGFloat { top + bottom }
    
    /// 水平方向总间距
    var horizontalInsets: CGFloat { leading + trailing }
    
    /// 转换为 UIEdgeInsets (默认从左到右 LTR)
    var edgeInsets: UIEdgeInsets {
        UIEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
    }
    
    /// 转换为 UIEdgeInsets (支持从右到左 RTL)
    var rightToLeftEdgeInsets: UIEdgeInsets {
        UIEdgeInsets(top: top, left: trailing, bottom: bottom, right: leading)
    }
    
    // MARK: - Modifiers
    
    /// 修改当前 insets (In-place 修改)
    mutating func update(
        top: CGFloat? = nil,
        leading: CGFloat? = nil,
        bottom: CGFloat? = nil,
        trailing: CGFloat? = nil
    ) {
        if let top { self.top = top }
        if let leading { self.leading = leading }
        if let bottom { self.bottom = bottom }
        if let trailing { self.trailing = trailing }
    }

    /// 返回修改后的新 insets (链式调用)
    func with(
        top: CGFloat? = nil,
        leading: CGFloat? = nil,
        bottom: CGFloat? = nil,
        trailing: CGFloat? = nil
    ) -> NSDirectionalEdgeInsets {
        var copy = self
        // 直接复用 update 方法，避免代码重复
        copy.update(top: top, leading: leading, bottom: bottom, trailing: trailing)
        return copy
    }
}
