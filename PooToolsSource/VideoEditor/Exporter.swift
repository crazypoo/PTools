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
    
    public typealias PixelBufferCallback = @Sendable (_ buffer: ExporterBuffer) -> ExporterBuffer?
    public typealias ExportComplete = @Sendable (Result<URL, Exporter.Error>) -> Void
    
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
    public func export(options: [Exporter.Option: Any] = [:], filtering: @escaping PixelBufferCallback, complete: @escaping ExportComplete) async {
        do {
            let (composition, videoComposition) = try await setupComposition(options: options, filtering: filtering)
            
            // 🚀 修复核心 1：使用 nonisolated(unsafe) 关键字。
            // 这明确告诉 Swift 6 编译器：我知道这个 export 对象不是 Sendable，
            // 但我保证它的生命周期是安全的，请允许它被闭包捕获。
            nonisolated(unsafe) let export = try setupExportSession(composition: composition, options: options)
            export.videoComposition = videoComposition
            
            // 🚀 修复核心 2：提前提取 URL，切断对 self 的依赖。
            // URL 类型天生是 Sendable 的，这样 Task 就只会捕获 targetURL，彻底忘掉 self。
            let targetURL = provider.outputURL
            
            Task {
                do {
                    await export.export()
                    switch export.status {
                    case .failed:
                        if let error = export.error {
                            complete(.failure(Exporter.Error.error(error)))
                        } else {
                            complete(.failure(Exporter.Error.unknown))
                        }
                    case .completed:
                        // 🚀 修复核心 3：在这里使用刚刚提取的安全局部变量 targetURL
                        complete(.success(targetURL))
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

    private func setupComposition(options: [Exporter.Option: Any], filtering: @escaping PixelBufferCallback) async throws -> (AVComposition, AVVideoComposition) {
        
        var videoFrameDuration = CMTimeMake(value: 1, timescale: 30)
        
        // 🌟 2. 字典取值极简优化：告别啰嗦的 for 循环 switch
        if let value = options[.VideoCompositionFrameDuration] as? CMTime {
            videoFrameDuration = value
        }
        
        let asset = self.provider.asset
        
        // 🌟 3. 异步获取视频轨道
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = videoTracks.first else {
            throw(Exporter.Error.videoTrackEmpty)
        }
        
        // 🌟 4. 无缝衔接刚才重构的异步方法
        let naturalSize = try await setupVideoRenderSize(videoTracks, asset: asset, options: options)
        
        // 🌟 5. 异步获取资产总时长
        let duration = try await asset.load(.duration)
        
        let composition = AVMutableComposition()
        composition.naturalSize = naturalSize
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw(Exporter.Error.addVideoTrack)
        }
        
        try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: track, at: .zero)
        
        // 🌟 6. 异步获取音频轨道
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        if let audio = audioTracks.first,
           let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try audioCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: audio, at: .zero)
        }
        
        let instruction = CompositionInstruction(videoTrack: videoTrack, bufferCallback: filtering, options: options)
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: duration)
        
        // 🌟 7. iOS 16+ 专属适配：使用异步工厂方法初始化 VideoComposition，防止阻塞底层
        let videoComposition = try await AVMutableVideoComposition.videoComposition(withPropertiesOf: asset)
        videoComposition.customVideoCompositorClass = Compositor.self
        videoComposition.frameDuration = videoFrameDuration
        videoComposition.renderSize = naturalSize
        videoComposition.instructions = [instruction]
        
        return (composition, videoComposition)
    }
}
