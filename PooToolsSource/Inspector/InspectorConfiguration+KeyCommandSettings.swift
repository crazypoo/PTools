//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension InspectorConfiguration {
    struct KeyCommandSettings: Hashable {
        public var layerToggleInputRange: ClosedRange<Int> = (1...9)

        public var layerToggleModifierFlags: UIKeyModifierFlags = [.control]

        public var allLayersToggleInput = String(0)

        public var presentationOptions = KeyCommandOptions(
            input: "0",
            modifierFlags: [.control, .shift]
        )

        public var presentationSettings = KeyCommandOptions(
            input: "1",
            modifierFlags: [.control, .alternate]
        )

        public struct KeyCommandOptions: Hashable {
            public var input: String
            public var modifierFlags: UIKeyModifierFlags

            public init(
                input: String,
                modifierFlags: UIKeyModifierFlags
            ) {
                self.input = input
                self.modifierFlags = modifierFlags
            }
        }
    }
}

extension UIKeyModifierFlags: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
