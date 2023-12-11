//
//  CompositionInstruction.swift
//  Exporter
//
//  Created by Condy on 2022/12/20.
//

import Foundation
import AVFoundation

class CompositionInstruction: AVMutableVideoCompositionInstruction {
    
    let trackID: CMPersistentTrackID
    let videoTrack: AVCompositionTrack
    let bufferCallback: Exporter.PixelBufferCallback
    let options: [Exporter.Option: Any]
    
    override var requiredSourceTrackIDs: [NSValue] {
        get {
            return [NSNumber(value: Int(self.trackID))]
        }
    }
    
    override var containsTweening: Bool {
        get {
            guard options.keys.contains(where: { $0 == .VideoCompositionInstructionContainsTweening }),
                  let value = options[.VideoCompositionInstructionContainsTweening] as? Bool else {
                return false
            }
            return value
        }
    }
    
    init(videoTrack: AVCompositionTrack, bufferCallback: @escaping Exporter.PixelBufferCallback, options: [Exporter.Option: Any]) {
        self.trackID = videoTrack.trackID
        self.videoTrack = videoTrack
        self.bufferCallback = bufferCallback
        self.options = options
        super.init()
        self.setupOptions(options)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupOptions(_ options: [Exporter.Option: Any]) {
        var enablePostProcessing = true
        for (key, value) in options {
            switch (key, value) {
            case (.VideoCompositionInstructionEnablePostProcessing, let value as Bool):
                enablePostProcessing = value
            default:
                break
            }
        }
        self.enablePostProcessing = enablePostProcessing
        self.layerInstructions = setupLayerInstructions(options: options)
    }
    
    private func setupLayerInstructions(options: [Exporter.Option: Any]) -> [AVVideoCompositionLayerInstruction] {
        guard options.keys.contains(where: { $0 == .VideoCompositionInstructionLayerInstructions }),
              let value = options[.VideoCompositionInstructionLayerInstructions] as? [AVVideoCompositionLayerInstruction] else {
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            layerInstruction.trackID = videoTrack.trackID
            return [layerInstruction]
        }
        return value
    }
}
