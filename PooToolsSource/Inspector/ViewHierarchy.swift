//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class ViewHierarchy {
    static let shared = ViewHierarchy(application: .shared)

    let application: UIApplication

    init(application: UIApplication) {
        self.application = application
    }
}

// MARK: - ViewHierarchyRepresentable

extension ViewHierarchy: ViewHierarchyRepresentable {
    
    var windows: [UIWindow] { UIApplication.shared.findWindows }

    var keyWindow: UIWindow? { windows.first(where: \.isKeyWindow) }

    var topPresentableViewController: UIViewController? {
        presentedViewControllers?.last ?? keyWindow?.rootViewController
    }

    var presentedViewControllers: [UIViewController]? {
        keyWindow?.rootViewController?.allPresentedViewControllers
            .filter { $0 is InternalViewProtocol == false }
            .filter { $0._isInternalView == false }
    }
}
