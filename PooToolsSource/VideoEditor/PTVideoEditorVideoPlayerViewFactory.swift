//
//  PTVideoEditorVideoPlayerViewFactory.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation

protocol PTVideoEditorVideoPlayerViewFactoryProtocol {
    
    func makeFullscreenVideoPlayerController(store: PTVideoEditorVideoPlayerStore,
                                             capabilities: PTVideoEditorVideoPlayerController.Capabilities,
                                             theme: PTVideoEditorVideoPlayerController.Theme,
                                             originalFrame: CGRect?,
                                             c7Player:C7CollectorVideo,
                                             c7Image:UIImageView) -> PTVideoEditorFullscreenVideoPlayerController

    func makeControlsViewController(store: PTVideoEditorVideoPlayerStore,
                                    capabilities: PTVideoEditorVideoPlayerController.Capabilities,
                                    theme: PTVideoEditorVideoPlayerController.Theme,
                                    isFullscreen: Bool) -> PTVideoEditorControlsViewController
}

final class PTVideoEditorVideoPlayerViewFactory: PTVideoEditorVideoPlayerViewFactoryProtocol {    

    // MARK: Init

    func makeFullscreenVideoPlayerController(store: PTVideoEditorVideoPlayerStore,
                                             capabilities: PTVideoEditorVideoPlayerController.Capabilities,
                                             theme: PTVideoEditorVideoPlayerController.Theme,
                                             originalFrame: CGRect?,
                                             c7Player:C7CollectorVideo,
                                             c7Image:UIImageView) -> PTVideoEditorFullscreenVideoPlayerController {
        PTVideoEditorFullscreenVideoPlayerController(store: store,
                                                     viewFactory: self,
                                                     capabilities: capabilities,
                                                     theme: theme,
                                                     originalFrame: originalFrame,
                                                     c7Player:c7Player,
                                                     c7Image:c7Image)
    }

    func makeControlsViewController(store: PTVideoEditorVideoPlayerStore,
                                    capabilities: PTVideoEditorVideoPlayerController.Capabilities,
                                    theme: PTVideoEditorVideoPlayerController.Theme,
                                    isFullscreen: Bool) -> PTVideoEditorControlsViewController {
        PTVideoEditorControlsViewController(store: store,
                                            capabilities: capabilities,
                                            theme: theme,
                                            isFullscreen: isFullscreen)
    }
}
