//
//  PTVision.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Vision
import VisionKit

// 1. 标记为 final 和 Sendable，向 Swift 6 证明这个单例是跨线程安全的
public final class PTVision: NSObject, @unchecked Sendable {
    
    public static let share = PTVision()
    
    // 私有化初始化方法，确保单例的纯粹性
    private override init() {
        super.init()
    }

    // MARK: - 识别二维码
    // 为跨线程回调添加 @Sendable 标记
    public static func funcQRCode(withImage image: UIImage,
                                  type: VNBarcodeSymbology = .qr,
                                  callback: @escaping @Sendable (String) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            PTNSLogConsole("Failed to convert UIImage to CIImage")
            callback("")
            return
        }
        
        // 切换到后台任务执行识别，避免阻塞调用者的线程
        Task.detached(priority: .userInitiated) {
            let barcodeRequest = VNDetectBarcodesRequest { request, error in
                guard let results = request.results as? [VNBarcodeObservation] else {
                    PTNSLogConsole("No barcodes detected")
                    callback("")
                    return
                }

                for barcode in results {
                    if barcode.symbology == type {
                        let payload = barcode.payloadStringValue ?? "Unknown"
                        PTNSLogConsole("Detected barcode: \(payload)")
                        callback(payload)
                        return // 找到后直接返回，避免多次回调
                    }
                }
                callback("") // 如果遍历完没有匹配的类型，也返回空
            }

            let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])

            do {
                try requestHandler.perform([barcodeRequest])
            } catch {
                PTNSLogConsole("Failed to perform barcode detection request: \(error)")
                callback("")
            }
        }
    }
    
    // MARK: - OCR查找文字方法(UIImage) (Async/Await)
    public static func findText(withImage image: UIImage,
                                revision: Int = VNRecognizeTextRequestRevision2,
                                recognitionLanguages: [String] = ["zh-cn","zh-Hant","zh-Hans","en","es"]) async throws -> (String, [VNRecognizedTextObservation]) {
        
        try await withCheckedThrowingContinuation { continuation in
            PTVision.share.findText(withImage: image, revision: revision, recognitionLanguages: recognitionLanguages) { resultText, textObservations in
                continuation.resume(returning: (resultText, textObservations))
            }
        }
    }
    
    // MARK: - OCR查找文字方法(UIImage) (Closure)
    public func findText(withImage image: UIImage,
                         revision: Int = VNRecognizeTextRequestRevision2,
                         recognitionLanguages: [String] = ["zh-cn","zh-Hant","zh-Hans","en","es"],
                         resultBlock: (@Sendable (_ resultText: String, _ textObservations: [VNRecognizedTextObservation]) -> Void)?) {
        
        // 提前在当前线程获取 CGImage，避免在后台访问带有 UI 状态的 UIImage 可能引发的隐患
        guard let cgImage = image.cgImage else {
            PTNSLogConsole("Invalid image for OCR detection", levelType: .error, loggerType: .vision)
            return
        }
        
        // 2. 修复原代码中的阻塞 Bug：使用 Task.detached 将沉重的 OCR 计算推入后台
        Task.detached(priority: .userInitiated) {
            let textDetectionRequest = VNRecognizeTextRequest { request, error in
                if let error = error {
                    PTNSLogConsole(error.localizedDescription, levelType: .error, loggerType: .vision)
                } else {
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        PTNSLogConsole("No results found", levelType: .error, loggerType: .vision)
                        return
                    }

                    var resultText = ""
                    let maximumCandidates = 1
                    for observation in observations {
                        let candidates = observation.topCandidates(maximumCandidates)
                        resultText += candidates.map { $0.string }.joined(separator: "\n")
                    }

                    // 3. 计算完成后，安全地切回主线程进行回调，方便外部直接更新 UI
                    Task { @MainActor in
                        PTNSLogConsole(resultText, levelType: PTLogMode, loggerType: .vision)
                        resultBlock?(resultText, observations)
                    }
                }
            }

            textDetectionRequest.recognitionLanguages = recognitionLanguages
            textDetectionRequest.recognitionLevel = .accurate
            textDetectionRequest.revision = revision

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                // 原本这里是在 gcdMain 执行的，现在已修复为在后台完美运行！
                try handler.perform([textDetectionRequest])
            } catch {
                PTNSLogConsole("Failed to perform text detection request: \(error)", levelType: .error, loggerType: .vision)
            }
        }
    }
    
    // MARK: - OCR查找文字方法(UIImageView) (Async/Await)
    // 4. 涉及 UIImageView 的 API 必须强制 @MainActor 隔离
    @MainActor
    public static func findText(withImageView image: UIImageView,
                                revision: Int = VNRecognizeTextRequestRevision2,
                                recognitionLanguages: [String] = ["zh-cn","zh-Hant","zh-Hans","en","es"]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            PTVision.share.findText(withImageView: image, revision: revision) { resultText in
                continuation.resume(returning: resultText)
            }
        }
    }
    
    // MARK: - OCR查找文字方法(UIImageView) (Closure)
    @MainActor
    public func findText(withImageView imageView: UIImageView,
                         revision: Int = VNRecognizeTextRequestRevision2,
                         resultBlock: (@Sendable (_ resultText: String) -> Void)?) {
        
        imageView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        guard let image = imageView.image else {
            PTNSLogConsole("ImageView does not contain an image", levelType: .error, loggerType: .vision)
            return
        }

        // 调用刚才写好的后台安全查找方法
        findText(withImage: image, revision: revision) { [weak self, weak imageView] resultText, textObservations in
            resultBlock?(resultText)
            
            // 确保在主线程为图片添加高亮框
            Task { @MainActor [weak self, weak imageView] in
                guard let self = self, let imgView = imageView else { return }
                let textLayers = self.addShapeToText(observations: textObservations, textImageView: imgView)
                textLayers.forEach { imgView.layer.addSublayer($0) }
            }
        }
    }
    
    // 辅助 UI 绘制的方法，标记为 @MainActor
    @MainActor
    private func addShapeToText(observations: [VNRecognizedTextObservation], textImageView: UIImageView) -> [CAShapeLayer] {
        return observations.map { observation in
            let bounds = observation.boundingBox
            let layerFrame = CGRect(
                x: bounds.origin.x * textImageView.bounds.width,
                y: (1 - bounds.origin.y) * textImageView.bounds.height - bounds.height * textImageView.bounds.height,
                width: bounds.width * textImageView.bounds.width,
                height: bounds.height * textImageView.bounds.height
            )

            let layer = CAShapeLayer()
            layer.frame = layerFrame
            // 假设 UIColor.random 是你库里的一个分类扩展，这里直接使用
            layer.borderColor = UIColor.random.cgColor
            layer.borderWidth = 1
            layer.cornerRadius = 2
            return layer
        }
    }
}
