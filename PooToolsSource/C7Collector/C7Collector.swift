//
//  C7Collector.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

// English: Import the umbrella Core target explicitly for standalone SwiftPM builds.
// Español: Importa explícitamente el target Core para las compilaciones SwiftPM independientes.
// 中文：独立 SwiftPM 编译时，显式导入 Core 聚合 target。
#if SWIFT_PACKAGE
import ptools
#endif
import CoreVideo
import Harbeth

// English: Harbeth has finished producing these SDK objects before they cross to MainActor.
// Español: Harbeth ya terminó de producir estos objetos del SDK antes de cruzar a MainActor.
// 中文：Harbeth 在对象跨到 MainActor 前已经完成生成，跨 actor 期间只读这些系统对象。
private struct PTSystemTextureBox: @unchecked Sendable {
    let value: MTLTexture
}

private struct PTSystemImageBox: @unchecked Sendable {
    let value: UIImage
}

@objc public protocol C7CollectorImageDelegate: NSObjectProtocol {
    
    /// The filter image is returned in the child thread.
    ///
    /// - Parameters:
    ///   - collector: collector
    ///   - image: fliter image
    func preview(_ collector: C7Collector, fliter image: C7Image)
    
    /// Capture other relevant information. The child thread returns the result.
    /// - Parameters:
    ///   - collector: Collector
    ///   - pixelBuffer: A CVPixelBuffer object containing the video frame data and additional information about the frame, such as its format and presentation time.
    @objc optional func captureOutput(_ collector: C7Collector, pixelBuffer: CVPixelBuffer)
    
    /// Capture CVPixelBuffer converted to MTLTexture.
    /// - Parameters:
    ///   - collector: Collector
    ///   - texture: CVPixelBuffer => MTLTexture
    @objc optional func captureOutput(_ collector: C7Collector, texture: MTLTexture)
}

@MainActor
public class C7Collector: NSObject {
    public var filters: [C7FilterProtocol] = []
    public var videoSettings: [String : Sendable] = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    /// Whether to enable automatic direction correction of pictures? The default is true.
    public var autoCorrectDirection: Bool = true
    
    weak var delegate: C7CollectorImageDelegate?
    
    public required init(delegate: C7CollectorImageDelegate) {
        self.delegate = delegate
        super.init()
        setupInit()
    }
    
    deinit {
//        delegate = nil
//        deferTextureCache()
        PTNSLogConsole("C7Collector is deinit.",levelType: PTLogMode,loggerType: .viewCycle)
    }
    
    open func setupInit() {
        // English: Harbeth owns the shared texture cache and supplies it at conversion time.
        // Español: Harbeth posee la caché de texturas compartida y la proporciona al convertir.
        // 中文：共享纹理缓存由 Harbeth 持有，在转换时统一提供。
    }
}

extension C7Collector {
    
    func pixelBuffer2Image(_ pixelBuffer: CVPixelBuffer?) -> C7Image? {
        guard let pixelBuffer = pixelBuffer else {
            return nil
        }
        delegate?.captureOutput?(self, pixelBuffer: pixelBuffer)
        guard let texture = pixelBuffer.c7.toMTLTexture(textureCache: Harbeth.Device.sharedTextureCache()) else {
            return nil
        }
        let dest = HarbethIO<MTLTexture>(element: texture, filters: filters)
        guard let texture = try? dest.output() else {
            return nil
        }
        delegate?.captureOutput?(self, texture: texture)
        return texture.c7.toImage()
    }
    
    func processing(with pixelBuffer: CVPixelBuffer?) {
        guard let pixelBuffer = pixelBuffer else {
            return
        }
        delegate?.captureOutput?(self, pixelBuffer: pixelBuffer)
        guard let texture = pixelBuffer.c7.toMTLTexture(textureCache: Harbeth.Device.sharedTextureCache()) else {
            return
        }
        var dest = HarbethIO<MTLTexture>(element: texture, filters: filters)
        dest.transmitOutputRealTimeCommit = true
        
        dest.transmitOutput(success: { [weak self] (desTexture: MTLTexture) in
            let textureBox = PTSystemTextureBox(value: desTexture)
            guard let outputImage = desTexture.c7.toImage() else { return }
            let imageBox = PTSystemImageBox(value: outputImage)

            // 💡 修复点：一进入闭包，立刻切回主线程！
            Task { @MainActor [weak self, textureBox, imageBox] in
                guard let self = self else { return }
                
                // 现在下面的所有 self 调用都是绝对安全的了
                self.delegate?.captureOutput?(self, texture: textureBox.value)
                
                var image = imageBox.value
                
                if self.autoCorrectDirection {
                    image = image.c7.fixOrientation()
                }
                
                self.delegate?.preview(self, fliter: image)
            }
        })
    }
}
