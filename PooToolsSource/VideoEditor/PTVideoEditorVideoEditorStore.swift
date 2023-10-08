//
//  PTVideoEditorVideoEditorStore.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation
import Combine

extension PTVideoEditResult {
    var item: AVPlayerItem {
        let item = AVPlayerItem(asset: asset)
        #if !targetEnvironment(simulator)
        item.videoComposition = videoComposition
        #endif

        return item
    }
}

final class PTVideoEditorVideoEditorStore {

    // MARK: Public Properties

    @Published private(set) var originalAsset: AVAsset

    @Published var editedPlayerItem: AVPlayerItem

    @Published var playheadProgress: CMTime = .zero

    @Published var isSeeking: Bool = false
    @Published var currentSeekingValue: Double = .zero

    @Published var speed: Double = 1.0
    @Published var trimPositions: (Double, Double) = (0.0, 1.0)
    @Published var croppingPreset: PTVideoEditorCroppingPreset?

    @Published var videoEdit: PTVideoEdit

    // MARK: Private Properties

    private var cancellables = Set<AnyCancellable>()

    private let editor: PTVideoEditor
    private let generator: PTVideoEditorVideoTimeLineGeneratorProtocol

    // MARK: Init

    init(asset: AVAsset,
         videoEdit: PTVideoEdit?,
         editor: PTVideoEditor = .init(),
         generator: PTVideoEditorVideoTimeLineGeneratorProtocol = PTVideoEditorVideoTimeLineGenerator()) {
        self.originalAsset = asset
        self.editor = editor
        self.generator = generator
        self.editedPlayerItem = AVPlayerItem(asset: asset)
        self.videoEdit = videoEdit ?? PTVideoEdit()

        setupBindings()
    }
}

// MARK: Bindings

fileprivate extension PTVideoEditorVideoEditorStore {
    func setupBindings() {
        $videoEdit
            .setFailureType(to: Error.self)
            .flatMap { [weak self] edit -> AnyPublisher<PTVideoEditResult, Error> in
                self!.editor.apply(edit: edit, to: self!.originalAsset)
            }
            .map(\.item)
            .replaceError(with: AVPlayerItem(asset: originalAsset))
            .assign(to: \.editedPlayerItem, weakly: self)
            .store(in: &cancellables)

        $speed
            .dropFirst(1)
            .filter { [weak self] speed in
                guard let self = self else { return false }
                return speed != self.videoEdit.speedRate
            }
            .compactMap { [weak self] speedRate in
                guard let self = self else { return nil }
                return PTVideoEdit.speedRateLens.to(speedRate, self.videoEdit)
            }
            .assign(to: \.videoEdit, weakly: self)
            .store(in: &cancellables)

        $trimPositions
            .dropFirst(1)
            .compactMap { [weak self] trimPositions in
                guard let self = self else { return nil }
                let startTime = CMTime(
                    seconds: self.originalDuration.seconds * trimPositions.0,
                    preferredTimescale: self.originalDuration.timescale
                )
                let endTime = CMTime(
                    seconds: self.originalDuration.seconds * trimPositions.1,
                    preferredTimescale: self.originalDuration.timescale
                )
                let positions = (startTime, endTime)

                return PTVideoEdit.trimPositionsLens.to(positions, self.videoEdit)
            }
            .assign(to: \.videoEdit, weakly: self)
            .store(in: &cancellables)

        $croppingPreset
            .dropFirst(1)
            .filter { [weak self] croppingPreset in
                guard let self = self else { return false }
                return croppingPreset != self.videoEdit.croppingPreset
            }
            .compactMap { [weak self] croppingPreset in
                guard let self = self else { return nil }
                return PTVideoEdit.croppingPresetLens.to(croppingPreset, self.videoEdit)
            }
            .assign(to: \.videoEdit, weakly: self)
            .store(in: &cancellables)

    }
}

// MARK: Public Accessors

extension PTVideoEditorVideoEditorStore {
    var currentSeekingTime: CMTime {
        CMTime(seconds: duration.seconds * currentSeekingValue, preferredTimescale: duration.timescale)
    }

    var assetAspectRatio: CGFloat {
        guard let track = editedPlayerItem.asset.tracks(withMediaType: AVMediaType.video).first else {
            return .zero
        }

        let assetSize = track.naturalSize.applying(track.preferredTransform)

        return abs(assetSize.width) / abs(assetSize.height)
    }

    var originalDuration: CMTime {
        originalAsset.duration
    }

    var duration: CMTime {
        editedPlayerItem.asset.duration
    }

    var fractionCompleted: Double {
        guard duration != .zero else {
            return .zero
        }

        return playheadProgress.seconds / duration.seconds
    }
    
    func videoTimeline(for asset: AVAsset, in bounds: CGRect) -> AnyPublisher<[CGImage], Error> {
        generator.videoTimeline(for: asset, in: bounds, numberOfFrames: numberOfFrames(within: bounds))
    }

    func export(to url: URL) -> AnyPublisher<Void, Error> {
        editor.apply(edit: videoEdit, to: originalAsset)
            .flatMap { $0.export(to: url) }
            .eraseToAnyPublisher()
    }
}

// MARK: Private Accessors

fileprivate extension PTVideoEditorVideoEditorStore {
    func numberOfFrames(within bounds: CGRect) -> Int {
        let frameWidth = bounds.height * assetAspectRatio
        return Int(bounds.width / frameWidth) + 1
    }
}
