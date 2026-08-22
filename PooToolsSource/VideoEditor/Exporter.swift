//
//  Exporter.swift
//  Exporter
//
//  Created by Condy on 2022/12/20.
//

import Foundation
// AVFoundation asset/compositor APIs are legacy reference-type boundaries;
// export state is isolated on MainActor and assets use a narrow system box.
@preconcurrency import AVFoundation
import CoreVideo

public typealias ExporterBuffer = CVPixelBuffer

/// AVFoundation's asset classes are imported as non-Sendable reference types.
/// This box is deliberately limited to the read-only asset used by the export
/// pipeline; mutable export state never crosses this boundary.
struct PTSystemAVAssetBox: @unchecked Sendable {
    let asset: AVAsset
}

public struct Exporter {
    
    public typealias PixelBufferCallback = @Sendable (_ buffer: ExporterBuffer) -> ExporterBuffer?
    public typealias ExportComplete = @Sendable (Result<URL, Exporter.Error>) -> Void
    
    let provider: Exporter.Provider

    /// 保存当前导出会话，供编辑器退出时取消正在进行的导出。
    private final class State {
        var exportSession: AVAssetExportSession?
    }

    private let state: State

    /// Values copied from the public `[Option: Any]` input before the first
    /// suspension point. The raw dictionary must not cross the async/render
    /// boundary because its `Any` values are not concurrency-safe.
    private struct ExportSettings {
        let presetName: String
        let optimizeForNetworkUse: Bool
        let frameDuration: CMTime
        let renderSize: CGSize?
        let enablePostProcessing: Bool
        let containsTweening: Bool
        let layerInstructions: [AVVideoCompositionLayerInstruction]?
    }
    
    /// Craate exporter.
    /// - Parameter provider: Configure export information.
    public init(provider: Exporter.Provider) {
        self.provider = provider
        self.state = State()
    }

    /// 取消当前导出。该方法只影响当前 Exporter 实例。
    @MainActor
    func cancel() {
        state.exportSession?.cancelExport()
    }
    
    /// Export the video after add the filter.
    /// - Parameters:
    ///   - options: Setup other parameters about export video.
    ///   - filtering: Filters work to filter pixel buffer.
    ///   - complete: The conversion is complete, including success or failure.
    @MainActor
    public func export(options: [Exporter.Option: Any] = [:], filtering: @escaping PixelBufferCallback, complete: @escaping ExportComplete) async {
        guard !Task.isCancelled else {
            complete(.failure(Exporter.Error.exportAsynchronously(.cancelled)))
            return
        }

        do {
            // Snapshot every supported option while still on the caller's
            // actor. No async helper or compositor instruction receives the
            // original `[Option: Any]` dictionary.
            let settings = Self.makeSettings(from: options)
            let provider = self.provider
            let assetBox = PTSystemAVAssetBox(asset: provider.asset)
            let (composition, videoComposition) = try await Self.setupComposition(assetBox: assetBox, settings: settings, filtering: filtering)
            guard !Task.isCancelled else {
                complete(.failure(Exporter.Error.exportAsynchronously(.cancelled)))
                return
            }
            
            let export = try Self.setupExportSession(composition: composition,
                                                     outputURL: provider.outputURL,
                                                     fileType: provider.fileType,
                                                     settings: settings)
            export.videoComposition = videoComposition

            state.exportSession = export
            defer { state.exportSession = nil }
            
            let targetURL = provider.outputURL
            
            do {
                await export.export()
                if Task.isCancelled || export.status == .cancelled {
                    complete(.failure(Exporter.Error.exportAsynchronously(.cancelled)))
                    return
                }
                switch export.status {
                case .failed:
                    if let error = export.error {
                        complete(.failure(Exporter.Error.error(error)))
                    } else {
                        complete(.failure(Exporter.Error.unknown))
                    }
                case .completed:
                    complete(.success(targetURL))
                default:
                    complete(.failure(Exporter.Error.exportAsynchronously(export.status)))
                    break
                }
            }
        } catch {
            if let error = error as? Exporter.Error {
                complete(.failure(error))
            } else {
                complete(.failure(Exporter.Error.error(error)))
            }
        }
    }
}

extension Exporter {
    
    @MainActor
    private static func setupExportSession(composition: AVComposition,
                                           outputURL: URL,
                                           fileType: MovieFileType,
                                           settings: ExportSettings) throws -> AVAssetExportSession {
        guard let export = AVAssetExportSession(asset: composition, presetName: settings.presetName) else {
            throw(Exporter.Error.exportSessionEmpty)
        }
        export.outputURL = outputURL
        export.outputFileType = fileType.avFileType
        export.shouldOptimizeForNetworkUse = settings.optimizeForNetworkUse
        return export
    }

    @MainActor
    private static func setupComposition(assetBox: PTSystemAVAssetBox,
                                         settings: ExportSettings,
                                         filtering: @escaping PixelBufferCallback) async throws -> (AVComposition, AVVideoComposition) {
        let asset = assetBox.asset
        
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = videoTracks.first else {
            throw(Exporter.Error.videoTrackEmpty)
        }
        
        let naturalSize = try await Self.setupVideoRenderSize(videoTracks, assetBox: assetBox, renderSize: settings.renderSize)
        
        let duration = try await asset.load(.duration)
        
        let composition = AVMutableComposition()
        composition.naturalSize = naturalSize
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw(Exporter.Error.addVideoTrack)
        }
        
        try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: track, at: .zero)
        
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        if let audio = audioTracks.first,
           let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try audioCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: audio, at: .zero)
        }
        
        let instruction = CompositionInstruction(videoTrack: videoTrack,
                                                 bufferCallback: filtering,
                                                 containsTweening: settings.containsTweening,
                                                 enablePostProcessing: settings.enablePostProcessing,
                                                 layerInstructions: settings.layerInstructions)
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: duration)
        
        let videoComposition = try await AVMutableVideoComposition.videoComposition(withPropertiesOf: asset)
        videoComposition.customVideoCompositorClass = Compositor.self
        videoComposition.frameDuration = settings.frameDuration
        videoComposition.renderSize = naturalSize
        videoComposition.instructions = [instruction]
        
        return (composition, videoComposition)
    }

    @MainActor
    private static func makeSettings(from options: [Exporter.Option: Any]) -> ExportSettings {
        let presetName: String
        if let value = options[.ExportSessionPresetName] as? String,
           AVAssetExportSession.allExportPresets().contains(value) {
            presetName = value
        } else if options[.ExportSessionPresetName] != nil {
            presetName = AVAssetExportPresetMediumQuality
        } else {
            presetName = AVAssetExportPresetHighestQuality
        }

        return ExportSettings(
            presetName: presetName,
            optimizeForNetworkUse: (options[.OptimizeForNetworkUse] as? Bool) ?? true,
            frameDuration: (options[.VideoCompositionFrameDuration] as? CMTime) ?? CMTime(value: 1, timescale: 30),
            renderSize: options[.VideoCompositionRenderSize] as? CGSize,
            enablePostProcessing: (options[.VideoCompositionInstructionEnablePostProcessing] as? Bool) ?? true,
            containsTweening: (options[.VideoCompositionInstructionContainsTweening] as? Bool) ?? false,
            layerInstructions: options[.VideoCompositionInstructionLayerInstructions] as? [AVVideoCompositionLayerInstruction]
        )
    }
}
