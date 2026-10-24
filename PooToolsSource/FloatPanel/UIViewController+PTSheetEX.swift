//
//  UIViewController+PTSheetEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

@MainActor
extension UIViewController {
    public var sheetViewController: PTSheetViewController? {
        var parent = self.parent
        while let currentParent = parent {
            if let sheetViewController = currentParent as? PTSheetViewController {
                return sheetViewController
            } else {
                parent = currentParent.parent
            }
        }
        return nil
    }

    // English: Convert the real pull-bar frame into the child controller's local coordinate space.
    // Español: Convierte el marco real de la barra en el espacio local del controlador hijo.
    // 中文：将真实 pullbar 框架转换到子控制器的局部坐标系。
    public func ptSheetPullBarFrame(in view: UIView) -> CGRect? {
        guard let sheet = sheetViewController,
              sheet.isViewLoaded,
              sheet.contentViewController.isViewLoaded else { return nil }
        let pullBar = sheet.contentViewController.pullBarView
        guard pullBar.superview != nil, !pullBar.bounds.isEmpty else { return nil }
        return pullBar.convert(pullBar.bounds, to: view)
    }
}

#endif
