//
//  Compositor.swift
//  Exporter
//
//  Created by Condy on 2022/12/20.
//

import Foundation
import AVFoundation
import CoreVideo

class Compositor: NSObject, AVVideoCompositing {
    
    let renderQueue = DispatchQueue(label: "com.condy.exporter.rendering.queue")
    let renderContextQueue = DispatchQueue(label: "com.condy.exporter.rendercontext.queue")
    
    var renderContext: AVVideoCompositionRenderContext!
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
    ]
    
    var sourcePixelBufferAttributes: [String : Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA,
    ]
    
    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        self.renderQueue.sync {
            guard let instruction = request.videoCompositionInstruction as? CompositionInstruction,
                  let pixels = request.sourceFrame(byTrackID: instruction.trackID) else {
                return
            }
            let buffer = instruction.bufferCallback(pixels) ?? pixels
            request.finish(withComposedVideoFrame: buffer)
        }
    }
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        self.renderContextQueue.sync {
            self.renderContext = newRenderContext
        }
    }
}
