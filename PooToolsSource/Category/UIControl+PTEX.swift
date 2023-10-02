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
}
