//
//  AVAsset+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/2/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public extension AVAsset {
    // English: Export to a real Documents URL and report completion only after the session finishes.
    // Español: Exporta a una URL real de Documents e informa solo cuando termina la sesión.
    // 中文：使用真实的 Documents URL 导出，并只在导出会话结束后回调。
    @MainActor func exportToDocuments(filename:String, completion: @escaping (_ outputURL: URL) -> ()) -> Bool {
        guard !filename.isEmpty,
              let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let exportSession = AVAssetExportSession(asset: self,
                                                       presetName: AVAssetExportPresetHighestQuality) else {
            PTNSLogConsole("视频导出准备失败")
            return false
        }

        let outputURL = documentsURL.appendingPathComponent(filename, isDirectory: false)
        do {
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
        } catch {
            PTNSLogConsole("清理旧的视频文件失败: \(error.localizedDescription)")
            return false
        }

        guard exportSession.supportedFileTypes.contains(.mov) else {
            PTNSLogConsole("当前视频不支持 MOV 导出")
            return false
        }

        exportSession.outputURL = outputURL
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputFileType = .mov

        Task { @MainActor in
            await exportSession.export()
            guard exportSession.status == .completed,
                  exportSession.error == nil else {
                PTNSLogConsole("导出视频失败: \(exportSession.error?.localizedDescription ?? "未知错误")")
                return
            }
            completion(outputURL)
        }
        return true
    }
    
    func getVideoFirstImage(maximumSize: CGSize = CGSize(width: 1000, height: 1000),
                            closure: @escaping @MainActor @Sendable (UIImage?) -> Void) {
        PTVideoThumbnailService.image(for: self, maximumSize: maximumSize, completion: closure)
    }
}
