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
import SVGAPlayer

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
    
    s = maxV == 0 ? 0 : d / minV;
    
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
public class PTHeartRateViewController: PTBaseViewController {

    public var svgaIsMute:Bool = true {
        didSet {
            self.player.isMute = svgaIsMute
        }
    }
    
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
    
    private var heartRateManager: PTHeartRateManager!
    private var inputs: [CGFloat] = []
    private var measurementStartedFlag = false
    private var timer = Timer()
    private var svgaIsPlaying:Bool = false
    
    var validFrameCounter = 0
        
    var fiter = PTFiter()
    var pulseDetector = PTPulseDetector()
    
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
    
    lazy var player : SVGAPlayerSwiftEdition = {
        let view = SVGAPlayerSwiftEdition()
        view.contentMode = .scaleAspectFit
        view.isAnimated = true
        view.exDelegate = self
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
        
        PTGCDManager.gcdAfter(time: 0.1) {
            self.initVideoCapture()
        }
        
        setupLoader()
        setupDownloader()
        setupCacheKeyGenerator()
    }
    
    private func initVideoCapture() {
        let specs = VideoSpec(fps: 30, size: CGSize(width: 300, height: 300))
        heartRateManager = PTHeartRateManager(cameraType: .back, preferredSpec: specs, previewContainer: previewLayer.layer)
        heartRateManager.imageBufferHandler = { [unowned self] (imageBuffer) in
            self.handle(buffer: imageBuffer)
        }
    }
    
    private func initCaptureSession() {
        heartRateManager.startCapture()
    }

    private func deinitCaptureSession() {
        heartRateManager.stopCapture()
        toggleTorch(status: false)
        player.stop()
    }

    private func toggleTorch(status: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        device.toggleTorch(on: status)
    }

    private func startMeasurement() {
        PTGCDManager.gcdMain {
            self.toggleTorch(status: true)
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
                guard let self = self else { return }
                let average = self.pulseDetector.getAverage()
                let pulse = 60.0/average
                if pulse == -60 {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.pulseRate.alpha = 0
                    }) { (finished) in
                        self.pulseRate.isHidden = finished
                    }
                } else {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.pulseRate.alpha = 1.0
                    }) { (_) in
                        self.pulseRate.isHidden = false
                        self.pulseRate.text = "\(lroundf(pulse)) BPM"
                    }
                }
            })
        }
    }    
}

extension PTHeartRateViewController {
    fileprivate func handle(buffer: CMSampleBuffer) {
        var redmean:CGFloat = 0.0;
        var greenmean:CGFloat = 0.0;
        var bluemean:CGFloat = 0.0;
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(buffer)
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)

        let extent = cameraImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        let averageFilter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: cameraImage, kCIInputExtentKey: inputExtent])!
        let outputImage = averageFilter.outputImage!

        let ctx = CIContext(options:nil)
        let cgImage = ctx.createCGImage(outputImage, from:outputImage.extent)!
        
        let rawData:NSData = cgImage.dataProvider!.data!
        let pixels = rawData.bytes.assumingMemoryBound(to: UInt8.self)
        let bytes = UnsafeBufferPointer<UInt8>(start:pixels, count:rawData.length)
        var BGRA_index = 0
        for pixel in UnsafeBufferPointer(start: bytes.baseAddress, count: bytes.count) {
            switch BGRA_index {
            case 0:
                bluemean = CGFloat (pixel)
            case 1:
                greenmean = CGFloat (pixel)
            case 2:
                redmean = CGFloat (pixel)
            case 3:
                break
            default:
                break
            }
            BGRA_index += 1
        }
        
        let hsv = rgb2hsv((red: redmean, green: greenmean, blue: bluemean, alpha: 1.0))
        if (hsv.1 > 0.5 && hsv.2 > 0.5) {
            PTGCDManager.gcdMain {
                self.validFrames.text = "正在获取,请耐心等待,请不要把手指移开！"
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
                let _ = self.pulseDetector.addNewValue(filtered, atTime: CACurrentMediaTime())
            }
            PTNSLogConsole("我在了")
            if self.svgaIsPlaying {
                return
            } else {
                self.svgaIsPlaying = true
                self.player.play("https://public.ch.files.1drv.com/y4mQbrpflOUYev_mJ-phJV5xd_TRumdYFfyuvnnF1yzGT2Glaoj3eVrbFRIpwDCNIINHlOk0CL32gqjbn60VSL-x8ZadxJyW8oYw1i7v5Wzcxj1eIf-XdQ7x3gUOBC9zobtLqsbsH4mvzC9onR-bfdCdxytUmVkQWGZHrEbCbEuXoAGcpRVrUCCtRMfYBKujcYoRn_uVO7C6fevUr_yztKDUvQHlCqOBGugM6m-SI57FcI?AVOverride=1")
            }
        } else {
            PTNSLogConsole("我要离开了")
            validFrameCounter = 0
            measurementStartedFlag = false
            pulseDetector.reset()
            PTGCDManager.gcdMain() {
                self.validFrames.text = "请将手指放在闪光灯在位置"
                self.player.stop()
                self.svgaIsPlaying = false
            }
        }
    }
}

// MARK: - <SVGAPlayerSwiftEditionDelegate>
extension PTHeartRateViewController: SVGAPlayerSwiftEditionDelegate {
    /// 状态发生改变【状态更新】
    public func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      statusDidChanged status: SVGAPlayerSwiftEditionStatus,
                      oldStatus: SVGAPlayerSwiftEditionStatus) {
        switch status {
        case .loading:
            PTNSLogConsole("Loading")
        default:
            PTNSLogConsole("Done")
        }
    }
    
    /// SVGA未知来源【无法播放】
    public func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      unknownSvga source: String) {
        PTNSLogConsole("SVGA未知来源")
    }
    
    /// SVGA资源加载失败【无法播放】
    public func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      dataLoadFailed error: Error) {
        PTNSLogConsole(error.localizedDescription)
    }
    
    /// 加载的SVGA资源解析失败【无法播放】
    public func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      dataParseFailed error: Error) {
        PTNSLogConsole(error.localizedDescription)
    }
    
    /// 本地SVGA资源解析失败【无法播放】
    public func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      assetParseFailed error: Error) {
        PTNSLogConsole(error.localizedDescription)
    }
    
    /// SVGA资源无效【无法播放】
    public func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      entity: SVGAVideoEntity,
                      invalid error: SVGAVideoEntityError) {
        let status: String
        switch error {
        case .zeroVideoSize: status = "SVGA资源有问题：videoSize是0！"
        case .zeroFPS: status = "SVGA资源有问题：FPS是0！"
        case .zeroFrames: status = "SVGA资源有问题：frames是0！"
        default: return
        }
        PTNSLogConsole(status)
    }
    
    /// SVGA动画执行回调【正在播放】
    public func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      animationPlaying currentFrame: Int) {
        guard player.isPlaying else { return }
    }
    
    /// SVGA动画完成一次播放【正在播放】
    public func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition, svga source: String, animationDidFinishedOnce loopCount: Int) {
        PTNSLogConsole("完成第\(loopCount)次")
    }
    
    /// SVGA动画播放失败的回调【播放失败】
    public func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      animationPlayFailed error: SVGAPlayerPlayEditionError) {
        let status: String
        switch error {
        case .nullEntity: status = "SVGA资源是空的，无法播放"
        case .nullSuperview: status = "父视图是空的，无法播放"
        case .onlyOnePlayableFrame: status = "只有一帧可播放帧，无法形成动画"
        default: return
        }
        PTNSLogConsole(status)
    }
}

// MARK: - Setup SVGA Loader & Downloader & CacheKeyGenerator
private extension PTHeartRateViewController {
    func setupLoader() {
        SVGAPlayerSwiftEdition.loader = { svgaSource, success, failure, forwardDownload, forwardLoadAsset in
            guard FileManager.default.fileExists(atPath: svgaSource) else {
                if svgaSource.hasPrefix("http://") || svgaSource.hasPrefix("https://") {
                    forwardDownload(svgaSource)
                } else {
                    forwardLoadAsset(svgaSource)
                }
                return
            }
            
            PTNSLogConsole("加载磁盘的SVGA - \(svgaSource)")
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: svgaSource))
                success(data)
            } catch {
                failure(error)
            }
        }
    }
    
    func setupDownloader() {
        SVGAPlayerSwiftEdition.downloader = { svgaSource, success, failure in
            let _ = PTFileDownloadApi.init(fileUrl: svgaSource, saveFilePath: FileManager.pt.CachesDirectory() + "/heartrate.svga", progress: nil, success: { result in
                success(result.value!)
            }, fail: { error in
                failure(error!)
            })
        }
    }
    
    func setupCacheKeyGenerator() {
        SVGAPlayerSwiftEdition.cacheKeyGenerator = { $0.md5 }
    }
}
