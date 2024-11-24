//
//  AVExport.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
extension AVAssetExportSession: PTProtocolCompatible { }

public extension PTPOP where Base: AVAssetExportSession {
    
    // MARK: 本地视频压缩
    /// 本地视频压缩
    /// - Parameters:
    ///   - inputPath: 输入视频路径
    ///   - outputPath: 输出视频路径
    ///   - outputFileType: 导出视频类型
    ///   - handler: 处理视频的闭包，参数1：AVAssetExportSession对象，参数2：视频的时间，参数3：视频压缩后的大小，参数4：转码后的视频本地地址
    ///   - shouldOptimizeForNetworkUse: 是否优化网络
    ///   - exportPresetMediumQuality: 压缩质量，这种设置方式，最终生成的视频分辨率与具体的拍摄设备有关。比如 iPhone6 拍摄的视频：使用AVAssetExportPresetHighestQuality则视频分辨率是1920x1080（不压缩）；AVAssetExportPresetMediumQuality视频分辨率是568x320；AVAssetExportPresetLowQuality视频分辨率是224x128
    static func assetExportSession(inputPath: String,
                                   outputPath: String,
                                   outputFileType: AVFileType = .mp4,
                                   shouldOptimizeForNetworkUse: Bool = true,
                                   exportPresetMediumQuality: String = AVAssetExportPresetMediumQuality) async throws -> (AVAssetExportSession, Float64, String, String) {
        await withCheckedContinuation { continuation in
            AVAssetExportSession.pt.assetExportSession(inputPath: inputPath, outputPath: outputPath,outputFileType: outputFileType,shouldOptimizeForNetworkUse: shouldOptimizeForNetworkUse,exportPresetMediumQuality: exportPresetMediumQuality) { session, float64, outputFullFilePath, outputFilePath in
                continuation.resume(returning: (session, float64, outputFullFilePath, outputFilePath))
            }
        }
    }
    
    static func assetExportSession(inputPath: String,
                                   outputPath: String,
                                   outputFileType: AVFileType = .mp4,
                                   shouldOptimizeForNetworkUse: Bool = true,
                                   exportPresetMediumQuality: String = AVAssetExportPresetMediumQuality,
                                   completionHandler handler: @escaping (AVAssetExportSession, Float64, String, String) -> Void) {
        // 1、先检查是否存在输入是视频路径
        guard FileManager.pt.judgeFileOrFolderExists(filePath: inputPath) else {
            return
        }
        // 2、先移除转换后的路径（否则无法导出视频）
        FileManager.pt.removefile(filePath: outputPath)
        // 3、获取视频资源
        let avAsset: AVURLAsset = AVURLAsset(url: URL(fileURLWithPath: inputPath), options: nil)
        // 资源的时间
        let assetTime = avAsset.duration
        // 视频时长
        let duration = CMTimeGetSeconds(assetTime)
        // 4、配置视频压缩参数
        guard let exportSession: AVAssetExportSession = AVAssetExportSession(asset: avAsset, presetName: exportPresetMediumQuality) else {
            return
        }
        // 输出URL
        exportSession.outputURL = URL(fileURLWithPath: outputPath)
        // 转换后的格式
        exportSession.outputFileType = outputFileType
        // 优化网络
        exportSession.shouldOptimizeForNetworkUse = shouldOptimizeForNetworkUse
        // 异步导出
        Task {
            do {
                await exportSession.export()
                if exportSession.status == .completed {
                    handler(exportSession, duration, FileManager.pt.fileOrDirectorySize(path: outputPath), outputPath)
                } else {
                    handler(exportSession, duration, "", "")
                }
            }
        }
    }
    
    static func saveVideoToCache(fileURL:URL = PTUtils.outputURL(),playerItem: AVPlayerItem,result: @escaping (AVAssetExportSession.Status, AVAssetExportSession?, URL?, NSError?)->Void) {
        let videoAsset = playerItem.asset
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = .mp4

        guard let exportSession = exportSession else {
            result(.failed,nil,nil,NSError(domain: "Can not create AVAssetExportSession", code: 999))
            return
        }

        exportSession.outputURL = fileURL
        
        Task {
            do {
                await exportSession.export()
                switch exportSession.status {
                case .completed:
                    result(.completed,nil,fileURL,nil)
                case .waiting:
                    result(.waiting,exportSession,nil,nil)
                case .exporting:
                    result(.exporting,exportSession,nil,nil)
                case .failed:
                    result(.failed,exportSession,nil,NSError(domain: "Output error：\(exportSession.error?.localizedDescription ?? "")", code: 998))
                case .cancelled:
                    result(.cancelled,exportSession,nil,NSError(domain: "User cancel", code: 997))
                case .unknown:
                    result(.unknown,exportSession,nil,NSError(domain: "Unkonw error", code: 996))
                @unknown default:
                    result(.unknown,exportSession,nil,NSError(domain: "Unkonw error", code: 996))
                }
            }
        }
    }
}
