//
//  Exporter.swift
//  Exporter
//
//  Created by Condy on 2022/12/20.
//

import Foundation
import AVFoundation
import CoreVideo

public typealias ExporterBuffer = CVPixelBuffer

public struct Exporter {
    
    public typealias PixelBufferCallback = (_ buffer: ExporterBuffer) -> ExporterBuffer?
    public typealias ExportComplete = (Result<URL, Exporter.Error>) -> Void
    
    let provider: Exporter.Provider
    
    /// Craate exporter.
    /// - Parameter provider: Configure export information.
    public init(provider: Exporter.Provider) {
        self.provider = provider
    }
    
    /// Export the video after add the filter.
    /// - Parameters:
    ///   - options: Setup other parameters about export video.
    ///   - filtering: Filters work to filter pixel buffer.
    ///   - complete: The conversion is complete, including success or failure.
    public func export(options: [Exporter.Option: Any] = [:], filtering: @escaping PixelBufferCallback, complete: @escaping ExportComplete) {
        do {
            let (composition, videoComposition) = try setupComposition(options: options, filtering: filtering)
            let export = try setupExportSession(composition: composition, options: options)
            export.videoComposition = videoComposition
            export.exportAsynchronously { [weak export] in
                guard let export = export else { return }
                DispatchQueue.main.async {
                    switch export.status {
                    case .failed:
                        if let error = export.error {
                            complete(.failure(Exporter.Error.error(error)))
                        } else {
                            complete(.failure(Exporter.Error.unknown))
                        }
                    case .completed:
                        complete(.success(provider.outputURL))
                    default:
                        complete(.failure(Exporter.Error.exportAsynchronously(export.status)))
                        break
                    }
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
    
    private func setupExportSession(composition: AVComposition, options: [Exporter.Option: Any]) throws -> AVAssetExportSession {
        let presetName = setupPresetName(options: options)
        guard let export = AVAssetExportSession(asset: composition, presetName: presetName) else {
            throw(Exporter.Error.exportSessionEmpty)
        }
        export.outputURL = provider.outputURL
        export.outputFileType = provider.fileType.avFileType
        export.shouldOptimizeForNetworkUse = setupOptimizeForNetworkUse(options: options)
        return export
    }
    
    private func setupComposition(options: [Exporter.Option: Any], filtering: @escaping PixelBufferCallback) throws -> (AVComposition, AVVideoComposition) {
        var videoFrameDuration = CMTimeMake(value: 1, timescale: 30)
        for (key, value) in options {
            switch (key, value) {
            case (.VideoCompositionFrameDuration, let value as CMTime):
                videoFrameDuration = value
            default:
                break
            }
        }
        
        let asset = self.provider.asset
        let videoTracks = asset.tracks(withMediaType: .video)
        guard let track = videoTracks.first else {
            throw(Exporter.Error.videoTrackEmpty)
        }
        let naturalSize = setupVideoRenderSize(videoTracks, asset: asset, options: options)
        let composition = AVMutableComposition()
        composition.naturalSize = naturalSize
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw(Exporter.Error.addVideoTrack)
        }
        try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: track, at: .zero)
        
        if let audio = asset.tracks(withMediaType: .audio).first,
           let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try audioCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: audio, at: .zero)
        }
        
        let instruction = CompositionInstruction(videoTrack: videoTrack, bufferCallback: filtering, options: options)
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
        
        let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
        videoComposition.customVideoCompositorClass = Compositor.self
        videoComposition.frameDuration = videoFrameDuration
        videoComposition.renderSize = naturalSize
        videoComposition.instructions = [instruction]
        
        return (composition, videoComposition)
    }
}
