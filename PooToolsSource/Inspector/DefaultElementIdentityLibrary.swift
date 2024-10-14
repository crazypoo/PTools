//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum DefaultElementIdentityLibrary: Swift.CaseIterable, InspectorElementLibraryProtocol {
    case preview
    case hierarchy
    case highlightView
    case runtimeAttributes

    var targetClass: AnyClass {
        NSObject.self
    }

    func sections(for object: NSObject) -> InspectorElementSections {
        switch (self, object) {
        case let (.preview, view as UIView):
            return .init(with: PreviewIdentitySectionDataSource(with: view))

        case let (.preview, viewController as UIViewController):
            return .init(with: PreviewIdentitySectionDataSource(with: viewController.view))

        case let (.highlightView, view as UIView):
            return .init(with: HighlightViewSectionDataSource(with: view))

        case let (.highlightView, viewController as UIViewController):
            return .init(with: HighlightViewSectionDataSource(with: viewController.view))

        case (.runtimeAttributes, _):
            return .init(with: RuntimeAttributesIdentitySectionDataSource(with: object))

        case (.hierarchy, _):
            return .init(with: HierarchyIdentitySectionDataSource(with: object))

        default:
            return .empty
        }
    }
}
