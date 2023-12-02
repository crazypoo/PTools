//
//  PTTransitioningAnimation.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

class PTTransitioningAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? PTCutViewController, let toVC = transitionContext.viewController(forKey: .to) as? PTEditImageViewController else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        
        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        
        let imageView = UIImageView(frame: fromVC.dismissAnimateFromRect)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = fromVC.dismissAnimateImage
        containerView.addSubview(imageView)
        
        UIView.animate(withDuration: 0.3, animations: {
            imageView.frame = toVC.originalFrame
        }) { _ in
            toVC.finishClipDismissAnimate()
            imageView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
