//
//  PTFont.swift
//
// English: UIKit construction remains on MainActor; immutable metadata lives in the Foundation-only font target.
// Español: La construcción UIKit permanece en MainActor; los metadatos inmutables viven en el target de fuentes basado en Foundation.
// 中文：UIKit 字体构造固定在 MainActor，不可变元数据由 Foundation-only 字体 target 提供。
//

import UIKit

#if SWIFT_PACKAGE
import PToolsFontCatalogCore
#endif

public extension PTFont {
    @MainActor
    func uiFont(size: CGFloat) -> UIFont? {
        UIFont(name: postScriptName, size: size)
    }

    @MainActor
    func isAvailable(size: CGFloat = 12) -> Bool {
        uiFont(size: size) != nil
    }
}
