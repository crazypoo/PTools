//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class LabelAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Label"

        private weak var label: UILabel?

        init?(with object: NSObject) {
            guard let label = object as? UILabel else { return nil }

            self.label = label
        }

        private enum Property: String, Swift.CaseIterable {
            case text = "Text"
            case textColor = "Text Color"
            case fontName = "Font Name"
            case fontSize = "Font Size"
            case adjustsFontSizeToFitWidth = "Automatically Adjusts Font"
            case textAlignment = "Alignment"
            case numberOfLines = "Lines"
            case groupBehavior = "Behavior"
            case isEnabled = "Enabled"
            case isHighlighted = "Highlighted"
            case separator0 = "Separator0"
            case baseline = "Baseline"
            case lineBreak = "Line Break"
            case autoShrink = "Auto Shrink"
            case allowsDefaultTighteningForTruncation = "Tighten Letter Spacing"
            case separator1 = "Separator1"
            case highlightedTextColor = "Highlighted Color"
            case shadowColor = "Shadow"
        }

        var properties: [InspectorElementProperty] {
            guard let label = label else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .text:
                    return .textView(
                        title: property.rawValue,
                        placeholder: label.text ?? property.rawValue,
                        value: { label.text }
                    ) { text in
                        label.text = text
                    }
                case .textColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { label.textColor }
                    ) { textColor in
                        label.textColor = textColor
                    }
                case .fontName:
                    return .fontNamePicker(
                        title: property.rawValue,
                        fontProvider: { label.font }
                    ) { font in
                        guard let font = font else {
                            return
                        }

                        label.font = font
                    }
                case .fontSize:
                    return .fontSizeStepper(
                        title: property.rawValue,
                        fontProvider: { label.font }
                    ) { font in
                        guard let font = font else {
                            return
                        }

                        label.font = font
                    }
                case .adjustsFontSizeToFitWidth:
                    return .switch(
                        title: property.rawValue,
                        isOn: { label.adjustsFontSizeToFitWidth }
                    ) { adjustsFontSizeToFitWidth in
                        label.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
                    }
                case .textAlignment:
                    let allCases = NSTextAlignment.allCases.withImages

                    return .imageButtonGroup(
                        title: property.rawValue,
                        images: allCases.compactMap(\.image),
                        selectedIndex: { allCases.firstIndex(of: label.textAlignment) }
                    ) {
                        guard let newIndex = $0 else { return }

                        let textAlignment = allCases[newIndex]

                        label.textAlignment = textAlignment
                    }
                case .numberOfLines:
                    return .integerStepper(
                        title: property.rawValue,
                        value: { label.numberOfLines },
                        range: { 0...100 },
                        stepValue: { 1 }
                    ) { numberOfLines in
                        label.numberOfLines = numberOfLines
                    }
                case .groupBehavior:
                    return .group(title: property.rawValue)

                case .isEnabled:
                    return .switch(
                        title: property.rawValue,
                        isOn: { label.isEnabled }
                    ) { isEnabled in
                        label.isEnabled = isEnabled
                    }
                case .isHighlighted:
                    return .switch(
                        title: property.rawValue,
                        isOn: { label.isHighlighted }
                    ) { isHighlighted in
                        label.isHighlighted = isHighlighted
                    }
                case .separator0,
                     .separator1:
                    return .separator

                case .baseline,
                     .lineBreak,
                     .autoShrink:
                    return nil

                case .allowsDefaultTighteningForTruncation:
                    return .switch(
                        title: property.rawValue,
                        isOn: { label.allowsDefaultTighteningForTruncation }
                    ) { allowsDefaultTighteningForTruncation in
                        label.allowsDefaultTighteningForTruncation = allowsDefaultTighteningForTruncation
                    }
                case .highlightedTextColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { label.highlightedTextColor }
                    ) { highlightedTextColor in
                        label.highlightedTextColor = highlightedTextColor
                    }
                case .shadowColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { label.shadowColor }
                    ) { shadowColor in
                        label.shadowColor = shadowColor
                    }
                }
            }
        }
    }
}
