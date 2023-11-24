//
//  PTHeartRateViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import SwifterSwift
import SnapKit

@objc public enum PTHeartRateState:Int {
    case paused
    case sampling
}

class PTHeartRateViewController: PTBaseViewController {

    var validFrameCounter = 0
    var showText:Bool = false
    
    var currentState:PTHeartRateState = .paused
    
    var fiter = PTFiter()
    var pulseDetector = PTPulseDetector()
    
    lazy var session : AVCaptureSession = {
        let cSession = AVCaptureSession()
        return cSession
    }()
    
    lazy var camera:AVCaptureDevice = {
        let avDevice = AVCaptureDevice.default(for: .video)
        
        if avDevice!.hasTorch {
            do {
                try avDevice?.lockForConfiguration()
                avDevice!.torchMode = .on
                // 检查并设置帧速率范围
                if let videoSupportedFrameRateRanges = avDevice!.activeFormat.videoSupportedFrameRateRanges.first {
                    let _ = videoSupportedFrameRateRanges.minFrameRate
                    let _ = videoSupportedFrameRateRanges.maxFrameRate
                    
                    // 设置最小帧速率
                    avDevice!.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 10)
                    
                    // 设置最大帧速率
//                    captureDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(desiredFPS))
                }
                avDevice!.unlockForConfiguration()
            } catch {
                PTNSLogConsole(error.localizedDescription)
            }
        }
        return avDevice!
    }()
    
    lazy var videoDataOutput : AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        let pixelFormatType = NSNumber(value: kCVPixelFormatType_32BGRA)
        let pixelBufferAttributes: [AnyHashable: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: pixelFormatType
        ]
        
        output.videoSettings = (NSDictionary(dictionary: pixelBufferAttributes) as! [String : Any])
        return output
    }()

    lazy var pulseRate : UILabel = {
        let view = UILabel()
        view.backgroundColor = .lightGray
        view.textColor = .systemRed
        return view
    }()
    
    lazy var validFrames : UILabel = {
        let view = UILabel()
        view.backgroundColor = .black
        view.textColor = .white
        view.font = .boldSystemFont(ofSize: 20)
        return view
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pause()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.addSubviews([pulseRate,validFrames])
        pulseRate.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
            make.left.right.equalToSuperview()
            make.height.equalTo(200)
        }
        
        validFrames.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(100)
            make.top.equalTo(self.pulseRate.snp.bottom)
        }
        
        startCameraCapture()
    }
    
    func startCameraCapture() {
        do {
            let deviceInput = try AVCaptureDeviceInput.init(device: camera)
            session.sessionPreset = .low
            session.addOutput(videoDataOutput)
            session.addInput(deviceInput)
            session.startRunning()
            currentState = .sampling
            
            UIApplication.shared.isIdleTimerDisabled = true
            
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                let distance = min(100, (100 * self.validFrameCounter) / 10)
                
                if distance == 100 {
                    self.showText = false
                }
                
                self.validFrames.text = "手指距离闪光灯距离: \(distance)"
                
                if self.currentState == .paused {
                    return
                }
                
                let avePeriod = self.pulseDetector.getAverage()
                if avePeriod == INVALID_PULSE_PERIOD {
                    
                } else {
                    self.showText = true
                    let pulse = 60 / avePeriod
                    
                    PTGCDManager.gcdMain {
                        self.pulseRate.font = .boldSystemFont(ofSize: 60)
                        self.pulseRate.text = "\(pulse)"
                    }
                }
            }
        } catch {
            PTNSLogConsole(error.localizedDescription)
        }
    }
    
    //MARK: RGB转HSV算法
    func RGBtoHSV(_ r: Float, _ g: Float, _ b: Float, _ h: inout Float, _ s: inout Float, _ v: inout Float) {
        let minVal = min(r, min(g, b))
        let maxVal = max(r, max(g, b))
        v = maxVal
        let delta = maxVal - minVal
        
        if maxVal != 0 {
            s = delta / maxVal
        } else {
            // r = g = b = 0
            s = 0
            h = -1
            return
        }
        
        if r == maxVal {
            h = (g - b) / delta
        } else if g == maxVal {
            h = 2 + (b - r) / delta
        } else {
            h = 4 + (r - g) / delta
        }
        
        h *= 60
        
        if h < 0 {
            h += 360
        }
    }
    
    func resume() {
        if currentState != .paused {
            return
        }
        
        if camera.hasTorch {
            do {
                try camera.lockForConfiguration()
                camera.torchMode = .on
                if let videoSupportedFrameRateRanges = camera.activeFormat.videoSupportedFrameRateRanges.first {
                    let _ = videoSupportedFrameRateRanges.minFrameRate
                    let _ = videoSupportedFrameRateRanges.maxFrameRate
                    
                    // 设置最小帧速率
                    camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 10)
                    
                    // 设置最大帧速率
//                    captureDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(desiredFPS))
                }
                camera.unlockForConfiguration()
            } catch {
                PTNSLogConsole(error.localizedDescription)
            }
        }

        currentState = .sampling
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func pause() {
        if currentState == .paused {
            return
        }
        
        if camera.hasTorch {
            do {
                try camera.lockForConfiguration()
                camera.torchMode = .off
                camera.unlockForConfiguration()
            } catch {
                PTNSLogConsole(error.localizedDescription)
            }
        }

        currentState = .paused
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func stopCameraCapture() {
        session.stopRunning()
    }
}

extension PTHeartRateViewController:AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if currentState == .paused {
            validFrameCounter = 0
            return
        }
        
        if validFrameCounter == 0 {
            PTGCDManager.gcdMain {
                self.pulseRate.font = .boldSystemFont(ofSize: 23)
                self.pulseRate.text = "请将手指放在闪光灯在位置"                
            }
        } else {
            if !self.showText {
                PTGCDManager.gcdMain {
                    self.pulseRate.font = .boldSystemFont(ofSize: 20)
                    self.pulseRate.text = "正在获取,请耐心等待,请不要把手指移开！"
                    
                    if self.camera.hasTorch {
                        do {
                            try self.camera.lockForConfiguration()
                            self.camera.torchMode = .on
                            // 检查并设置帧速率范围
                            if let videoSupportedFrameRateRanges = self.camera.activeFormat.videoSupportedFrameRateRanges.first {
                                let _ = videoSupportedFrameRateRanges.minFrameRate
                                let _ = videoSupportedFrameRateRanges.maxFrameRate
                                
                                // 设置最小帧速率
                                self.camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 10)
                                
                                // 设置最大帧速率
            //                    captureDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(desiredFPS))
                            }
                            self.camera.unlockForConfiguration()
                        } catch {
                            PTNSLogConsole(error.localizedDescription)
                        }
                    }
                }
            }
        }
        
        // 获取图像缓冲区
        guard let cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // 锁定图像缓冲区
        CVPixelBufferLockBaseAddress(cvimgRef, CVPixelBufferLockFlags(rawValue: 0))

        // 访问数据
        let width = CVPixelBufferGetWidth(cvimgRef)
        let height = CVPixelBufferGetHeight(cvimgRef)
        let buf = unsafeBitCast(CVPixelBufferGetBaseAddress(cvimgRef), to: UnsafeMutablePointer<UInt8>.self)
        let bprow = CVPixelBufferGetBytesPerRow(cvimgRef)

        // 平均帧的 RGB 值
        var r: Float = 0, g: Float = 0, b: Float = 0
        for y in 0..<height {
            var pixel = buf + y * bprow
            for _ in 0..<width {
                b += Float(pixel[0])
                g += Float(pixel[1])
                r += Float(pixel[2])
                pixel += 4
            }
        }

        r /= 255 * Float(width * height)
        g /= 255 * Float(width * height)
        b /= 255 * Float(width * height)

        // 从 RGB 转换到 HSV 颜色空间
        var h: Float = 0, s: Float = 0, v: Float = 0
        
        RGBtoHSV(r, g, b, &h, &s, &v)
        
        if s > 0.5 && v > 0.5 {
            validFrameCounter += 1
            
            let filtered = self.fiter.processValue(h)
            
            if validFrameCounter > 10 {
                let _ = self.pulseDetector.addNewValue(filtered, atTime: CACurrentMediaTime())
            }
        } else {
            validFrameCounter = 0
            
            self.pulseDetector.reset()
        }
    }
}
