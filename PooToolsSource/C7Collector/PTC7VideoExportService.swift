// English: Native C7 video export keeps the existing Harbeth filter pipeline without Kakapos.
// Español: La exportación nativa de vídeo C7 conserva el pipeline de filtros Harbeth sin Kakapos.
// 中文：C7 原生视频导出保留现有 Harbeth 滤镜管线，不再依赖 Kakapos。

@preconcurrency import AVFoundation
import CoreVideo
import Foundation
import Harbeth

// English: Harbeth filters are created before export and accessed only by the serial compositor queue.
// Español: Los filtros Harbeth se crean antes de exportar y solo los usa la cola serial del compositor.
// 中文：Harbeth 滤镜在导出前创建，只由串行 compositor 队列访问。
private struct PTC7FilterBox: @unchecked Sendable {
    let filters: [C7FilterProtocol]
}

private final class PTC7VideoCompositionInstruction: AVMutableVideoCompositionInstruction, @unchecked Sendable {
    let trackID: CMPersistentTrackID
    let filterBox: PTC7FilterBox

    override var requiredSourceTrackIDs: [NSValue] {
        [NSNumber(value: Int(trackID))]
    }

    override var containsTweening: Bool { false }

    init(trackID: CMPersistentTrackID,
         filterBox: PTC7FilterBox,
         layerInstructions: [AVVideoCompositionLayerInstruction]) {
        self.trackID = trackID
        self.filterBox = filterBox
        super.init()
        self.layerInstructions = layerInstructions
    }

    @available(*, unavailable, message: "Use programmatic initialization.")
    required init?(coder: NSCoder) {
        nil
    }
}

private final class PTC7VideoFilterCompositor: NSObject, AVVideoCompositing, @unchecked Sendable {
    let requiredPixelBufferAttributesForRenderContext: [String: any Sendable] = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]

    let sourcePixelBufferAttributes: [String: any Sendable]? = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]

    private let renderQueue = DispatchQueue(label: "com.pootools.c7.video-render", qos: .userInitiated)
    private let renderContextQueue = DispatchQueue(label: "com.pootools.c7.video-render-context")
    private var renderContext: AVVideoCompositionRenderContext?

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        renderQueue.sync {
            guard let instruction = request.videoCompositionInstruction as? PTC7VideoCompositionInstruction,
                  let sourceBuffer = request.sourceFrame(byTrackID: instruction.trackID) else {
                request.finish(with: NSError(domain: "PooTools.C7VideoExport", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "无法获取视频合成源帧"
                ]))
                return
            }

            guard !instruction.filterBox.filters.isEmpty else {
                request.finish(withComposedVideoFrame: sourceBuffer)
                return
            }

            let output = HarbethIO(element: sourceBuffer, filters: instruction.filterBox.filters)
            guard let filteredBuffer = try? output.output() else {
                request.finish(with: NSError(domain: "PooTools.C7VideoExport", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "视频滤镜处理失败"
                ]))
                return
            }
            request.finish(withComposedVideoFrame: filteredBuffer)
        }
    }

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync {
            renderContext = newRenderContext
        }
    }

    func cancelAllPendingVideoCompositionRequests() {
        // English: Requests are serialized and finish synchronously, so no extra cancellation state is needed.
        // Español: Las solicitudes son seriales y finalizan de forma síncrona; no hace falta otro estado de cancelación.
        // 中文：请求按串行队列同步结束，不需要额外维护取消状态。
    }
}

@MainActor
enum PTC7VideoExportService {
    static func export(assetURL: URL,
                       timeRange: CMTimeRange?,
                       optimizeForNetworkUse: Bool,
                       filters: [C7FilterProtocol]) async throws -> URL {
        guard FileManager.default.fileExists(atPath: assetURL.path) else {
            throw PTVideoExportError.invalidAsset
        }

        let asset = AVURLAsset(url: assetURL)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let sourceVideoTrack = videoTracks.first else {
            throw PTVideoExportError.invalidAsset
        }

        let sourceDuration = try await asset.load(.duration)
        guard sourceDuration.isNumeric, sourceDuration.seconds > 0 else {
            throw PTVideoExportError.invalidAsset
        }

        let requestedRange = timeRange ?? CMTimeRange(start: .zero, duration: sourceDuration)
        let start = clamp(requestedRange.start, lower: .zero, upper: sourceDuration)
        let requestedEnd = CMTimeAdd(requestedRange.start, requestedRange.duration)
        let end = clamp(requestedEnd, lower: start, upper: sourceDuration)
        guard CMTimeCompare(end, start) > 0 else {
            throw PTVideoExportError.invalidTimeRange
        }
        let exportRange = CMTimeRange(start: start, duration: CMTimeSubtract(end, start))

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw PTVideoExportError.invalidAsset
        }
        try compositionVideoTrack.insertTimeRange(exportRange,
                                                   of: sourceVideoTrack,
                                                   at: .zero)

        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        if let sourceAudioTrack = audioTracks.first,
           let compositionAudioTrack = composition.addMutableTrack(
               withMediaType: .audio,
               preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try compositionAudioTrack.insertTimeRange(exportRange,
                                                      of: sourceAudioTrack,
                                                      at: .zero)
        }

        let naturalSize = try await sourceVideoTrack.load(.naturalSize)
        let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
        let transformedSize = naturalSize.applying(preferredTransform)
        let renderSize = CGSize(width: max(abs(transformedSize.width), 1),
                                height: max(abs(transformedSize.height), 1))
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(preferredTransform, at: .zero)

        let instruction = PTC7VideoCompositionInstruction(
            trackID: compositionVideoTrack.trackID,
            filterBox: PTC7FilterBox(filters: filters),
            layerInstructions: [layerInstruction]
        )
        instruction.timeRange = CMTimeRange(start: .zero, duration: exportRange.duration)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = PTC7VideoFilterCompositor.self
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [instruction]

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ptools-c7-export-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        guard let exportSession = AVAssetExportSession(asset: composition,
                                                        presetName: AVAssetExportPresetHighestQuality) else {
            throw PTVideoExportError.exporterUnavailable
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = optimizeForNetworkUse
        exportSession.videoComposition = videoComposition

        await exportSession.export()
        try Task.checkCancellation()

        switch exportSession.status {
        case .completed:
            return outputURL
        case .cancelled:
            throw PTVideoExportError.cancelled
        case .failed:
            throw PTVideoExportError.exportFailed(exportSession.error?.localizedDescription ?? "视频导出失败")
        default:
            throw PTVideoExportError.exportFailed("视频导出未完成")
        }
    }

    private static func clamp(_ value: CMTime, lower: CMTime, upper: CMTime) -> CMTime {
        if CMTimeCompare(value, lower) < 0 { return lower }
        if CMTimeCompare(value, upper) > 0 { return upper }
        return value
    }
}
