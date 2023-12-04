//
//  PTVideoEditorExporter.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

protocol PTVideoEditorExporterProtocol {
    func export(asset: AVAsset,
                to url: URL,
                videoComposition: AVVideoComposition?) -> AnyPublisher<Void, Error>
}

final class PTVideoEditorExporter: PTVideoEditorExporterProtocol {
    func export(asset: AVAsset, 
                to url: URL,
                videoComposition: AVVideoComposition?) -> AnyPublisher<Void, Error> {
        Future { promise in
            
            let avItem = AVPlayerItem(asset: asset)
            AVAssetExportSession.pt.saveVideoToCache(fileURL: url, playerItem: avItem) { status, exportSession, fileUrl, error in
                if status == .completed {
                    promise(.success(()))
                } else if status == .failed {
                    promise(.failure(error!))
                    return
                }
            }
        }.eraseToAnyPublisher()
    }
}
