//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

typealias ViewHierarchyControllerIconProvider = Inspector.Provider<UIViewController, UIImage?>
typealias ViewHierarchyElementIconProvider = Inspector.Provider<NSObject?, UIImage?>

struct ViewHierarchyElementCatalog {
    var libraries: [ElementInspectorPanel: [InspectorElementLibraryProtocol]]
    var iconProvider: ViewHierarchyElementIconProvider?

    func makeElement(from view: UIView) -> ViewHierarchyElement {
        ViewHierarchyElement(with: view, iconProvider: iconProvider)
    }

    func makeElement(from viewController: UIViewController) -> ViewHierarchyElementController {
        ViewHierarchyElementController(viewController, iconProvider: iconProvider)
    }
}
