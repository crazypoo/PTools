//
//  Options.swift
//  KakaposExamples
//
//  Created by Condy on 2023/7/31.
//

import Foundation
import AVFoundation
import CoreVideo

extension Exporter {
    
    /// Exporter with options.
    public struct Option : Hashable, Equatable, RawRepresentable, @unchecked Sendable {
        public let rawValue: UInt16
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }
}

extension Exporter.Option {
    
    /// Indicates that the output file should be optimized for network use.
    public static let OptimizeForNetworkUse: Exporter.Option = .init(rawValue: 1 << 0)
    
    /// These export options can be used to produce movie files with video size appropriate to the device.
    public static let ExportSessionPresetName: Exporter.Option = .init(rawValue: 1 << 1)
    
    /// Indicates the interval which the video composition, when enabled, should render composed video frames.
    public static let VideoCompositionFrameDuration: Exporter.Option = .init(rawValue: 1 << 2)
    
    /// Indicates the size at which the video composition, when enabled, should render.
    /// If not set, the value is the size of the composition's first video track. Set to CGSizeZero to revert to default behavior.
    public static let VideoCompositionRenderSize: Exporter.Option = .init(rawValue: 1 << 3)
    
    /// If NO, indicates that post-processing should be skipped for the duration of this instruction.  YES by default.
    /// See +[AVVideoCompositionCoreAnimationTool videoCompositionToolWithPostProcessingAsVideoLayer:inLayer:].
    public static let VideoCompositionInstructionEnablePostProcessing: Exporter.Option = .init(rawValue: 1 << 4)
    
    /// If YES, rendering a frame from the same source buffers and the same composition instruction at 2 different compositionTime may yield different output frames.
    /// If NO, 2 such compositions would yield the same frame.
    /// The media pipeline may be able to avoid some duplicate processing when containsTweening is NO
    public static let VideoCompositionInstructionContainsTweening: Exporter.Option = .init(rawValue: 1 << 5)
    
    /// Provides an array of instances of AVVideoCompositionLayerInstruction that specify how video frames from source tracks should be layered and composed.
    /// Tracks are layered in the composition according to the top-to-bottom order of the layerInstructions array;
    /// the track with trackID of the first instruction in the array will be layered on top, with the track with the trackID of the second instruction immediately underneath, etc.
    /// If this key is nil, the output will be a fill of the background color.
    public static let VideoCompositionInstructionLayerInstructions: Exporter.Option = .init(rawValue: 1 << 6)
}

extension Exporter {
    
    func setupPresetName(options: [Exporter.Option: Any]) -> String {
        guard options.keys.contains(where: { $0 == .ExportSessionPresetName }),
              let presetName = options[.ExportSessionPresetName] as? String else {
            return AVAssetExportPresetHighestQuality
        }
        if !AVAssetExportSession.allExportPresets().contains(presetName) {
            return AVAssetExportPresetMediumQuality
        }
        return presetName
    }
    
    func setupVideoRenderSize(_ videoTracks: [AVAssetTrack], asset: AVAsset, options: [Exporter.Option: Any]) -> CGSize {
        guard options.keys.contains(where: { $0 == .VideoCompositionRenderSize }),
              let size = options[.VideoCompositionRenderSize] as? CGSize else {
            /// AVMutableVideoComposition's renderSize property is buggy with some assets.
            /// Calculate the renderSize here based on the documentation of `AVMutableVideoComposition(propertiesOf:)`
            if let composition = asset as? AVComposition {
                return composition.naturalSize
            } else {
                var renderSize: CGSize = .zero
                for videoTrack in videoTracks {
                    let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
                    renderSize.width  = max(renderSize.width, abs(size.width))
                    renderSize.height = max(renderSize.height, abs(size.height))
                }
                return renderSize
            }
        }
        return size
    }
    
    func setupOptimizeForNetworkUse(options: [Exporter.Option: Any]) -> Bool {
        guard options.keys.contains(where: { $0 == .OptimizeForNetworkUse }),
              let value = options[.OptimizeForNetworkUse] as? Bool else {
            return true
        }
        return value
    }
}
