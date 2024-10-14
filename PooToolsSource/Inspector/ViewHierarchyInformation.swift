//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum ViewHierarchyInformation: Swift.CaseIterable, MenuContentProtocol {
    case className
    case description
    case report

    static func allCases(for element: ViewHierarchyElementReference) -> [ViewHierarchyInformation] {
        allCases
    }

    var title: String {
        switch self {
        case .className:
            return Texts.copy("Class Name")
        case .description:
            return Texts.copy("Description")
        case .report:
            return Texts.copy("View Report")
        }
    }

    var image: UIImage? { .copySymbol }
}
