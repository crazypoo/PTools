//
//  PTSearchEmptyConfiguration.swift
//  PooTools
//
// English: Empty-state values stay on MainActor because they contain UIKit presentation objects.
// Español: Los valores del estado vacío permanecen en MainActor porque contienen objetos de presentación UIKit.
// 中文：空状态配置停留在 MainActor，因为其中包含 UIKit 展示对象。
//

import UIKit

#if SWIFT_PACKAGE
import ptools
#endif

@MainActor
public struct PTSearchEmptyConfiguration {
    public var image: UIImage?
    public var title: String
    public var message: String
    public var actionTitle: String
    public var action: (@MainActor () -> Void)?

    public init(image: UIImage? = UIImage(systemName: "magnifyingglass"),
                title: String = "No Results".localized(),
                message: String = "Try another keyword".localized(),
                actionTitle: String = "",
                action: (@MainActor () -> Void)? = nil) {
        self.image = image
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
}
