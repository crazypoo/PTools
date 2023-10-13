//
//  UIView+VideoEditorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func fadeIn(_ duration: TimeInterval = 0.3) {
        isHidden = false
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: { _ in })
    }

    func fadeOut(_ duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: { _ in
            self.isHidden = true
        })
    }
}
