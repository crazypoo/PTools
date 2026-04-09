//
//  PTSheetEXCombos.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

public extension UIView {
    /// 兼容版本的安全区域内边距
    var compatibleSafeAreaInsets: UIEdgeInsets {
        self.safeAreaInsets
    }
}

public extension CALayer {
    /// 兼容版本的圆角遮罩
    var compatibleMaskedCorners: CACornerMask {
        get { self.maskedCorners }
        set { self.maskedCorners = newValue }
    }
}

public extension UIViewController {
    /// 兼容版本的附加安全区域内边距
    var compatibleAdditionalSafeAreaInsets: UIEdgeInsets {
        get { self.additionalSafeAreaInsets }
        set { self.additionalSafeAreaInsets = newValue }
    }
}
#endif // os(iOS) || os(tvOS) || os(watchOS)
