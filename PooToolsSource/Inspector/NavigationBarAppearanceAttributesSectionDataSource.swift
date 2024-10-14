//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import SwiftUI
import UIKit

extension DefaultElementAttributesLibrary {
    final class NavigationBarAppearanceAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let kind: Kind

        weak var appearance: UINavigationBarAppearance?

        init?(with object: NSObject, _ kind: Kind) {
            guard
                let navigationBar = object as? UINavigationBar,
                let appearance = kind.appearance(from: navigationBar)
            else {
                return nil
            }
            self.kind = kind
            self.appearance = appearance
        }

        var title: String {
            kind.description.string(appending: "Appearance")
        }

        private enum Property: String, Swift.CaseIterable {
            case information
            case iOS15_behaviorWarning
            case backgroundEffect = "Blur Style"
            case backgroundColor = "Background"
            case backgroundImage = "Image"
            case backgroundImageContentMode = "Content Mode"
            case shadowColor = "Shadow Color"
            case shadowImage = "Shadow Image"
            case separator0
            case titleOffset = "Title Offset"
            case separator1

            case titleGroup = "Title Attributes"
            case titleFontName = "Title Font Name"
            case titleFontSize = "Title Font Size"
            case titleColor = "Title Color"
            case titleShadow = "Title Shadow"
            case titleShadowOffset = "Title Shadow Offset"

            case largeTitleGroup = "Large Title Attributes"
            case largeTitleFontName = "Large Title Font Name"
            case largeTitleFontSize = "Large Title Font Size"
            case largeTitleColor = "Large Title Color"
            case largeTitleShadow = "Large Title Shadow"
            case largeTitleShadowOffset = "Large Title Shadow Offset"
        }

        private(set) lazy var properties = makeProperties(for: appearance)

        private func makeProperties(for appearance: UINavigationBarAppearance?) -> [InspectorElementProperty] {
            guard let appearance = appearance else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .information: return kind.infoNote

                case .iOS15_behaviorWarning: return kind.warning

                case .backgroundEffect:
                    return .optionsList(
                        title: property.rawValue,
                        emptyTitle: "None",
                        options: UIBlurEffect.Style.allCases.map(\.description),
                        selectedIndex: {
                            guard let style = appearance.backgroundEffect?.style else { return nil }
                            return UIBlurEffect.Style.allCases.firstIndex(of: style)
                        },
                        handler: {
                            if let newIndex = $0,
                               (0 ..< UIBlurEffect.Style.allCases.count).contains(newIndex)
                            {
                                let backgroundStyle = UIBlurEffect.Style.allCases[newIndex]
                                appearance.backgroundEffect = UIBlurEffect(style: backgroundStyle)
                            }
                            else { appearance.backgroundEffect = .none }
                        }
                    )

                case .backgroundColor:
                    return
                        .colorPicker(
                            title: property.rawValue,
                            emptyTitle: Texts.default,
                            color: { appearance.backgroundColor },
                            handler: { appearance.backgroundColor = $0 }
                        )

                case .backgroundImage:
                    return
                        .imagePicker(
                            title: property.rawValue,
                            image: { appearance.backgroundImage },
                            handler: { appearance.backgroundImage = $0 }
                        )

                case .backgroundImageContentMode:
                    return
                        .optionsList(
                            title: property.rawValue,
                            options: UIView.ContentMode.allCases.map(\.description),
                            selectedIndex: { UIView.ContentMode.allCases.firstIndex(of: appearance.backgroundImageContentMode) }
                        ) {
                            guard let newIndex = $0 else { return }
                            let backgroundImageContentMode = UIView.ContentMode.allCases[newIndex]
                            appearance.backgroundImageContentMode = backgroundImageContentMode
                        }

                case .shadowColor:
                    return
                        .colorPicker(
                            title: property.rawValue,
                            emptyTitle: Texts.default,
                            color: { appearance.shadowColor },
                            handler: { appearance.shadowColor = $0 }
                        )

                case .shadowImage:
                    return
                        .imagePicker(
                            title: property.rawValue,
                            image: { appearance.shadowImage },
                            handler: { appearance.shadowImage = $0 }
                        )

                case .separator0, .separator1:
                    return .separator

                case .titleOffset:
                    return nil

                case .titleGroup, .largeTitleGroup:
                    return .group(title: property.rawValue)

                case .titleFontName:
                    return .fontNamePicker(
                        title: property.rawValue,
                        fontProvider: { appearance.titleTextAttributes[.font] as? UIFont },
                        handler: { appearance.titleTextAttributes[.font] = $0 }
                    )
                case .titleFontSize:
                    return .fontSizeStepper(
                        title: property.rawValue,
                        fontProvider: { appearance.titleTextAttributes[.font] as? UIFont },
                        handler: { appearance.titleTextAttributes[.font] = $0 }
                    )
                case .titleColor:
                    return .colorPicker(
                        title: property.rawValue,
                        emptyTitle: Texts.default,
                        color: { appearance.titleTextAttributes[.foregroundColor] as? UIColor },
                        handler: { appearance.titleTextAttributes[.foregroundColor] = $0 }
                    )
                case .titleShadow:
                    return .colorPicker(
                        title: property.rawValue,
                        emptyTitle: Texts.default,
                        color: { (appearance.titleTextAttributes[.shadow] as? NSShadow)?.shadowColor as? UIColor },
                        handler: { (appearance.titleTextAttributes[.shadow] as? NSShadow)?.shadowColor = $0 }
                    )
                case .titleShadowOffset:
                    return .cgSize(
                        title: property.rawValue,
                        size: { (appearance.titleTextAttributes[.shadow] as? NSShadow)?.shadowOffset ?? .zero },
                        handler: { (appearance.titleTextAttributes[.shadow] as? NSShadow)?.shadowOffset = $0 ?? .zero }
                    )

                case .largeTitleFontName:
                    return .fontNamePicker(
                        title: property.rawValue,
                        fontProvider: { appearance.largeTitleTextAttributes[.font] as? UIFont },
                        handler: { appearance.largeTitleTextAttributes[.font] = $0 }
                    )
                case .largeTitleFontSize:
                    return .fontSizeStepper(
                        title: property.rawValue,
                        fontProvider: { appearance.largeTitleTextAttributes[.font] as? UIFont },
                        handler: { appearance.largeTitleTextAttributes[.font] = $0 }
                    )
                case .largeTitleColor:
                    return .colorPicker(
                        title: property.rawValue,
                        emptyTitle: Texts.default,
                        color: { appearance.largeTitleTextAttributes[.foregroundColor] as? UIColor },
                        handler: { appearance.largeTitleTextAttributes[.foregroundColor] = $0 }
                    )
                case .largeTitleShadow:
                    return .colorPicker(
                        title: property.rawValue,
                        emptyTitle: Texts.default,
                        color: { (appearance.titleTextAttributes[.shadow] as? NSShadow)?.shadowColor as? UIColor },
                        handler: { (appearance.titleTextAttributes[.shadow] as? NSShadow)?.shadowColor = $0 }
                    )
                case .largeTitleShadowOffset:
                    return .cgSize(
                        title: property.rawValue,
                        size: { (appearance.titleTextAttributes[.shadow] as? NSShadow)?.shadowOffset ?? .zero },
                        handler: { (appearance.titleTextAttributes[.shadow] as? NSShadow)?.shadowOffset = $0 ?? .zero }
                    )
                }
            }
        }
    }
}

// MARK: - TitleAttribute

extension DefaultElementAttributesLibrary.NavigationBarAppearanceAttributesSectionDataSource {
    private enum TitleAttribute: String, Swift.CaseIterable {
        case groupTitle
        case fontName = "Title Font Name"
        case fontSize = "Title Font Size"
        case color = "Title Color"
        case shadow = "Title Shadow"
        case shadowOffset = "Shadow Offset"
    }
}

// MARK: - `Type`

extension DefaultElementAttributesLibrary.NavigationBarAppearanceAttributesSectionDataSource {
    enum Kind: CustomStringConvertible {
        case standard, compact, scrollEdge, compactScrollEdge

        func appearance(from navigationBar: UINavigationBar) -> UINavigationBarAppearance? {
            switch self {
            case .standard:
                return navigationBar.standardAppearance
            case .compact:
                return navigationBar.compactAppearance
            case .scrollEdge:
                return navigationBar.scrollEdgeAppearance
            case .compactScrollEdge:
                #if swift(>=5.5)
                if #available(iOS 15.0, *) {
                    return navigationBar.compactScrollEdgeAppearance
                }
                #endif
                return .none
            }
        }

        var description: String {
            switch self {
            case .standard:
                return "Standard"
            case .compact:
                return "Compact"
            case .scrollEdge:
                return "Scroll Edge"
            case .compactScrollEdge:
                return "Compact Scroll Edge"
            }
        }

        var message: String {
            switch self {
            case .standard:
                return "The appearance settings for a standard height navigation bar."
            case .compact:
                return "The appearance settings for a compact height navigation bar."
            case .scrollEdge:
                return "The appearance settings for the navigation bar when content is scrolled to the top."
            case .compactScrollEdge:
                return "The appearance settings for a compact-height navigation bar when content is scrolled to the top."
            }
        }

        var infoNote: InspectorElementProperty {
            .infoNote(icon: .info, text: message)
        }

        var warning: InspectorElementProperty? {
            guard #available(iOS 15.0, *) else { return .none }

            switch self {
            case .scrollEdge:
                return .infoNote(
                    icon: .warning,
                    text: "Starting iOS 15 when this property is nil, the navigation bar's background will become transparent when scrolled to the top."
                )

            case .compactScrollEdge:
                return .infoNote(
                    icon: .warning,
                    text: "Starting iOS 15 when this property is nil, the navigation bar's background will become transparent when scrolled to the top in a vertically compact orientation."
                )

            default:
                return .none
            }
        }
    }
}
