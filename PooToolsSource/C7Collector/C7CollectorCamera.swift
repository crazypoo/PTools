//
//  C7CollectorCamera.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation
import Harbeth

/// 相机数据采集器，在主线程返回图片
/// The camera data collector returns pictures in the main thread.
public final class C7CollectorCamera: C7Collector {
    
    private var videoUrl: URL?
    
    private lazy var cameraConfig = PTCameraFilterConfig.share
    
    public var largeCircleView: UIView!
    
    public var smallCircleView: UIView!

    public var borderLayer: CAShapeLayer!
    public var focusCursorView: UIImageView!
    public var isAdjustingFocusPoint = false

    public var recordLongGes: UILongPressGestureRecognizer?

    /// 是否正在拍照
    public var isTakingPicture = false
    private var recordUrls: [URL] = []
    private var recordDurations: [Double] = []

    private var microPhontIsAvailable = true
    public var recordVideoPlayerLayer: AVPlayerLayer?
    private var restartRecordAfterSwitchCamera = false
    
    var animateLayer: CAShapeLayer!
    
    private var orientation: AVCaptureVideoOrientation = .portrait
    private var cacheVideoOrientation: AVCaptureVideoOrientation = .portrait
    
    public let sessionQueue = DispatchQueue(label: "camera.session.collector.metal")
    private let bufferQueue  = DispatchQueue(label: "camera.collector.buffer.metal")
    
    public var deviceInput: AVCaptureDeviceInput?
    
    public var movieFileOutput: AVCaptureMovieFileOutput?
    
    public lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        return session
    }()
    
    public lazy var imageOutput: AVCapturePhotoOutput = {
        let imageOutput = AVCapturePhotoOutput()
        return imageOutput
    }()
    
    public lazy var videoOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = videoSettings
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: bufferQueue)
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        if let xx = output.connection(with: .video), xx.isVideoOrientationSupported {
            xx.videoOrientation = .portrait
        }
        return output
    }()
    
    deinit {
        self.stopRunning()
        self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
    }
    
    public override func setupInit() {
        super.setupInit()
        
        switch PTPermission.camera.status {
        case .notDetermined:
            PTPermission.camera.request {
                switch PTPermission.camera.status {
                case .authorized:
                    guard self.cameraConfig.allowRecordVideo else {
                        self.addNotification()
                        return
                    }
                default:
                    return
                }
            }
        case .authorized:
            guard self.cameraConfig.allowRecordVideo else {
                self.addNotification()
                return
            }
            
            switch PTPermission.microphone.status {
            case .notDetermined:
                PTPermission.microphone.request {
                    self.addNotification()
                    switch PTPermission.microphone.status {
                    case .authorized:break
                    default:
                        //                self.showNoMicrophoneAuthorityAlert()
                        return
                    }
                }
            case .authorized:
                self.addNotification()
            default:
                self.addNotification()
                //                self.showNoMicrophoneAuthorityAlert()
                break
            }
        default:
            //TODO: 没授权
            return
        }
        
        if cameraConfig.allowRecordVideo {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .duckOthers)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                let err = error as NSError
                if err.code == AVAudioSession.ErrorCode.insufficientPriority.rawValue ||
                    err.code == AVAudioSession.ErrorCode.isBusy.rawValue {
                    microPhontIsAvailable = false
                }
            }
        }
        
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        guard let camera = self.getCamera(position: cameraConfig.devicePosition.avDevicePosition) else { return }
        guard let input = try? AVCaptureDeviceInput(device: camera) else { return }
        captureSession.beginConfiguration()
        
        deviceInput = input
        
        refreshSessionPreset(device: camera)
        
        let movieFileOutput = AVCaptureMovieFileOutput()
        // 解决视频录制超过10s没有声音的bug
        movieFileOutput.movieFragmentInterval = .invalid
        self.movieFileOutput = movieFileOutput
        
        // 添加视频输入
        if let videoInput = self.deviceInput, self.captureSession.canAddInput(videoInput) {
            self.captureSession.addInput(videoInput)
        }
        
        // 添加音频输入
        self.addAudioInput()
        
        
        // 照片输出流
        let imageOutput = AVCapturePhotoOutput()
        self.imageOutput = imageOutput
        // 将输出流添加到session
        if self.captureSession.canAddOutput(imageOutput) {
            self.captureSession.addOutput(imageOutput)
        }
        if self.captureSession.canAddOutput(movieFileOutput) {
            self.captureSession.addOutput(movieFileOutput)
        }
        
        let _ = self.videoOutput
        captureSession.commitConfiguration()
        
        startRunning()
    }
    
    private func getMicrophone() -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified).devices.first
    }
    
    private func removeAudioInput() {
        var audioInput: AVCaptureInput?
        for input in captureSession.inputs {
            if (input as? AVCaptureDeviceInput)?.device.deviceType == .builtInMicrophone {
                audioInput = input
            }
        }
        guard let audioInput = audioInput else { return }
        
        if captureSession.isRunning {
            captureSession.beginConfiguration()
        }
        captureSession.removeInput(audioInput)
        if captureSession.isRunning {
            captureSession.commitConfiguration()
        }
    }
    
    private func addAudioInput() {
        guard cameraConfig.allowRecordVideo else { return }
        
        // 音频输入流
        var audioInput: AVCaptureDeviceInput?
        if let microphone = getMicrophone() {
            audioInput = try? AVCaptureDeviceInput(device: microphone)
        }
        
        guard microPhontIsAvailable, let ai = audioInput else { return }
        
        removeAudioInput()
        
        if captureSession.isRunning {
            captureSession.beginConfiguration()
        }
        if captureSession.canAddInput(ai) {
            captureSession.addInput(ai)
        }
        if captureSession.isRunning {
            captureSession.commitConfiguration()
        }
    }
    
    // 点击拍照
    public func takePicture(flashBtn:UIButton) {
        guard PTMediaLibManager.hasCameraAuthority(), !isTakingPicture else {
            return
        }
        
        guard captureSession.outputs.contains(videoOutput) else {
            //MARK: 相机不能用
            PTNSLogConsole("相机不能用")
            //            showAlertAndDismissAfterDoneAction(message: localLanguageTextValue(.cameraUnavailable), type: .camera)
            return
        }
        
        isTakingPicture = true
        
        let connection = imageOutput.connection(with: .video)
        connection?.videoOrientation = orientation
        if deviceInput?.device.position == .front, connection?.isVideoMirroringSupported == true {
            connection?.isVideoMirrored = true
        }
        let setting = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        if deviceInput?.device.hasFlash == true, flashBtn.isSelected {
            setting.flashMode = .on
        } else {
            setting.flashMode = .off
        }
        imageOutput.capturePhoto(with: setting, delegate: self)
    }
    
    public func changeCamera(handle:PTActionTask?) {
        
        guard !restartRecordAfterSwitchCamera else {
            return
        }
        
        guard let currInput = deviceInput,
              let movieFileOutput = movieFileOutput else {
            return
        }
        
        if movieFileOutput.isRecording {
            let pauseTime = animateLayer.convertTime(CACurrentMediaTime(), from: nil)
            animateLayer.speed = 0
            animateLayer.timeOffset = pauseTime
            restartRecordAfterSwitchCamera = true
        }
        
        sessionQueue.async {
            self.captureSession.stopRunning()
            do {
                var newVideoInput: AVCaptureDeviceInput?
                if currInput.device.position == .back, let front = self.getCamera(position: .front) {
                    newVideoInput = try AVCaptureDeviceInput(device: front)
                } else if currInput.device.position == .front, let back = self.getCamera(position: .back) {
                    newVideoInput = try AVCaptureDeviceInput(device: back)
                } else {
                    return
                }
                
                if let newVideoInput = newVideoInput {
                    self.captureSession.beginConfiguration()
                    
                    self.refreshSessionPreset(device: newVideoInput.device)
                    
                    self.captureSession.removeInput(currInput)
                    
                    if self.captureSession.canAddInput(newVideoInput) {
                        self.captureSession.addInput(newVideoInput)
                        self.deviceInput = newVideoInput
                    } else {
                        self.refreshSessionPreset(device: currInput.device)
                        self.captureSession.addInput(currInput)
                    }
                                        
                    self.captureSession.commitConfiguration()
                    
                    self.startRunning()
                    
                    if handle != nil {
                        handle!()
                    }
                }
            } catch {
                PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:"切换摄像头失败 \(error.localizedDescription)",icon:.Error,style: .Normal)
            }
        }
        
    }
    
    private func getCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    private func refreshSessionPreset(device: AVCaptureDevice) {
        func setSessionPreset(_ preset: AVCaptureSession.Preset) {
            guard captureSession.sessionPreset != preset else {
                return
            }
            
            captureSession.sessionPreset = preset
        }
        
        let preset = cameraConfig.sessionPreset.avSessionPreset
        if device.supportsSessionPreset(preset), captureSession.canSetSessionPreset(preset) {
            setSessionPreset(preset)
        } else {
            setSessionPreset(.photo)
        }
    }
    
    private func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        if cameraConfig.allowRecordVideo {
            NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        }
    }
    
    @objc private func appWillResignActive() {
        if captureSession.isRunning {
            PTUtils.returnFrontVC()
        }
        if videoUrl != nil, let player = recordVideoPlayerLayer?.player {
            player.pause()
        }
    }
    
    @objc private func appDidBecomeActive() {
        if videoUrl != nil, let player = recordVideoPlayerLayer?.player {
            player.play()
        }
    }
    
    @objc private func handleAudioSessionInterruption(_ notify: Notification) {
        guard recordVideoPlayerLayer?.isHidden == false, let player = recordVideoPlayerLayer?.player else {
            return
        }
        guard player.rate == 0 else {
            return
        }
        
        let type = notify.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
        let option = notify.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
        if type == AVAudioSession.InterruptionType.ended.rawValue, option == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
            player.play()
        }
    }
    
    public func startRecord() {
        guard let movieFileOutput = movieFileOutput else {
            return
        }
        
        guard !movieFileOutput.isRecording else {
            return
        }
        
        guard captureSession.outputs.contains(movieFileOutput) else {
            //TODO:
            //            showAlertAndDismissAfterDoneAction(message: localLanguageTextValue(.cameraUnavailable), type: .camera)
            return
        }
        
        //        dismissBtn.isHidden = true
        //        flashBtn.isHidden = true
        
        let connection = movieFileOutput.connection(with: .video)
        connection?.videoScaleAndCropFactor = 1
        if !restartRecordAfterSwitchCamera {
            connection?.videoOrientation = orientation
            cacheVideoOrientation = orientation
        } else {
            connection?.videoOrientation = cacheVideoOrientation
        }
        
        // 解决不同系统版本,因为录制视频编码导致安卓端无法播放的问题
        if #available(iOS 11.0, *),
           movieFileOutput.availableVideoCodecTypes.contains(cameraConfig.videoCodecType),
           let connection = connection {
            let outputSettings = [AVVideoCodecKey: cameraConfig.videoCodecType]
            movieFileOutput.setOutputSettings(outputSettings, for: connection)
        }
        // 解决前置摄像头录制视频时候左右颠倒的问题
        if deviceInput?.device.position == .front {
            // 镜像设置
            if connection?.isVideoMirroringSupported == true {
                connection?.isVideoMirrored = true
            }
            closeTorch()
        } else {
            openTorch()
        }
        
        let url = URL(fileURLWithPath: PTCameraFilterConfig.getVideoExportFilePath())
        movieFileOutput.startRecording(to: url, recordingDelegate: self)
    }
    
    func closeTorch() {
        if deviceInput!.device.hasTorch {
            do {
                try deviceInput!.device.lockForConfiguration()
                deviceInput!.device.torchMode = .off
                deviceInput!.device.unlockForConfiguration()
            } catch {
                PTNSLogConsole(error.localizedDescription)
            }
        }
    }
    
    func openTorch() {
        if deviceInput!.device.hasTorch {
            do {
                try deviceInput!.device.lockForConfiguration()
                deviceInput!.device.torchMode = .on
                deviceInput!.device.unlockForConfiguration()
            } catch {
                PTNSLogConsole(error.localizedDescription)
            }
        }
    }
    
    public func setVideoZoomFactor(_ zoomFactor: CGFloat) {
        guard let device = self.deviceInput?.device else {
            return
        }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        } catch {
//            zl_debugPrint("调整焦距失败 \(error.localizedDescription)")
        }
    }

}

extension C7CollectorCamera {
    
    public func startRunning() {
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }
    
    public func stopRunning() {
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
}

extension C7CollectorCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        self.processing(with: pixelBuffer)
    }
}

extension C7CollectorCamera:AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
            
        PTGCDManager.gcdMain {
            defer {
//                self.isTakingPicture = false
            }
            
            if photoSampleBuffer == nil || error != nil {
                PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:"拍照失败 \(error?.localizedDescription ?? "")",icon:.Error,style: .Normal)
                return
            }

            if let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
                self.stopRunning()
                let image = UIImage(data: data)?.pt.fixOrientation()
                
                var dest = BoxxIO(element: image, filters: self.filters)
                dest.transmitOutputRealTimeCommit = true
                self.delegate?.takePhoto!(self, fliter: (try? dest.output() ?? image!)!)
            } else {
                PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:"拍照失败，data为空",icon:.Error,style: .Normal)
            }
        }
    }
}

extension C7CollectorCamera: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        guard recordLongGes?.state != .possible else {
            finishRecordAndMergeVideo()
            return
        }
        
        if restartRecordAfterSwitchCamera {
            restartRecordAfterSwitchCamera = false
                
            PTGCDManager.gcdMain {
                let pauseTime = self.animateLayer.timeOffset
                self.animateLayer.speed = 1
                self.animateLayer.timeOffset = 0
                self.animateLayer.beginTime = 0
                let timeSincePause = self.animateLayer.convertTime(CACurrentMediaTime(), from: nil) - pauseTime
                self.animateLayer.beginTime = timeSincePause
            }
        } else {
            PTGCDManager.gcdMain {
                self.startRecordAnimation()
            }
        }
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        PTGCDManager.gcdMain {
            self.recordUrls.append(outputFileURL)
            self.recordDurations.append(output.recordedDuration.seconds)
            
            if self.restartRecordAfterSwitchCamera {
                self.startRecord()
                return
            }
            
            self.finishRecordAndMergeVideo()
        }
    }
    
    private func finishRecordAndMergeVideo() {
        PTGCDManager.gcdMain {
            self.stopRecordAnimation()
            
            defer {
//                self.resetSubViewStatus()
            }
            
            guard !self.recordUrls.isEmpty else {
                return
            }
            
            let duration = self.recordDurations.reduce(0, +)
            
            // 重置焦距
            self.setVideoZoomFactor(1)
            if duration < Double(self.cameraConfig.minRecordDuration) {
//                showAlertView(String(format: localLanguageTextValue(.minRecordTimeTips), self.cameraConfig.minRecordDuration), self)
                self.recordUrls.forEach { try? FileManager.default.removeItem(at: $0) }
                self.recordUrls.removeAll()
                self.recordDurations.removeAll()
                return
            }
            
            self.captureSession.stopRunning()
            
            // 拼接视频
            if self.recordUrls.count > 1 {
//                let hud = ZLProgressHUD.show(toast: .processing)
                PTCameraFilterConfig.mergeVideos(fileUrls: self.recordUrls) { [weak self] url, error in
//                    hud.hide()
                    
                    if let url = url, error == nil {
                        self?.videoUrl = url
                        self?.playRecordVideo(fileUrl: url)
                    } else if let error = error {
                        self?.videoUrl = nil
//                        showAlertView(error.localizedDescription, self)
                    }

                    self?.recordUrls.forEach { try? FileManager.default.removeItem(at: $0) }
                    self?.recordUrls.removeAll()
                    self?.recordDurations.removeAll()
                }
            } else {
                let url = self.recordUrls[0]
                self.videoUrl = url
                self.playRecordVideo(fileUrl: url)
                self.recordUrls.removeAll()
                self.recordDurations.removeAll()
            }
        }
    }
    
    private func startRecordAnimation() {
        UIView.animate(withDuration: 0.1, animations: {
            self.largeCircleView.layer.transform = CATransform3DScale(CATransform3DIdentity, PTFilterCameraViewController.largeCircleRecordScale, PTFilterCameraViewController.largeCircleRecordScale, 1)
            self.smallCircleView.layer.transform = CATransform3DScale(CATransform3DIdentity, PTFilterCameraViewController.smallCircleRecordScale, PTFilterCameraViewController.smallCircleRecordScale, 1)
            self.borderLayer.strokeColor = PTFilterCameraViewController.cameraBtnRecodingBorderColor.cgColor
            self.borderLayer.lineWidth = PTFilterCameraViewController.animateLayerWidth
        }) { _ in
            self.largeCircleView.layer.addSublayer(self.animateLayer)
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = Double(self.cameraConfig.maxRecordDuration)
            animation.delegate = self
            self.animateLayer.add(animation, forKey: nil)
        }
    }
    
    private func stopRecordAnimation() {
        PTGCDManager.gcdMain {
            self.borderLayer.strokeColor = PTFilterCameraViewController.cameraBtnNormalColor.cgColor
            self.borderLayer.lineWidth = PTFilterCameraViewController.borderLayerWidth
            self.animateLayer.speed = 1
            self.animateLayer.timeOffset = 0
            self.animateLayer.beginTime = 0
            self.animateLayer.removeFromSuperlayer()
            self.animateLayer.removeAllAnimations()
            self.largeCircleView.transform = .identity
            self.smallCircleView.transform = .identity
        }
    }
    
    private func playRecordVideo(fileUrl: URL) {
        recordVideoPlayerLayer?.isHidden = false
        let player = AVPlayer(url: fileUrl)
        player.automaticallyWaitsToMinimizeStalling = false
        recordVideoPlayerLayer?.player = player
        player.play()
    }

}

extension C7CollectorCamera: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim is CAAnimationGroup {
            focusCursorView.alpha = 0
            focusCursorView.layer.removeAllAnimations()
            isAdjustingFocusPoint = false
        } else {
            finishRecord()
        }
    }
    
    public func finishRecord() {
        closeTorch()
        restartRecordAfterSwitchCamera = false

        guard let movieFileOutput = movieFileOutput else {
            return
        }

        guard movieFileOutput.isRecording else {
            return
        }

        movieFileOutput.stopRecording()
    }
}

