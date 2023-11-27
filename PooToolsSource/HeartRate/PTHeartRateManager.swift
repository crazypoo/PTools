//
//  PTHeartRateManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import DeviceKit

public enum CameraType: Int {
    case back
    case front
    
    public func captureDevice() -> AVCaptureDevice {
        switch self {
        case .front:
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [], mediaType: AVMediaType.video, position: .front).devices
            PTNSLogConsole("devices:\(devices)")
            for device in devices where device.position == .front {
                return device
            }
        default:
            break
        }
        
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
    }
}

public typealias ImageBufferHandler = (_ imageBuffer: CMSampleBuffer) -> ()

public class PTHeartRateManager: NSObject {
    private let captureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice!
    private var videoConnection: AVCaptureConnection!
    private var audioConnection: AVCaptureConnection!
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    public var imageBufferHandler: ImageBufferHandler?
    
    public init(cameraType: CameraType, preferredSpec: VideoSpec?, previewContainer: CALayer?) {
        super.init()
        
        if !Gobal_device_info.isSimulator {
            videoDevice = cameraType.captureDevice()
            
            // MARK: - Setup Video Format
            do {
                captureSession.sessionPreset = .low
                if let preferredSpec = preferredSpec {
                    // Update the format with a preferred fps
                    videoDevice.updateFormatWithPreferredVideoSpec(preferredSpec: preferredSpec)
                }
            }
            
            // MARK: - Setup video device input
            let videoDeviceInput: AVCaptureDeviceInput
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch let error {
                fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
            }
            guard captureSession.canAddInput(videoDeviceInput) else { fatalError() }
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
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            let queue = DispatchQueue(label: "com.covidsense.videosamplequeue")
            videoDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard captureSession.canAddOutput(videoDataOutput) else {
                fatalError()
            }
            captureSession.addOutput(videoDataOutput)
            videoConnection = videoDataOutput.connection(with: .video)
        }
    }
    
    public func startCapture() {
#if POOTOOLS_DEBUG
        PTNSLogConsole(#function + "\(classForCoder)/")
#endif
        if captureSession.isRunning {
#if POOTOOLS_DEBUG
            PTNSLogConsole("Capture Session is already running 🏃‍♂️.")
#endif
            return
        }
        captureSession.startRunning()
    }
    
    public func stopCapture() {
#if POOTOOLS_DEBUG
        PTNSLogConsole("\(classForCoder)/")
#endif
        if !captureSession.isRunning {
#if POOTOOLS_DEBUG
            PTNSLogConsole("Capture Session has already stopped 🛑.")
#endif
            return
        }
        captureSession.stopRunning()
    }
}

extension PTHeartRateManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: - Export buffer from video frame
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
            return
        }
        if let imageBufferHandler = imageBufferHandler {
            imageBufferHandler(sampleBuffer)
        }
    }
}
