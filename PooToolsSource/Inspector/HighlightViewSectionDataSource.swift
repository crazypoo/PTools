//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementIdentityLibrary {
    final class HighlightViewSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title: String = Texts.highlight("View")

        weak var highlightView: InspectorHighlightView?

        init?(with view: UIView) {
            if let highlightView = view._highlightView {
                self.highlightView = highlightView
            }
            else {
                return nil
            }
        }

        private enum Property: String, Swift.CaseIterable {
            case nameDisplayMode = "Name Display"
            case highlightView = "Show Highlight"
        }

        var properties: [InspectorElementProperty] {
            guard let highlightView = highlightView else {
                return []
            }

            return Property.allCases.compactMap { property in
                switch property {
                case .highlightView:
                    return .switch(
                        title: property.rawValue,
                        isOn: { !highlightView.isHidden },
                        handler: { isOn in
                            highlightView.isHidden = !isOn
                        }
                    )
                case .nameDisplayMode:
                    return .optionsList(
                        title: property.rawValue,
                        options: ElementNameView.DisplayMode.allCases.map(\.title),
                        selectedIndex: { ElementNameView.DisplayMode.allCases.firstIndex(of: highlightView.displayMode) },
                        handler: {
                            guard let newIndex = $0 else { return }

                            let displayMode = ElementNameView.DisplayMode.allCases[newIndex]

                            highlightView.displayMode = displayMode
                        }
                    )
                }
            }
        }
    }
}
