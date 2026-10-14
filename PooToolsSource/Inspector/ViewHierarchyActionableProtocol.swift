//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
#if SWIFT_PACKAGE
import ptools
#endif

protocol ViewHierarchyActionableProtocol {
    func canPerform(action: ViewHierarchyElementAction) -> Bool

    func perform(action: ViewHierarchyElementAction,
                 with element: ViewHierarchyElementReference,
                 from sourceView: UIView)
}
