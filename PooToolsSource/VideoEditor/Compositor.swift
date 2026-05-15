//
//  Compositor.swift
//  Exporter
//
//  Created by Condy on 2022/12/20.
//

import Foundation
import AVFoundation
import CoreVideo

// ⭐️ 核心改进 1：声明为 @unchecked Sendable。
// 因为系统要求继承 NSObject 无法使用 actor，且我们手动用 GCD 保证了线程安全，
// 所以通过 @unchecked 显式告知 Swift 6 编译器跳过对这个类的严格状态并发检查。
public final class Compositor: NSObject, AVVideoCompositing, @unchecked Sendable {
    
    private let renderQueue = DispatchQueue(label: "com.condy.exporter.rendering.queue")
    private let renderContextQueue = DispatchQueue(label: "com.condy.exporter.rendercontext.queue")
    
    // ⭐️ 核心改进 2：私有化可变状态。真实数据仅在队列闭包中访问。
    private var _renderContext: AVVideoCompositionRenderContext?
    
    // 提供线程安全的对外读取接口（如果外部需要的话）
    var renderContext: AVVideoCompositionRenderContext? {
        renderContextQueue.sync { _renderContext }
    }
    
    // ⭐️ 核心改进 3：将 var 改为 let。
    // 协议仅要求 { get }，设为常量能彻底消除非隔离状态的数据竞争警告。
    public let requiredPixelBufferAttributesForRenderContext: [String : Any] = [
        kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA
    ]
    
    public let sourcePixelBufferAttributes: [String : Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA
    ]
    
    public func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        // AVFoundation 会在后台线程调用此方法，使用 sync 将渲染任务串行化
        self.renderQueue.sync {
            guard let instruction = request.videoCompositionInstruction as? CompositionInstruction,
                  let pixels = request.sourceFrame(byTrackID: instruction.trackID) else {
                
                // 💡 优化建议：如果获取失败，最好 finish 抛出错误，而不是直接 return 导致后续流程挂起
                let error = NSError(domain: "com.condy.exporter.compositor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract source frame or instruction."])
                request.finish(with: error)
                return
            }
            
            // ⚠️ 前提假设：`bufferCallback` 闭包已经在 CompositionInstruction 中被标记为 @Sendable
            let buffer = instruction.bufferCallback(pixels) ?? pixels
            request.finish(withComposedVideoFrame: buffer)
        }
    }
    
    public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        self.renderContextQueue.sync {
            self._renderContext = newRenderContext
        }
    }
}
