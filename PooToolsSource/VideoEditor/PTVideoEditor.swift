//
//  PTVideoEditor.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import AVFoundation
import Combine

enum PTVideoEditorError: Error {
    case unknown
}

public protocol PTVideoEditorProtocol {
    func apply(edit: PTVideoEdit,
               to originalAsset: AVAsset) -> AnyPublisher<PTVideoEditResult, Error>
}

public final class PTVideoEditor: PTVideoEditorProtocol {

    // MARK: Init

    public init() {}

    public func apply(edit: PTVideoEdit, 
                      to originalAsset: AVAsset) -> AnyPublisher<PTVideoEditResult, Error> {
        Future { promise in
            let composition = AVMutableComposition()

            guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                  let videoTrack = originalAsset.tracks(withMediaType: .video).first else {
                promise(.failure(PTVideoEditorError.unknown))
                return
            }

            let range: CMTimeRange
            let duration: CMTime
            if let trimPositions = edit.trimPositions {
                let value = trimPositions.1.seconds - trimPositions.0.seconds
                duration = CMTime(seconds: value, preferredTimescale: originalAsset.duration.timescale)
                range = CMTimeRange(start: trimPositions.0, duration: duration)
            } else {
                duration = originalAsset.duration
                range = CMTimeRange(start: .zero, duration: duration)
            }

            do {
                try videoCompositionTrack.insertTimeRange(range, of: videoTrack, at: .zero)

                let newDuration = Double(duration.seconds) / edit.speedRate
                let time = CMTime(seconds: newDuration, preferredTimescale: duration.timescale)
                let newRange = CMTimeRange(start: .zero, duration: duration)
                videoCompositionTrack.scaleTimeRange(newRange, toDuration: time)
                videoCompositionTrack.preferredTransform = videoTrack.preferredTransform

                if let audioTrack = originalAsset.tracks(withMediaType: .audio).first, !edit.isMuted {
                    guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                        promise(.failure(PTVideoEditorError.unknown))
                        return
                    }
                    try audioCompositionTrack.insertTimeRange(range, of: audioTrack, at: .zero)
                    audioCompositionTrack.scaleTimeRange(newRange, toDuration: time)
                }
            } catch {
                promise(.failure(PTVideoEditorError.unknown))
                return
            }

            let videoComposition = self.makeVideoComposition(
                edit: edit,
                videoCompositionTrack: videoCompositionTrack,
                videoTrack: videoTrack,
                duration: composition.duration
            )

            let result = PTVideoEditResult(
                asset: composition,
                videoComposition: videoComposition
            )

            promise(.success(result))
        }.eraseToAnyPublisher()
    }
}

fileprivate extension PTVideoEditor {
    func makeVideoComposition(edit: PTVideoEdit,
                              videoCompositionTrack: AVCompositionTrack,
                              videoTrack: AVAssetTrack,
                              duration: CMTime) -> AVVideoComposition {
        let naturalSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let renderSize = makeRenderSize(naturalSize: naturalSize, croppingPreset: edit.croppingPreset)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)

        if let transform = makeLayerInstructionTransform(naturalSize: naturalSize, renderSize: renderSize, croppingPreset: edit.croppingPreset) {
            videoLayerInstruction.setTransform(transform, at: .zero)
        }

        instruction.layerInstructions = [
            videoLayerInstruction
        ]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderScale = 1.0

        return videoComposition
    }

    func makeLayerInstructionTransform(naturalSize: CGSize,
                                       renderSize: CGSize,
                                       croppingPreset: PTVideoEditorCroppingPreset?) -> CGAffineTransform? {
        guard croppingPreset != nil else {
            return nil
        }

        let widthOffset = -(naturalSize.width - renderSize.width) / 2
        let heightOffset = -(naturalSize.height - renderSize.height) / 2

        return CGAffineTransform(translationX: widthOffset, y: heightOffset)
    }

    func makeRenderSize(naturalSize: CGSize,
                        croppingPreset: PTVideoEditorCroppingPreset?) -> CGSize {
        guard let croppingPreset = croppingPreset else {
            return CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
        }

        let width = naturalSize.width
        let height = naturalSize.height

        let renderSize: CGSize
        if width > height {
            let newWidth = height * CGFloat(croppingPreset.widthToHeightRatio)
            renderSize = CGSize(width: newWidth, height: height)
        } else {
            let newHeight = width / CGFloat(croppingPreset.widthToHeightRatio)
            renderSize = CGSize(width: width, height: newHeight)
        }

        return renderSize
    }
}
