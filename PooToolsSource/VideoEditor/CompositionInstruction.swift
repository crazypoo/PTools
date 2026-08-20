//
//  CompositionInstruction.swift
//  Exporter
//
//  Created by Condy on 2022/12/20.
//

import Foundation
import AVFoundation

class CompositionInstruction: AVMutableVideoCompositionInstruction, @unchecked Sendable {
    
    let trackID: CMPersistentTrackID
    let videoTrack: AVCompositionTrack
    let bufferCallback: Exporter.PixelBufferCallback
    private let containsTweeningValue: Bool
    
    override var requiredSourceTrackIDs: [NSValue] {
        get {
            return [NSNumber(value: Int(self.trackID))]
        }
    }
    
    override var containsTweening: Bool {
        containsTweeningValue
    }
    
    init(videoTrack: AVCompositionTrack,
         bufferCallback: @escaping Exporter.PixelBufferCallback,
         containsTweening: Bool,
         enablePostProcessing: Bool,
         layerInstructions: [AVVideoCompositionLayerInstruction]?) {
        self.trackID = videoTrack.trackID
        self.videoTrack = videoTrack
        self.bufferCallback = bufferCallback
        self.containsTweeningValue = containsTweening
        super.init()
        self.enablePostProcessing = enablePostProcessing
        if let layerInstructions {
            self.layerInstructions = layerInstructions
        } else {
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            layerInstruction.trackID = videoTrack.trackID
            self.layerInstructions = [layerInstruction]
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
