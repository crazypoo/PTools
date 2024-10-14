//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit

struct BundleInfo: Codable {
    private var appearance: String?
    var build: String
    var displayName: String?
    var executableName: String?
    var icons: Icons?
    var identifier: String?
    var minimumOSVersion: String?
    var name: String
    var version: String
    var xcodeBuild: String
    var xcodeVersion: String

    var interfaceStyle: UIUserInterfaceStyle? {
        switch appearance {
        case .none:
            return .none
        case "Dark":
            return .dark
        default:
            return .light
        }
    }

    struct Icons: Codable {
        var primaryIcon: Icon

        private enum CodingKeys: String, CodingKey {
            case primaryIcon = "CFBundlePrimaryIcon"
        }
    }

    struct Icon: Codable {
        var files: [String]
        var name: String

        private enum CodingKeys: String, CodingKey {
            case files = "CFBundleIconFiles"
            case name = "CFBundleIconName"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case appearance = "UIUserInterfaceStyle"
        case build = "CFBundleVersion"
        case displayName = "CFBundleDisplayName"
        case executableName = "CFBundleExecutable"
        case icons = "CFBundleIcons"
        case identifier = "CFBundleIdentifier"
        case minimumOSVersion = "MinimumOSVersion"
        case name = "CFBundleName"
        case version = "CFBundleShortVersionString"
        case xcodeBuild = "DTXcodeBuild"
        case xcodeVersion = "DTXcode"
    }
}
