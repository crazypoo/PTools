//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public protocol ViewHierarchyRepresentable {
    var application: UIApplication { get }
    var keyWindow: UIWindow? { get }
    var topPresentableViewController: UIViewController? { get }
    var presentedViewControllers: [UIViewController]? { get }
    var windows: [UIWindow] { get }
}
