//
//  AVPlayer+VideoEditorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import AVFoundation
import Foundation
import Combine
import AVKit

//MARK: Convenience
extension AVPlayer {
    func seekBackToBeginning() {
        guard let currentItem = currentItem else { return }
        let time = CMTime(seconds: 0, preferredTimescale: currentItem.asset.duration.timescale)
        seek(to: time)
    }
}

//MARK: Notifications
extension AVPlayer {
    var itemDidPlayToEnd: AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime).map { _ in () }.eraseToAnyPublisher()
    }
}

//MARK: Publishers
public extension AVPlayer {
    func progress(interval: TimeInterval = 0.02) -> AnyPublisher<CMTime, Never> {
        Publishers.PlayheadProgressPublisher(interval: interval, player: self).eraseToAnyPublisher()
    }
}

