// English: Native video export shared by camera and media features.
// Español: Exportación de vídeo nativa compartida por las funciones de cámara y medios.
// 中文：供相机和媒体功能复用的原生视频导出服务。

@preconcurrency import AVFoundation
import Foundation

public enum PTVideoExportError: Error, LocalizedError, Sendable {
    case invalidAsset
    case invalidTimeRange
    case exporterUnavailable
    case exportFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidAsset: return "视频资源不可用"
        case .invalidTimeRange: return "视频时间范围不可用"
        case .exporterUnavailable: return "无法创建视频导出器"
        case .exportFailed(let message): return message
        case .cancelled: return "视频导出已取消"
        }
    }
}

@MainActor
public enum PTVideoExportService {
    public static func export(assetURL: URL,
                              timeRange: CMTimeRange? = nil,
                              optimizeForNetworkUse: Bool = true) async throws -> URL {
        guard FileManager.default.fileExists(atPath: assetURL.path) else {
            throw PTVideoExportError.invalidAsset
        }

        let asset = AVURLAsset(url: assetURL)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ptools-export-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        guard let session = AVAssetExportSession(asset: asset,
                                                 presetName: AVAssetExportPresetHighestQuality) else {
            throw PTVideoExportError.exporterUnavailable
        }

        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = optimizeForNetworkUse
        if let timeRange {
            session.timeRange = timeRange
        }

        await session.export()
        try Task.checkCancellation()

        switch session.status {
        case .completed:
            return outputURL
        case .cancelled:
            throw PTVideoExportError.cancelled
        case .failed:
            throw PTVideoExportError.exportFailed(session.error?.localizedDescription ?? "视频导出失败")
        default:
            throw PTVideoExportError.exportFailed("视频导出未完成")
        }
    }
}
