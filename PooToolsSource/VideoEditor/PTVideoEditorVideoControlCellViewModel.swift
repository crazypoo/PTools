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
            return "PT Video editor function speed".localized()
        case .trim:
            return "PT Video editor function trim".localized()
        case .crop:
            return "PT Video editor function crop".localized()
        case .rotate:
            return "PT Video editor function rotate".localized()
        }
    }

    var imageName: String {
        switch videoControl {
        case .speed:
            return "Speed"
        case .trim:
            return "Trim"
        case .crop:
            return "Crop"
        case .rotate:
            return "Rotate"
        }
    }
}
