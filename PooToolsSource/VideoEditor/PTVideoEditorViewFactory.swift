//
//  PTVideoEditorViewFactory.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import AVFoundation

protocol PTVideoEditorViewFactoryProtocol {
    func makeVideoPlayerController() -> PTVideoEditorVideoPlayerController
    func makeVideoTimelineViewController(store: PTVideoEditorVideoEditorStore) -> PTVideoEditorTimeLineViewController
    func makeVideoControlListController(store: PTVideoEditorVideoEditorStore) -> PTVideoEditorVideoControlListController
    func makeVideoControlViewController(asset: AVAsset,
                                        speed: Double,
                                        trimPositions: (Double, Double)) -> PTVideoEditorVideoControlViewController
    func makeCropVideoControlViewController() -> PTVideoEditorCropVideoControlViewController
    func makeSpeedVideoControlViewController(speed: Double) -> PTVideoEditorSpeedVideoControlViewController
    func makeTrimVideoControlViewController(asset: AVAsset, 
                                            trimPositions: (Double, Double)) -> PTVideoEditorTrimVideoControlViewController
}

final class PTVideoEditorVideoViewFactory: PTVideoEditorViewFactoryProtocol {
    
    func makeVideoPlayerController() -> PTVideoEditorVideoPlayerController {
        var theme = PTVideoEditorVideoPlayerController.Theme()
        theme.backgroundStyle = .plain(.white)
        return PTVideoEditorVideoPlayerController(capabilities: .none, theme: theme)
    }

    func makeVideoTimelineViewController(store: PTVideoEditorVideoEditorStore) -> PTVideoEditorTimeLineViewController {
        PTVideoEditorTimeLineViewController(store: store)
    }

    func makeVideoControlListController(store: PTVideoEditorVideoEditorStore) -> PTVideoEditorVideoControlListController {
        PTVideoEditorVideoControlListController(store: store, viewFactory: self)
    }

    func makeVideoControlViewController(asset: AVAsset,
                                        speed: Double,
                                        trimPositions: (Double, Double)) -> PTVideoEditorVideoControlViewController {
        let controller = PTVideoEditorVideoControlViewController(asset: asset,
                                                                 speed: speed,
                                                                 trimPositions: trimPositions,
                                                                 viewFactory: self)

        return controller
    }

    func makeCropVideoControlViewController() -> PTVideoEditorCropVideoControlViewController {
        PTVideoEditorCropVideoControlViewController()
    }

    func makeSpeedVideoControlViewController(speed: Double) -> PTVideoEditorSpeedVideoControlViewController {
        PTVideoEditorSpeedVideoControlViewController(speed: speed)
    }

    func makeTrimVideoControlViewController(asset: AVAsset, 
                                            trimPositions: (Double, Double)) -> PTVideoEditorTrimVideoControlViewController {
        PTVideoEditorTrimVideoControlViewController(asset: asset, trimPositions: trimPositions)
    }

}
