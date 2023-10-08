//
//  PTVideoEdit.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation

public struct PTVideoEdit {
    public var speedRate: Double = 1.0
    public var trimPositions: (CMTime, CMTime)?
    public var croppingPreset: PTVideoEditorCroppingPreset?
    public var isMuted: Bool = false

    public init() {}

}

extension PTVideoEdit {
    static let speedRateLens = PTVideoEditorLens<PTVideoEdit, Double>(
        from: { $0.speedRate },
        to: { speedRate, previousEdit in
            var edit = PTVideoEdit()
            edit.croppingPreset = previousEdit.croppingPreset
            edit.speedRate = speedRate
            edit.trimPositions = previousEdit.trimPositions
            return edit
        }
    )

    static let trimPositionsLens = PTVideoEditorLens<PTVideoEdit, (CMTime, CMTime)?>(
        from: { $0.trimPositions },
        to: { trimPositions, previousEdit in
            var edit = PTVideoEdit()
            edit.croppingPreset = previousEdit.croppingPreset
            edit.speedRate = previousEdit.speedRate
            edit.trimPositions = trimPositions
            return edit
        }
    )

    static let croppingPresetLens = PTVideoEditorLens<PTVideoEdit, PTVideoEditorCroppingPreset?>(
        from: { $0.croppingPreset },
        to: { croppingPreset, previousEdit in
            var edit = PTVideoEdit()
            edit.croppingPreset = croppingPreset
            edit.speedRate = previousEdit.speedRate
            edit.trimPositions = previousEdit.trimPositions
            return edit
        }
    )
}
