//
//  PTVideoEditorCroppingPreset.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public enum PTVideoEditorCroppingPreset: CaseIterable {
    case vertical // 3:4
    case standard // 4:3
    case portrait // 9:16
    case square // 1:1
    case landscape // 16:9
    case instagram // 4:5

    var widthToHeightRatio: Double {
        switch self {
        case .vertical:
            return 3 / 4
        case .standard:
            return 4 / 3
        case .portrait:
            return 9 / 16
        case .square:
            return 1 / 1
        case .landscape:
            return 16 / 9
        case .instagram:
            return 4 / 5
        }
    }
}

final class PTVideoEditorCroppingPresetCellViewModel: NSObject {

    // MARK: Public Properties

    let croppingPreset: PTVideoEditorCroppingPreset

    // MARK: Init

    init(croppingPreset: PTVideoEditorCroppingPreset) {
        self.croppingPreset = croppingPreset
    }

    // MARK: Public Properties

    var ratio: Double {
        switch croppingPreset {
        case .vertical:
            return 3 / 4
        case .standard:
            return 4 / 3
        case .portrait:
            return 9 / 16
        case .square:
            return 1 / 1
        case .landscape:
            return 16 / 9
        case .instagram:
            return 4 / 5
        }
    }

    var formattedRatio: String {
        switch croppingPreset {
        case .vertical:
            return "3:4"
        case .standard:
            return "4:3"
        case .portrait:
            return "9:16"
        case .square:
            return "1:1"
        case .landscape:
            return "16:9"
        case .instagram:
            return "4:5"
        }
    }

    var name: String {
        switch croppingPreset {
        case .vertical:
            return "PT Video editor crop vertical".localized()
        case .standard:
            return "PT Video editor crop standar".localized()
        case .portrait:
            return "PT Video editor crop portrait".localized()
        case .square:
            return "PT Video editor crop square".localized()
        case .landscape:
            return "PT Video editor crop landscape".localized()
        case .instagram:
            return "PT Video editor crop instagram".localized()
        }
    }

    var imageName: String {
        switch croppingPreset {
        case .vertical:
            return "Vertical"
        case .standard:
            return "Standard"
        case .portrait:
            return "Portrait"
        case .square:
            return "Square"
        case .landscape:
            return "Landscape"
        case .instagram:
            return "Instagram"
        }
    }
}
