//
//  PTSheetEXCombos.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

@MainActor
public extension UIView {
    /// 兼容版本的安全区域内边距
    @available(*, deprecated, message: "iOS 17+ 请直接使用 safeAreaInsets")
    var compatibleSafeAreaInsets: UIEdgeInsets {
        self.safeAreaInsets
    }
}

@MainActor
public extension CALayer {
    /// 兼容版本的圆角遮罩
    @available(*, deprecated, message: "iOS 17+ 请直接使用 maskedCorners")
    var compatibleMaskedCorners: CACornerMask {
        get { self.maskedCorners }
        set { self.maskedCorners = newValue }
    }
}

@MainActor
public extension UIViewController {
    /// 兼容版本的附加安全区域内边距
    @available(*, deprecated, message: "iOS 17+ 请直接使用 additionalSafeAreaInsets")
    var compatibleAdditionalSafeAreaInsets: UIEdgeInsets {
        get { self.additionalSafeAreaInsets }
        set { self.additionalSafeAreaInsets = newValue }
    }
}
#endif // os(iOS) || os(tvOS) || os(watchOS)
