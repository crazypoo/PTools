//
//  AutoScale+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/6.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

public enum InchWidth: Double {
    case NoTouchIDModel = 320
    case TouchIDNormalModel = 375
    case TouchIDPlusModel = 414
    case FaceIDMini = 360
    case FaceIDNormal = 390
    case FaceIDProMax = 428
    
    static var baseWidth: InchWidth {
        return .TouchIDNormalModel
    }
}

public enum InchHeight: Double {
    case NoTouchIDModel = 568
    case TouchIDNormalModel = 667
    case TouchIDPlusModel = 736
    case FaceIDX = 812
    case FaceIDXR = 896
    case FaceIDMini = 780
    case FaceIDNormal = 844
    case FaceIDProMax = 926
}

//deviceSafeAreaInsets

public extension Double {
    
    private func rounded(_ decimalPlaces: Int) -> Double {
        let divisor = pow(10.0, Double(max(0, decimalPlaces)))
        return (self * divisor).rounded() / divisor
    }
    
    func autoWidth(_ inch: InchWidth = .TouchIDNormalModel) -> Double {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            return self
        }
        let base = inch.rawValue
        let screenWidth = Double(UIScreen.main.bounds.width)
        let screenHeight = Double(UIScreen.main.bounds.height)
        let width = min(screenWidth, screenHeight) - Double(deviceSafeAreaInsets().left - deviceSafeAreaInsets().right)
        return (self * (width / base)).rounded(3)
    }
    
    func autoHeight(_ inch: InchHeight = .TouchIDNormalModel) -> Double {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            return self
        }
        let base = inch.rawValue
        let screenWidth = Double(UIScreen.main.bounds.width)
        let screenHeight = Double(UIScreen.main.bounds.height)
        let height = max(screenWidth, screenHeight) - Double(deviceSafeAreaInsets().top - deviceSafeAreaInsets().bottom)
        return (self * (height / base)).rounded(3)
    }
}

public extension BinaryInteger {
    
    func autoWidth(_ inch: InchWidth = .TouchIDNormalModel) -> Double {
        let temp = Double("\(self)") ?? 0
        return temp.autoWidth(inch)
    }
    func autoWidth<T: BinaryInteger>(_ inch: InchWidth = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoWidth(inch))
    }
    func autoWidth<T: BinaryFloatingPoint>(_ inch: InchWidth = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoWidth(inch))
    }
    func autoHeight(_ inch: InchHeight = .TouchIDNormalModel) -> Double {
        let temp = Double("\(self)") ?? 0
        return temp.autoHeight(inch)
    }
    func autoHeight<T: BinaryInteger>(_ inch: InchHeight = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoHeight(inch))
    }
    func autoHeight<T: BinaryFloatingPoint>(_ inch: InchHeight = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoHeight(inch))
    }
}

public extension BinaryFloatingPoint {
    
    func autoWidth(_ inch: InchWidth = .TouchIDNormalModel) -> Double {
        let temp = Double("\(self)") ?? 0
        return temp.autoWidth(inch)
    }
    func autoWidth<T: BinaryInteger>(_ inch: InchWidth = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoWidth(inch))
    }
    func autoWidth<T: BinaryFloatingPoint>(_ inch: InchWidth = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoWidth(inch))
    }
    func autoHeight(_ inch: InchHeight = .TouchIDNormalModel) -> Double {
        let temp = Double("\(self)") ?? 0
        return temp.autoHeight(inch)
    }
    func autoHeight<T: BinaryInteger>(_ inch: InchHeight = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoHeight(inch))
    }
    func autoHeight<T: BinaryFloatingPoint>(_ inch: InchHeight = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoHeight(inch))
    }
    
}

public extension CGSize {
    
    func autoWidth(_ inch: InchWidth = .TouchIDNormalModel) -> CGSize {
        return CGSize(width: width.autoWidth(), height: height.autoWidth())
    }
    func autoHeight(_ inch: InchHeight = .TouchIDNormalModel) -> CGSize {
        return CGSize(width: width.autoHeight(), height: height.autoHeight())
    }
}

