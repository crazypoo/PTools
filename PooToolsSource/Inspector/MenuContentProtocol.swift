//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@MainActor
protocol MenuContentProtocol: Hashable {
    @MainActor var title: String { get }
    @MainActor var image: UIImage? { get }

    @MainActor static func allCases(for element: ViewHierarchyElementReference) -> [Self]
}
