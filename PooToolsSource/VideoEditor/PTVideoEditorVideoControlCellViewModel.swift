//
//  PTVideoEditorVideoControlCellViewModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

final class PTVideoEditorVideoControlCellViewModel: NSObject {
    let videoControl: PTVideoEditorVideoControl

    // MARK: Init

    init(videoControl: PTVideoEditorVideoControl) {
        self.videoControl = videoControl
    }
        
    var name: String {
        switch videoControl {
        case .speed:
            return "Speed"
        case .trim:
            return "Trim"
        case .crop:
            return "Crop"
        }
    }

    var imageName: String {
        "\(name)"
    }
}
