//
//  UISctckView+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/9/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

public extension UIStackView {
    
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach(addArrangedSubview)
    }
    
    func addArrangedSubviews(_ views: UIView...) {
        views.forEach(addArrangedSubview)
    }
    
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
    }
    
    func replaceArrangedSubviews(with arrangedSubviews: [UIView]) {
        removeAllArrangedSubviews()
        addArrangedSubviews(arrangedSubviews)
    }
}
