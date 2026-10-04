//
//  PTHeartRateViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit
import Lottie

// English: CMSampleBuffer is a system-owned frame passed through one narrow compatibility box.
// Español: CMSampleBuffer es un fotograma del sistema que cruza un único adaptador de compatibilidad.
// 中文：CMSampleBuffer 是系统拥有的帧，只通过一个窄范围兼容包装器跨越并发边界。
private struct PTHeartRateSampleBufferBox: @unchecked Sendable {
    let value: CMSampleBuffer
}

public typealias RGB = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
public typealias HSV = (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat)

public func hsv2rgb(_ hsv: HSV) -> RGB {
    var rgb: RGB = (red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    
    let i = Int(hsv.hue * 6)
    let f = hsv.hue * 6 - CGFloat(i)
    let p = hsv.brightness * (1 - hsv.saturation)
    let q = hsv.brightness * (1 - f * hsv.saturation)
    let t = hsv.brightness * (1 - (1 - f) * hsv.saturation)
    switch (i % 6) {
    case 0: r = hsv.brightness; g = t; b = p; break;
        
    case 1: r = q; g = hsv.brightness; b = p; break;
        
    case 2: r = p; g = hsv.brightness; b = t; break;
        
    case 3: r = p; g = q; b = hsv.brightness; break;
        
    case 4: r = t; g = p; b = hsv.brightness; break;
        
    case 5: r = hsv.brightness; g = p; b = q; break;
        
    default: r = hsv.brightness; g = t; b = p;
    }
    
    rgb.red = r
    rgb.green = g
    rgb.blue = b
    rgb.alpha = hsv.alpha
    return rgb
}

public func rgb2hsv(_ rgb: RGB) -> HSV {
    // Converts RGB to a HSV color
    var hsb: HSV = (hue: 0.0, saturation: 0.0, brightness: 0.0, alpha: 0.0)
    
    let rd: CGFloat = rgb.red
    let gd: CGFloat = rgb.green
    let bd: CGFloat = rgb.blue
    
    let maxV: CGFloat = max(rd, max(gd, bd))
    let minV: CGFloat = min(rd, min(gd, bd))
    var h: CGFloat = 0
    var s: CGFloat = 0
    let b: CGFloat = maxV
    
    let d: CGFloat = maxV - minV
    
    s = maxV == 0 ? 0 : d / maxV
    
    if (maxV == minV) {
        h = 0
    } else {
        if (maxV == rd) {
            h = (gd - bd) / d + (gd < bd ? 6 : 0)
        } else if (maxV == gd) {
            h = (bd - rd) / d + 2
        } else if (maxV == bd) {
            h = (rd - gd) / d + 4
        }
        
        h /= 6;
    }
    
    hsb.hue = h
    hsb.saturation = s
    hsb.brightness = b
    hsb.alpha = rgb.alpha
    return hsb
}

@objcMembers
@MainActor
public class PTHeartRateViewController: PTBaseViewController {

    public let sessionQueue = DispatchQueue(label: "camera.session.collector.metal")

    lazy var previewLayerShadowView : UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addShadow(ofColor: .black, radius: 3, offset: CGSizeMake(0, 3), opacity: 0.25)
        return view
    }()
    
    lazy var previewLayer : UIView = {
        let view = UIView()
        view.viewCorner(radius: 12, borderWidth: 0, borderColor: .clear)
        return view
    }()
    
    private var heartRateManager: PTHeartRateManager?
    private var inputs: [CGFloat] = []
    private var measurementStartedFlag = false
    private var timer: Timer?
    private var svgaIsPlaying:Bool = false
    
    var validFrameCounter = 0
        
    var fiter = PTFiter()
    var pulseDetector = PTPulseDetector()
    private let ciContext = CIContext(options: nil)
    
    lazy var pulseRate : UILabel = {
        let view = UILabel()
        view.textColor = .systemRed
        view.textAlignment = .center
        view.font = .boldSystemFont(ofSize: 34)
        return view
    }()
    
    lazy var validFrames : UILabel = {
        let view = UILabel()
        view.backgroundColor = .black
        view.textColor = .white
        view.font = .boldSystemFont(ofSize: 20)
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()
    
    lazy var player : LottieAnimationView = {
        let view: LottieAnimationView
        if let url = URL(string: "https://lottie.host/80012aeb-ac39-44e4-8ae0-20b9ba56f1bf/73xBogjj9i.lottie") {
            view = LottieAnimationView(dotLottieUrl: url)
        } else {
            view = LottieAnimationView()
        }
        view.frame = CGRectMake(0, 0, 88, 88)
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        view.animationSpeed = 1
        return view
    }()

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initCaptureSession()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deinitCaptureSession()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.addSubviews([player,previewLayerShadowView,pulseRate,validFrames])
        player.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
            make.height.equalTo(88)
        }
        
        previewLayerShadowView.snp.makeConstraints { make in
            make.size.equalTo(120)
            make.centerX.equalToSuperview()
            make.top.equalTo(player.snp.bottom).offset(10)
        }
        
        previewLayerShadowView.addSubview(previewLayer)
        previewLayer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        pulseRate.snp.makeConstraints { make in
            make.top.equalTo(self.previewLayerShadowView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(200)
        }
        
        validFrames.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.pulseRate.snp.bottom)
        }
        
        if !deviceInfo.isSimulator {
            PTGCDManager.shared.delayOnMain(time: 0.1) {
                self.initVideoCapture()
            }
        }
    }
    
    private func initVideoCapture() {
        let specs = VideoSpec(fps: 30, size: CGSize(width: 300, height: 300))
        let manager = PTHeartRateManager(cameraType: .back, preferredSpec: specs, previewContainer: previewLayer.layer)
        heartRateManager = manager
        manager.imageBufferHandler = { [weak self] imageBuffer in
            let box = PTHeartRateSampleBufferBox(value: imageBuffer)
            Task { @MainActor [weak self, box] in
                self?.handle(buffer: box.value)
            }
        }
        if let error = manager.configurationError {
            PTNSLogConsole(error.localizedDescription, levelType: .error, loggerType: .health)
        }
    }

    private func initCaptureSession() {
        heartRateManager?.startCapture()
    }

    private func deinitCaptureSession() {
        timer?.invalidate()
        timer = nil
        heartRateManager?.stopCapture()
        toggleTorch(status: false)
        player.stop()
    }

    private func toggleTorch(status: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        device.toggleTorch(on: status)
    }

    private func startMeasurement() {
        toggleTorch(status: true)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let average = self.pulseDetector.getAverage()
                let pulse = average > 0 ? 60.0 / average : -60
                if pulse == -60 {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.pulseRate.alpha = 0
                    }) { finished in
                        self.pulseRate.isHidden = finished
                    }
                } else {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.pulseRate.alpha = 1.0
                    }) { _ in
                        self.pulseRate.isHidden = false
                        self.pulseRate.text = "\(lroundf(pulse)) BPM"
                    }
                }
            }
        }
    }

}

extension PTHeartRateViewController {
    fileprivate func handle(buffer: CMSampleBuffer) {
        var redmean:CGFloat = 0.0;
        var greenmean:CGFloat = 0.0;
        var bluemean:CGFloat = 0.0;
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer)

        let extent = cameraImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        guard let averageFilter = CIFilter(name: "CIAreaAverage") else { return }
        averageFilter.setValue(cameraImage, forKey: kCIInputImageKey)
        averageFilter.setValue(inputExtent, forKey: kCIInputExtentKey)
        guard let outputImage = averageFilter.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent),
              let rawData = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(rawData),
              CFDataGetLength(rawData) >= 3 else { return }

        bluemean = CGFloat(bytes[0])
        greenmean = CGFloat(bytes[1])
        redmean = CGFloat(bytes[2])
        
        let hsv = rgb2hsv((red: redmean, green: greenmean, blue: bluemean, alpha: 1.0))
        if (hsv.1 > 0.5 && hsv.2 > 0.5) {
            Task { @MainActor in
                self.validFrames.text = "PT HeartRate loading".localized()
                self.toggleTorch(status: true)
                if !self.measurementStartedFlag {
                    self.startMeasurement()
                    self.measurementStartedFlag = true
                }
            }
            validFrameCounter += 1
            inputs.append(hsv.0)
            let filtered = fiter.processValue(Double(hsv.0))
            if validFrameCounter > 60 {
                let _ = pulseDetector.addNewValue(filtered, atTime: CACurrentMediaTime())
            }
            if svgaIsPlaying {
                return
            } else {
                svgaIsPlaying = true
                player.play()
            }
        } else {
            validFrameCounter = 0
            measurementStartedFlag = false
            pulseDetector.reset()
            Task { @MainActor in
                self.validFrames.text = "PT HeartRate touch".localized()
                self.player.stop()
                self.svgaIsPlaying = false
            }
        }
    }
}
