//
//  AVAsset+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/2/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation

public extension AVAsset {
    func exportToDocuments(filename:String, completion: @escaping (_ outputURL: URL) -> ()) -> Bool {
        
        var isExporting = false
        
        if let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetHighestQuality) {
            if let documentsURL = URL(string: FileManager.pt.DocumnetsDirectory()) {
                let outputURL = documentsURL.appendingPathComponent(filename)
                if FileManager.pt.judgeFileOrFolderExists(filePath: outputURL.path) {
                    FileManager.pt.removefile(filePath: outputURL.path)
                } else {
                    FileManager.pt.createFile(filePath: outputURL.path)
                }
                exportSession.outputURL = URL(fileURLWithPath: outputURL.absoluteString)
                exportSession.shouldOptimizeForNetworkUse = true
                exportSession.outputFileType = AVFileType.mov
                
                isExporting = true
                
                Task {
                    do {
                        await exportSession.export()
                        if exportSession.status == .completed && exportSession.error == nil {
                            completion(outputURL)
                        } else {
                            PTNSLogConsole("导出视频失败")
                        }
                        return isExporting
                    }
                }
                return isExporting
            } else {
                PTNSLogConsole("没有这个文件夹")
                return false
            }
        } else {
            return isExporting
        }
    }
}
