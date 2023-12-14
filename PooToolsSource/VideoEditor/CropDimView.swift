//
//  CropDimView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

// CropDimView
class CropDimView: UIView {
    private var path: CGPath?
    
    init() {
        super.init(frame: .zero)
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func mask(_ path: CGPath, duration: TimeInterval, animated: Bool) {
        self.path = path
        if let mask = self.layer.mask as? CAShapeLayer {
            mask.removeAllAnimations()
            if animated {
                let animation = CABasicAnimation(keyPath: "path")
                animation.delegate = self
                animation.fromValue = mask.path
                animation.toValue = path
                animation.byValue = path
                animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                animation.duration = duration
                mask.add(animation, forKey: "path")
            } else {
                mask.path = path
            }
        } else {
            let maskLayer = CAShapeLayer()
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
            maskLayer.backgroundColor = UIColor.clear.cgColor
            maskLayer.path = path
            self.layer.mask = maskLayer
        }
    }
}

// MARK: CAAnimationDelegate
extension CropDimView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let path = self.path else { return }
        if let mask = self.layer.mask as? CAShapeLayer {
            mask.removeAllAnimations()
            mask.path = path
        }
    }
}
