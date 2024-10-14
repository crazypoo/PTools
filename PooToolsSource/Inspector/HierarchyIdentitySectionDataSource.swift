//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementIdentityLibrary {
    final class HierarchyIdentitySectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .expanded

        let title = "Hierarchy"

        private let classHierarchy: [AnyClass]

        init(with object: NSObject) {
            classHierarchy = object._classesForCoder
        }

        private(set) lazy var properties: [InspectorElementProperty] = classHierarchy.map { aClass in
            .infoNote(icon: .info, title: String(describing: aClass), text: .none)
        }
    }
}
