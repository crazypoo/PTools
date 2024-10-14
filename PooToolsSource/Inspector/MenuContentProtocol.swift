//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol MenuContentProtocol: Hashable {
    var title: String { get }
    var image: UIImage? { get }

    static func allCases(for element: ViewHierarchyElementReference) -> [Self]
}
