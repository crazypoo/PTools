//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class SwitchAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Switch"

        private weak var switchControl: UISwitch?

        init?(with object: NSObject) {
            guard let switchControl = object as? UISwitch else { return nil }

            self.switchControl = switchControl
        }

        private enum Property: String, Swift.CaseIterable {
            case title = "Title"
            case preferredStyle = "Preferred Style"
            case isOn = "State"
            case onTintColor = "On Tint"
            case thumbTintColor = "Thumb Tint"
        }

        var properties: [InspectorElementProperty] {
            guard let switchControl = switchControl else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .title:
                    return .textField(
                        title: property.rawValue,
                        placeholder: switchControl.title.isNilOrEmpty ? property.rawValue : switchControl.title,
                        value: { switchControl.title }
                    ) { title in
                        switchControl.title = title
                    }
                case .preferredStyle:
                    return .textButtonGroup(
                        title: property.rawValue,
                        texts: UISwitch.Style.allCases.map(\.description),
                        selectedIndex: { UISwitch.Style.allCases.firstIndex(of: switchControl.preferredStyle) },
                        handler: {
                            guard let newIndex = $0 else { return }

                            let preferredStyle = UISwitch.Style.allCases[newIndex]

                            switchControl.preferredStyle = preferredStyle
                        }
                    )
                case .isOn:
                    return .switch(
                        title: property.rawValue,
                        isOn: { switchControl.isOn }
                    ) { isOn in
                        switchControl.setOn(isOn, animated: true)
                        switchControl.sendActions(for: .valueChanged)
                    }
                case .onTintColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { switchControl.onTintColor }
                    ) { onTintColor in
                        switchControl.onTintColor = onTintColor
                    }
                case .thumbTintColor:
                    return .colorPicker(
                        title: property.rawValue,
                        color: { switchControl.thumbTintColor }
                    ) { thumbTintColor in
                        switchControl.thumbTintColor = thumbTintColor
                    }
                }
            }
        }
    }
}
