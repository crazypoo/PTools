//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class WindowAttributesSectionDataSource: InspectorElementSectionDataSource {
        var state: InspectorElementSectionState = .collapsed

        let title = "Window"

        private weak var window: UIWindow?

        init?(with object: NSObject) {
            guard let window = object as? UIWindow else { return nil }

            self.window = window
        }

        private enum Property: String, Swift.CaseIterable {
            case canResizeToFitContent = "Can Resize To Fit Content"
            case isKeyWindow = "Is Key"
            case canBecomeKey = "Can Become Key"
            case separator0
            case windowLevel = "Window Level"
            case separator1
            case screenBounds = "Screen Bounds"
            case screenScale = "Screen Scale"
        }

        var properties: [InspectorElementProperty] {
            guard let window = window else { return [] }

            return Property.allCases.compactMap { property in
                switch property {
                case .canResizeToFitContent:
                    return .switch(
                        title: property.rawValue,
                        isOn: { window.canResizeToFitContent },
                        handler: { canResizeToFitContent in
                            window.canResizeToFitContent = canResizeToFitContent
                        }
                    )
                case .separator0, .separator1:
                    return .separator

                case .screenBounds:
                    return .cgRect(
                        title: property.rawValue,
                        rect: { window.screen.bounds },
                        handler: nil
                    )
                case .screenScale:
                    return .cgFloatStepper(
                        title: property.rawValue,
                        value: { window.screen.scale },
                        range: { 0...window.screen.scale },
                        stepValue: { 1 },
                        handler: nil
                    )
                case .windowLevel:
                    return .cgFloatStepper(
                        title: property.rawValue,
                        value: { window.windowLevel.rawValue },
                        range: { -Double.infinity...Double.infinity },
                        stepValue: { 1 },
                        handler: nil
                    )
                case .isKeyWindow:
                    return .switch(
                        title: property.rawValue,
                        isOn: { window.isKeyWindow },
                        handler: nil
                    )
                case .canBecomeKey:
                    guard #available(iOS 15.0, *) else { return nil }

                    return .switch(
                        title: property.rawValue,
                        isOn: { window.canBecomeKey },
                        handler: nil
                    )
                }
            }
        }
    }
}
