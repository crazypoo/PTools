//
//  PTSearchPresentationContext.swift
//  PooTools
//
// English: Capture and restore the custom navigation item without touching UIKit global appearance.
// Español: Captura y restaura el elemento de navegación personalizado sin tocar la apariencia global de UIKit.
// 中文：保存并恢复自定义导航项，不修改 UIKit 全局外观。
//

import UIKit

#if SWIFT_PACKAGE
import ptools
#endif

@MainActor
public final class PTSearchPresentationContext {
    private weak var viewController: UIViewController?
    private weak var navigationController: UINavigationController?

    private let leftViews: [UIView]
    private let leftSpacing: CGFloat
    private let rightViews: [UIView]
    private let rightSpacing: CGFloat
    private let titleView: UIView?
    private let titleViewFillSpace: Bool
    private let title: String
    private let style: PTNavigationBarStyle

    public init(viewController: UIViewController) {
        self.viewController = viewController
        self.navigationController = viewController.navigationController

        if let navigationController = viewController.navigationController {
            let item = PTNavigationBarManager.shared.item(for: viewController)
            self.leftViews = item.leftView
            self.leftSpacing = item.leftItemSpacing
            self.rightViews = item.rightViews
            self.rightSpacing = item.rightItemSpacing
            self.titleView = item.titleView
            self.titleViewFillSpace = item.titleViewFillSpace
            self.title = item.navTitle
            self.style = item.barColorStyle
            _ = navigationController
        } else {
            self.leftViews = []
            self.leftSpacing = 0
            self.rightViews = []
            self.rightSpacing = 0
            self.titleView = nil
            self.titleViewFillSpace = true
            self.title = ""
            self.style = .default
        }
    }

    public func restore() {
        guard let viewController,
              let navigationController else { return }

        let item = PTNavigationBarManager.shared.item(for: viewController)
        item.leftView = leftViews
        item.leftItemSpacing = leftSpacing
        item.rightViews = rightViews
        item.rightItemSpacing = rightSpacing
        item.titleView = titleView
        item.titleViewFillSpace = titleViewFillSpace
        item.navTitle = title
        item.barColorStyle = style
        PTNavigationBarManager.shared.update(item: item, for: viewController)
        PTNavigationBarManager.shared.apply(style: style, in: navigationController)
        PTNavigationBarManager.shared.restoreIfNeeded(for: viewController)
    }
}
