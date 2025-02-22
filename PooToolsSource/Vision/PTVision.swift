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

public class PTVision: NSObject {
    public static let share = PTVision()

    public static func funcQRCode(withImage image:UIImage,
                                  type:VNBarcodeSymbology = .qr,
                                  callback:@escaping (String)->Void) {
        guard let ciImage = CIImage(image: image) else {
            PTNSLogConsole("Failed to convert UIImage to CIImage")
            callback("")
            return
        }
        
        // 创建条形码识别请求
        let barcodeRequest = VNDetectBarcodesRequest { request, error in
            guard let results = request.results as? [VNBarcodeObservation] else {
                PTNSLogConsole("No barcodes detected")
                callback("")
                return
            }

            for barcode in results {
                if barcode.symbology == type {
                    PTNSLogConsole("Detected barcode: \(barcode.payloadStringValue ?? "Unknown")")
                    callback(barcode.payloadStringValue ?? "Unknown")
                }
            }
        }

        // 创建图像请求处理器
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        // 执行请求
        do {
            try requestHandler.perform([barcodeRequest])
        } catch {
            PTNSLogConsole("Failed to perform barcode detection request: \(error)")
            callback("")
        }
    }
    
    //MARK: OCR查找文字方法(UIImage)
    ///OCR查找文字方法(UIImage)
    /// - Parameters:
    ///   - image: 图片
    ///   - revision: Vision版本(VNRecognizeTextRequestRevision2 iOS14,VNRecognizeTextRequestRevision3 iOS16)
    ///   - recognitionLanguages: 識別語言(默認中,英,西)
    ///   - resultBlock: 回调
    public static func findText(withImage image:UIImage,
                                revision:Int = VNRecognizeTextRequestRevision2,
                                recognitionLanguages:[String] = ["zh-cn","zh-Hant","zh-Hans","en","es"]) async throws -> (String,[VNRecognizedTextObservation]) {
        try await withCheckedThrowingContinuation { continuation in
            PTVision.share.findText(withImage: image, revision: revision, recognitionLanguages: recognitionLanguages) { resultText, textObservations in
                continuation.resume(returning: (resultText, textObservations))
            }
        }
    }
    
    public func findText(withImage image:UIImage,
                         revision:Int = VNRecognizeTextRequestRevision2,
                         recognitionLanguages:[String] = ["zh-cn","zh-Hant","zh-Hans","en","es"],
                         resultBlock:((_ resultText:String,_ textObservations:[VNRecognizedTextObservation])->Void)?) {
        PTGCDManager.gcdGobal {
            let textDetectionRequest = VNRecognizeTextRequest { request, error in
                if let error = error {
                    PTNSLogConsole(error.localizedDescription, levelType: .Error, loggerType: .Vision)
                } else {
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        PTNSLogConsole("No results found", levelType: .Error, loggerType: .Vision)
                        return
                    }

                    var resultText = ""
                    let maximumCandidates = 1
                    for observation in observations {
                        let candidates = observation.topCandidates(maximumCandidates)
                        resultText += candidates.map { $0.string }.joined(separator: "\n")
                    }

                    PTGCDManager.gcdMain {
                        PTNSLogConsole(resultText, levelType: PTLogMode, loggerType: .Vision)
                        resultBlock?(resultText, observations)
                    }
                }
            }

            textDetectionRequest.recognitionLanguages = recognitionLanguages
            textDetectionRequest.recognitionLevel = .accurate
            textDetectionRequest.revision = revision

            PTGCDManager.gcdMain {
                guard let cgImage = image.cgImage else {
                    PTNSLogConsole("Invalid image for OCR detection", levelType: .Error, loggerType: .Vision)
                    return
                }

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([textDetectionRequest])
                } catch {
                    PTNSLogConsole("Failed to perform text detection request: \(error)", levelType: .Error, loggerType: .Vision)
                }
            }
        }
    }
    
    //MARK: OCR查找文字方法(UIImageView)
    ///OCR查找文字方法(UIImageView)
    /// - Parameters:
    ///   - image: 图片
    ///   - revision: Vision版本(VNRecognizeTextRequestRevision2 iOS14,VNRecognizeTextRequestRevision3 iOS16)
    ///   - recognitionLanguages: 支持語言
    ///   - resultBlock: 回调
    public static func findText(withImageView image:UIImageView,
                                revision:Int = VNRecognizeTextRequestRevision2,
                                recognitionLanguages:[String] = ["zh-cn","zh-Hant","zh-Hans","en","es"]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            PTVision.share.findText(withImageView: image, revision: revision) { resultText in
                continuation.resume(returning: resultText)
            }
        }
    }
    
    public func findText(withImageView imageView:UIImageView,
                         revision:Int = VNRecognizeTextRequestRevision2,
                         resultBlock:((_ resultText:String)->Void)?) {
        imageView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        guard let image = imageView.image else {
            PTNSLogConsole("ImageView does not contain an image", levelType: .Error, loggerType: .Vision)
            return
        }

        findText(withImage: image, revision: revision) { resultText, textObservations in
            resultBlock?(resultText)

            let textLayers = self.addShapeToText(observations: textObservations, textImageView: imageView)
            textLayers.forEach { imageView.layer.addSublayer($0) }
        }
    }
    
    private func addShapeToText(observations:[VNRecognizedTextObservation],textImageView:UIImageView) -> [CAShapeLayer] {
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
            layer.borderColor = UIColor.random.cgColor
            layer.borderWidth = 1
            layer.cornerRadius = 2
            return layer
        }
    }
}
