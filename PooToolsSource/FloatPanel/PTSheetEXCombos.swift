//
//  PTSheetEXCombos.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension UIView {
    public var compatibleSafeAreaInsets: UIEdgeInsets {
        return self.safeAreaInsets
    }
}

extension CALayer {
    public var compatibleMaskedCorners: CACornerMask {
        get {
            return self.maskedCorners
        }
        set {
            self.maskedCorners = newValue
        }
    }
}

extension UIViewController {
    public var compatibleAdditionalSafeAreaInsets: UIEdgeInsets {
        get {
            return self.additionalSafeAreaInsets
        }
        set {
            self.additionalSafeAreaInsets = newValue
        }
    }
}

#endif
