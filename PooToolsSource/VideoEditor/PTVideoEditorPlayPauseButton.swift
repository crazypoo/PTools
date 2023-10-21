//
//  PTVideoEditorPlayPauseButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public final class PTVideoEditorPlayPauseButton: UIButton {

    public var isPaused: Bool = true {
        didSet {
            updateImage()
        }
    }

    public init() {
        super.init(frame: .zero)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        setImage(UIImage.podBundleImage("Play",bundleName:PTVideoEditorPodBundleName), for: .normal)
        setImage(UIImage.podBundleImage("Pause",bundleName:PTVideoEditorPodBundleName), for: .selected)
    }

    func updateImage() {
        isSelected = !isPaused
    }
}
