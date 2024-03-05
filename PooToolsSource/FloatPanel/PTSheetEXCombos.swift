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
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        } else {
            return .zero
        }
    }
}

extension CALayer {
    public var compatibleMaskedCorners: CACornerMask {
        get {
            if #available(iOS 11.0, *) {
                return self.maskedCorners
            } else {
                return []
            }
        }
        set {
            if #available(iOS 11.0, *) {
                self.maskedCorners = newValue
            }
        }
    }
}

extension UIViewController {
    public var compatibleAdditionalSafeAreaInsets: UIEdgeInsets {
        get {
            if #available(iOS 11.0, *) {
                return self.additionalSafeAreaInsets
            } else {
                return .zero
            }
        }
        set {
            if #available(iOS 11.0, *) {
                self.additionalSafeAreaInsets = newValue
            }
        }
    }
}

#endif
