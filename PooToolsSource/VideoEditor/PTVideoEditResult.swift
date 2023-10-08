//
//  PTVideoEditResult.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import AVFoundation
import Combine

public struct PTVideoEditResult {
    public let asset: AVAsset
    public let videoComposition: AVVideoComposition

    private let exporter: PTVideoEditorExporterProtocol

    init(asset: AVAsset,
         videoComposition: AVVideoComposition,
         exporter: PTVideoEditorExporterProtocol = PTVideoEditorExporter()) {
        self.asset = asset
        self.videoComposition = videoComposition
        self.exporter = exporter
    }

    public func export(to outputUrl: URL) -> AnyPublisher<Void, Error> {
        exporter.export(asset: asset, to: outputUrl, videoComposition: videoComposition)
    }
}
