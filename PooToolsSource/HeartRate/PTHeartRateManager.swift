//
//  PTHeartRateManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
@preconcurrency import AVFoundation

// English: Report camera setup failures instead of terminating the host application.
// Español: Informa los errores de configuración de la cámara en lugar de terminar la aplicación anfitriona.
// 中文：报告相机配置失败，不再让宿主应用直接闪退。
public enum PTHeartRateError: Error, LocalizedError, Sendable, Equatable {
    case simulator
    case cameraUnavailable
    case inputCreationFailed
    case inputNotSupported
    case outputNotSupported

    public var errorDescription: String? {
        switch self {
        case .simulator: return "模拟器不支持心率相机采集"
        case .cameraUnavailable: return "当前设备没有可用相机"
        case .inputCreationFailed: return "无法创建相机输入"
        case .inputNotSupported: return "相机输入无法加入采集会话"
        case .outputNotSupported: return "视频输出无法加入采集会话"
        }
    }
}

public enum CameraType: Int {
    case back
    case front
    
    public func captureDevice() -> AVCaptureDevice? {
        switch self {
        case .front:
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [], mediaType: AVMediaType.video, position: .front).devices
            for device in devices where device.position == .front {
                return device
            }
        default:
            break
        }
        
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }
}

public typealias ImageBufferHandler = (_ imageBuffer: CMSampleBuffer) -> ()

public class PTHeartRateManager: NSObject {
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.pootools.heartrate.capture", qos: .userInitiated)
    private var videoDevice: AVCaptureDevice?
    private var videoConnection: AVCaptureConnection?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    public private(set) var configurationError: PTHeartRateError?
    public var isAvailable: Bool { configurationError == nil && !deviceInfo.isSimulator }

    public var imageBufferHandler: ImageBufferHandler?
    
    public init(cameraType: CameraType, preferredSpec: VideoSpec?, previewContainer: CALayer?) {
        super.init()
        
        guard !deviceInfo.isSimulator else {
            configurationError = .simulator
            return
        }
        guard let videoDevice = cameraType.captureDevice() else {
            configurationError = .cameraUnavailable
            return
        }
        self.videoDevice = videoDevice

        // English: Configure the capture graph only when each required resource is available.
        // Español: Configura el grafo de captura solo cuando cada recurso requerido está disponible.
        // 中文：只有所有必需资源都可用时才配置采集图。
        captureSession.sessionPreset = .low
        if let preferredSpec {
            videoDevice.updateFormatWithPreferredVideoSpec(preferredSpec: preferredSpec)
        }

        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            configurationError = .inputCreationFailed
            return
        }
        guard captureSession.canAddInput(videoDeviceInput) else {
            configurationError = .inputNotSupported
            return
        }
        captureSession.addInput(videoDeviceInput)
            
            // MARK: - Setup preview layer
            if let previewContainer = previewContainer {
                let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.frame = previewContainer.bounds
                previewLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                previewContainer.insertSublayer(previewLayer, at: 0)
                self.previewLayer = previewLayer
            }
            
            // MARK: - Setup video output
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        let queue = DispatchQueue(label: "com.pootools.heartrate.sample-buffer", qos: .userInitiated)
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
        guard captureSession.canAddOutput(videoDataOutput) else {
            configurationError = .outputNotSupported
            return
        }
        captureSession.addOutput(videoDataOutput)
        videoConnection = videoDataOutput.connection(with: .video)
    }
    
    public func startCapture() {
#if POOTOOLS_DEBUG
        PTNSLogConsole(#function + "\(classForCoder)/",levelType: PTLogMode,loggerType: .health)
#endif
        let session = captureSession
        let available = isAvailable
        sessionQueue.async { [session, available] in
            guard available, !session.isRunning else { return }
            session.startRunning()
        }
    }
    
    public func stopCapture() {
#if POOTOOLS_DEBUG
        PTNSLogConsole("\(classForCoder)/",levelType: PTLogMode,loggerType: .health)
#endif
        let session = captureSession
        sessionQueue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }
}

extension PTHeartRateManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: - Export buffer from video frame
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.isVideoRotationAngleSupported(90.0), connection.videoRotationAngle != 90.0 {
            connection.videoRotationAngle = 90.0
            // 角度不对时，纠正角度并主动丢弃这一帧（直接 return）
            return
        }
        if let imageBufferHandler = imageBufferHandler {
            imageBufferHandler(sampleBuffer)
        }
    }
}
