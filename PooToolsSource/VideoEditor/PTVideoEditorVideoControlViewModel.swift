//
//  PTVideoEditorVideoControlViewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

final class PTVideoEditorVideoControlViewModel {
    let videoControl: PTVideoEditorVideoControl

    var title: String {
        switch videoControl {
        case .speed:
            return "Speed"
        case .trim:
            return "Trim"
        case .crop:
            return "Crop"
        }
    }

    var titleImageName: String {
        "\(title)"
    }

    init(videoControl: PTVideoEditorVideoControl) {
        self.videoControl = videoControl
    }
}
