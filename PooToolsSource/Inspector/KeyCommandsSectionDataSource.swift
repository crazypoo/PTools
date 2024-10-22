//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class KeyCommandsSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .expanded

        let title: String

        var subtitle: String?

        private weak var keyCommand: UIKeyCommand?

        var customClass: InspectorElementSectionView.Type? {
            InspectorElementKeyCommandSectionView.self
        }

        init?(with object: NSObject) {
            guard let keyCommand = object as? UIKeyCommand else {
                return nil
            }

            if keyCommand.title.isEmpty {
                subtitle = keyCommand.discoverabilityTitle ?? keyCommand.action?.description
            }
            else {
                subtitle = keyCommand.title
            }

            title = keyCommand.symbols ?? "Key Command"

            self.keyCommand = keyCommand
        }

        private enum Property: String, Swift.CaseIterable {
            case title = "Title"
            case discoverabilityTitle = "Discoverability Title"
            case image = "Image"
            case separator
            case key = "Keys"
            case selector = "Selector"
        }

        var properties: [InspectorElementProperty] {
            guard let keyCommand = keyCommand else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .separator:
                    return .separator
                case .discoverabilityTitle:
                    return .textField(
                        title: property.rawValue,
                        placeholder: .none,
                        axis: .vertical,
                        value: { keyCommand.discoverabilityTitle },
                        handler: .none
                    )
                case .image:
                    return .imagePicker(
                        title: property.rawValue,
                        image: { keyCommand.image },
                        handler: .none
                    )
                case .key:
                    return .textField(
                        title: property.rawValue,
                        placeholder: .none,
                        axis: .vertical,
                        value: { keyCommand.symbols },
                        handler: .none
                    )
                case .title:
                    return .textField(
                        title: property.rawValue,
                        placeholder: .none,
                        axis: .vertical,
                        value: { keyCommand.title },
                        handler: .none
                    )
                case .selector:
                    return .textField(
                        title: property.rawValue,
                        placeholder: .none,
                        axis: .vertical,
                        value: { keyCommand.action?.description },
                        handler: .none
                    )
                }
            }
        }
    }
}

extension UIKeyCommand {
    var symbols: String? {
        let keys = (modifierFlags.symbols + [input?.localizedUppercase]).compactMap { $0 }
        return keys.isEmpty ? nil : keys.joined(separator: " + ")
    }
}

extension UIKeyModifierFlags: @retroactive CaseIterable {
    public typealias AllCases = [UIKeyModifierFlags]

    public static let allCases: [UIKeyModifierFlags] = [
        .alphaShift,
        .shift,
        .control,
        .alternate,
        .command,
        .numericPad
    ]
}

extension UIKeyModifierFlags {
    var symbols: [String?] {
        var symbols = [String?]()

        Self.allCases.forEach { flag in
            if contains(flag) {
                symbols.append({
                    switch flag {
                    case .alphaShift:
                        return "⇪"
                    case .shift:
                        return "⇧"
                    case .control:
                        return "^"
                    case .alternate:
                        return "⌥"
                    case .command:
                        return "⌘"
                    default:
                        return nil
                    }
                }())
            }
        }

        return symbols
    }
}
