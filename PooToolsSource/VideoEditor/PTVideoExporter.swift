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
            let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
            exporter?.outputURL = url
            exporter?.outputFileType = .mp4
            exporter?.videoComposition = videoComposition

            exporter?.exportAsynchronously(completionHandler: {
                if let error = exporter?.error {
                    promise(.failure(error))
                    return
                }

                promise(.success(()))
            })
        }.eraseToAnyPublisher()

    }
}
