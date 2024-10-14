//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementSizeLibrary {
    final class LabelSizeSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title: String = "Label"

        private weak var label: UILabel?

        init?(with object: NSObject) {
            guard let label = object as? UILabel else { return nil }
            self.label = label
        }

        private enum Properties: String, Swift.CaseIterable {
            case preferredMaxLayoutWidth = "Desired Width"
        }

        var properties: [InspectorElementProperty] {
            guard let label = label else { return [] }

            return Properties.allCases.map { property in
                switch property {
                case .preferredMaxLayoutWidth:
                    return .cgFloatStepper(
                        title: property.rawValue,
                        value: { label.preferredMaxLayoutWidth },
                        range: { 0...Double.infinity },
                        stepValue: { 1 },
                        handler: { label.preferredMaxLayoutWidth = $0 }
                    )
                }
            }
        }
    }
}
