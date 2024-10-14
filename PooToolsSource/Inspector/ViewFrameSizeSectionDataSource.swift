//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementSizeLibrary {
    final class ViewFrameSizeSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title: String = "View"

        private weak var view: UIView?

        init?(with object: NSObject) {
            guard let view = object as? UIView else { return nil }

            self.view = view
        }

        private enum Properties: String, Swift.CaseIterable {
            case frame = "Frame Rectangle"
            case autoresizingMask = "View Resizing"
            case directionalLayoutsMargins = "Layout Margins"
        }

        var properties: [InspectorElementProperty] {
            guard let view = view else { return [] }

            return Properties.allCases.compactMap { property in
                switch property {
                case .frame:
                    return .cgRect(
                        title: property.rawValue,
                        rect: { view.frame },
                        handler: {
                            guard let newFrame = $0 else { return }
                            view.frame = newFrame
                        }
                    )

                case .autoresizingMask:
                    return .optionsList(
                        title: property.rawValue,
                        options: UIView.AutoresizingMask.allCases.map(\.description),
                        selectedIndex: { UIView.AutoresizingMask.allCases.firstIndex(of: view.autoresizingMask) },
                        handler: {
                            guard let newIndex = $0 else { return }

                            let autoresizingMask = UIView.AutoresizingMask.allCases[newIndex]
                            view.autoresizingMask = autoresizingMask
                        }
                    )

                case .directionalLayoutsMargins:
                    return .directionalInsets(
                        title: property.rawValue,
                        insets: { view.directionalLayoutMargins },
                        handler: { directionalLayoutMargins in
                            view.directionalLayoutMargins = directionalLayoutMargins
                        }
                    )
                }
            }
        }
    }
}
