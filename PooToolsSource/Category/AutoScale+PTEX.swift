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
    
    @MainActor func autoWidth(_ inch: InchWidth = .TouchIDNormalModel) -> Double {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            return self
        }
        let base = inch.rawValue
        let screenWidth = Double(UIScreen.main.bounds.width)
        let screenHeight = Double(UIScreen.main.bounds.height)
        // English: Keep the legacy screen-based API compatible, but never subtract one safe-area edge from the other.
        // Español: Mantén compatible la API basada en pantalla, pero no restes un borde seguro del otro.
        // 中文：保留旧版屏幕 API 的兼容性，但不能用左边减右边计算安全宽度。
        let insets = deviceSafeAreaInsets()
        let width = max(0, min(screenWidth, screenHeight) - Double(insets.left + insets.right))
        return (self * (width / base)).rounded(3)
    }
    
    @MainActor func autoHeight(_ inch: InchHeight = .TouchIDNormalModel) -> Double {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            return self
        }
        let base = inch.rawValue
        let screenWidth = Double(UIScreen.main.bounds.width)
        let screenHeight = Double(UIScreen.main.bounds.height)
        // English: The old overload is retained for source compatibility; use autoHeight(in:) for view-local layout.
        // Español: Se conserva la sobrecarga antigua; usa autoHeight(in:) para el diseño local de una vista.
        // 中文：旧重载仅用于源码兼容；View 布局请使用 autoHeight(in:)。
        let insets = deviceSafeAreaInsets()
        let height = max(0, max(screenWidth, screenHeight) - Double(insets.top + insets.bottom))
        return (self * (height / base)).rounded(3)
    }

    // English: Scale against the consuming view instead of a process-wide display snapshot.
    // Español: Escala usando la vista consumidora en lugar de una instantánea global de la pantalla.
    // 中文：基于实际使用布局的 View 缩放，不再读取进程级屏幕快照。
    @MainActor func autoWidth(in view: UIView, inch: InchWidth = .TouchIDNormalModel) -> Double {
        guard view.traitCollection.userInterfaceIdiom == .phone else { return self }
        let base = inch.rawValue
        let safeRect = view.bounds.inset(by: view.safeAreaInsets)
        let width = max(0, safeRect.width)
        return (self * (Double(width) / base)).rounded(3)
    }

    // English: Scale height from the view's current local safe rectangle.
    // Español: Escala la altura desde el rectángulo seguro local actual de la vista.
    // 中文：基于 View 当前局部安全矩形计算高度缩放。
    @MainActor func autoHeight(in view: UIView, inch: InchHeight = .TouchIDNormalModel) -> Double {
        guard view.traitCollection.userInterfaceIdiom == .phone else { return self }
        let base = inch.rawValue
        let safeRect = view.bounds.inset(by: view.safeAreaInsets)
        let height = max(0, safeRect.height)
        return (self * (Double(height) / base)).rounded(3)
    }
}

public extension BinaryInteger {
    
    @MainActor func autoWidth(_ inch: InchWidth = .TouchIDNormalModel) -> Double {
        let temp = Double("\(self)") ?? 0
        return temp.autoWidth(inch)
    }
    @MainActor func autoWidth<T: BinaryInteger>(_ inch: InchWidth = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoWidth(inch))
    }
    @MainActor func autoWidth<T: BinaryFloatingPoint>(_ inch: InchWidth = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoWidth(inch))
    }
    @MainActor func autoHeight(_ inch: InchHeight = .TouchIDNormalModel) -> Double {
        let temp = Double("\(self)") ?? 0
        return temp.autoHeight(inch)
    }
    @MainActor func autoHeight<T: BinaryInteger>(_ inch: InchHeight = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoHeight(inch))
    }
    @MainActor func autoHeight<T: BinaryFloatingPoint>(_ inch: InchHeight = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoHeight(inch))
    }
}

public extension BinaryFloatingPoint {
    
    @MainActor func autoWidth(_ inch: InchWidth = .TouchIDNormalModel) -> Double {
        let temp = Double("\(self)") ?? 0
        return temp.autoWidth(inch)
    }
    @MainActor func autoWidth<T: BinaryInteger>(_ inch: InchWidth = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoWidth(inch))
    }
    @MainActor func autoWidth<T: BinaryFloatingPoint>(_ inch: InchWidth = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoWidth(inch))
    }
    @MainActor func autoHeight(_ inch: InchHeight = .TouchIDNormalModel) -> Double {
        let temp = Double("\(self)") ?? 0
        return temp.autoHeight(inch)
    }
    @MainActor func autoHeight<T: BinaryInteger>(_ inch: InchHeight = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoHeight(inch))
    }
    @MainActor func autoHeight<T: BinaryFloatingPoint>(_ inch: InchHeight = .TouchIDNormalModel) -> T {
        let temp = Double("\(self)") ?? 0
        return T(temp.autoHeight(inch))
    }
    
}

public extension CGSize {
    
    @MainActor func autoWidth(_ inch: InchWidth = .TouchIDNormalModel) -> CGSize {
        return CGSize(width: width.autoWidth(inch), height: height.autoWidth(inch))
    }
    @MainActor func autoHeight(_ inch: InchHeight = .TouchIDNormalModel) -> CGSize {
        return CGSize(width: width.autoHeight(inch), height: height.autoHeight(inch))
    }

    // English: Scale a size using the owning view's local safe rectangle.
    // Español: Escala un tamaño usando el rectángulo seguro local de la vista anfitriona.
    // 中文：使用所属 View 的局部安全矩形缩放尺寸。
    @MainActor func autoWidth(in view: UIView, inch: InchWidth = .TouchIDNormalModel) -> CGSize {
        CGSize(width: Double(width).autoWidth(in: view, inch: inch),
               height: Double(height).autoWidth(in: view, inch: inch))
    }

    // English: Scale height from the owning view without reading global display geometry.
    // Español: Escala la altura desde la vista anfitriona sin leer la geometría global de pantalla.
    // 中文：基于所属 View 缩放高度，不读取全局屏幕几何。
    @MainActor func autoHeight(in view: UIView, inch: InchHeight = .TouchIDNormalModel) -> CGSize {
        CGSize(width: Double(width).autoHeight(in: view, inch: inch),
               height: Double(height).autoHeight(in: view, inch: inch))
    }
}

