//
//  Extensions.swift
//
//  Created by Duraid Abdul.
//  Copyright © 2021 Duraid Abdul. All rights reserved.
//

import UIKit

public extension UIControl {
    func addActions(highlightAction: UIAction,
                    unhighlightAction: UIAction) {
        if #available(iOS 14.0, *) {
            addAction(highlightAction, for: .touchDown)
            addAction(highlightAction, for: .touchDragEnter)
            addAction(unhighlightAction, for: .touchUpInside)
            addAction(unhighlightAction, for: .touchDragExit)
            addAction(unhighlightAction, for: .touchCancel)
        }
    }
    
    private struct Container {
        static var expandClickEdgeInsets: Void?
    }

    /// 扩大点击区域
    var expandClickEdgeInsets: UIEdgeInsets {
        get {
            objc_getAssociatedObject(self, &Container.expandClickEdgeInsets) as? UIEdgeInsets ?? .zero
        }
        set {
            objc_setAssociatedObject(self, &Container.expandClickEdgeInsets, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        let biggerFrame = CGRect(x: bounds.minX - expandClickEdgeInsets.left, y: bounds.minY - expandClickEdgeInsets.top, width: bounds.width + expandClickEdgeInsets.left + expandClickEdgeInsets.right, height: bounds.height + expandClickEdgeInsets.top + expandClickEdgeInsets.bottom)
        return biggerFrame.contains(point)
    }
}
