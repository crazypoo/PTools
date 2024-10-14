//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol UIViewControllerTransitionPresenterDelegate: AnyObject {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
}

final class UIViewControllerTransitionPresenter: NSObject, UIViewControllerTransitioningDelegate {
    weak var delegate: UIViewControllerTransitionPresenterDelegate?

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        delegate?.animationController(forPresented: presented, presenting: presenting, source: source)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        delegate?.animationController(forDismissed: dismissed)
    }
}
