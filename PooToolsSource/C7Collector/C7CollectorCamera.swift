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
import Photos
import Kakapos

/// 相机数据采集器，在主线程返回图片
/// The camera data collector returns pictures in the main thread.
public final class C7CollectorCamera: C7Collector {
    
    var shotImageCallback: ((UIImage) -> Void)!
    private var videoUrl: URL?
    
    private lazy var cameraConfig = C7CameraConfig.share
    
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
        let preset = AVCaptureSession.Preset.hd1280x720
        if session.canSetSessionPreset(preset) {
            session.sessionPreset = preset
        }
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
    
    public var showedImageView:UIImageView!
    public var haveRecordVideo:PTActionTask? = nil
    public var avPlayer:C7CollectorVideo?
    public var savedVideo:PTActionTask? = nil

    deinit {
        stopRunning()
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
    }
    
    public override func setupInit() {
        super.setupInit()
                
        if PTCameraFilterConfig.share.allowRecordVideo {
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
        guard let camera = getCamera(position: cameraConfig.devicePosition.avDevicePosition) else { return }
        self.deviceInput = try? AVCaptureDeviceInput(device: camera)
        captureSession.beginConfiguration()
        refreshSessionPreset(device: camera)
        
        let movieFileOutput = AVCaptureMovieFileOutput()
        // 解决视频录制超过10s没有声音的bug
        movieFileOutput.movieFragmentInterval = .invalid
        self.movieFileOutput = movieFileOutput
        
        // 添加视频输入
        if let videoInput = deviceInput, captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // 添加音频输入
        self.addAudioInput()
        
        // 照片输出流
        let imageOutput = AVCapturePhotoOutput()
        self.imageOutput = imageOutput
        // 将输出流添加到session
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
        if self.captureSession.canAddOutput(movieFileOutput) {
            self.captureSession.addOutput(movieFileOutput)
        }
        
        let _ = videoOutput
        captureSession.commitConfiguration()
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
        guard PTCameraFilterConfig.share.allowRecordVideo else { return }
        
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
        guard C7CameraConfig.hasCameraAuthority(), !isTakingPicture else {
            return
        }
        
        guard captureSession.outputs.contains(videoOutput) else {
            //MARK: 相机不能用
            PTNSLogConsole("相机不能用",levelType: .Error,loggerType: .Filter)
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
        
        if let image = self.showedImageView.image {
            if deviceInput?.device.position == .front {
                shotImageCallback(image.c7.rotate(degrees: 90))
            } else {
                shotImageCallback(image)
            }
        }
    }
        
    public func changeCamera(handle:PTActionTask?) {
        guard deviceInput != nil else { return }
        guard !restartRecordAfterSwitchCamera else { return }
        guard let currInput = deviceInput, let movieFileOutput = movieFileOutput else { return }

        if movieFileOutput.isRecording {
            let pauseTime = animateLayer.convertTime(CACurrentMediaTime(), from: nil)
            animateLayer.speed = 0
            animateLayer.timeOffset = pauseTime
            restartRecordAfterSwitchCamera = true
        }

        sessionQueue.async {
            // Ensure the session is stopped completely before reconfiguring
            self.captureSession.stopRunning()

            do {
                // Determine the new camera input
                var newVideoInput: AVCaptureDeviceInput?
                if currInput.device.position == .back, let front = self.getCamera(position: .front) {
                    newVideoInput = try AVCaptureDeviceInput(device: front)
                } else if currInput.device.position == .front, let back = self.getCamera(position: .back) {
                    newVideoInput = try AVCaptureDeviceInput(device: back)
                } else {
                    return
                }

                // Start configuring the session
                self.captureSession.beginConfiguration()

                // Remove the current input and clear the reference
                self.captureSession.removeInput(currInput)
                                
                // Attempt to add the new input
                if let newVideoInput = newVideoInput, self.captureSession.canAddInput(newVideoInput) {
                    // Update session preset based on the new device
                    self.refreshSessionPreset(device: newVideoInput.device)
                    self.captureSession.addInput(newVideoInput)
                    self.deviceInput = newVideoInput  // Set the new device input
                } else {
                    // If unable to add, restore the original input
                    self.refreshSessionPreset(device: currInput.device)
                    self.captureSession.addInput(currInput)
                    self.deviceInput = currInput
                }

                // Restart the session after configuration
                self.startRunning()
                self.captureSession.commitConfiguration()
                handle?()
                
            } catch {
                PTAlertTipControl.present(title: "PT Alert Opps".localized(),
                                          subtitle: "PT Filter cam change failed".localized() + "\(error.localizedDescription)",
                                          icon: .Error,
                                          style: .Normal)
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
        
    public func startRecord() {
        guard let movieFileOutput = movieFileOutput else {
            return
        }
        
        guard !movieFileOutput.isRecording else {
            return
        }
        
        guard captureSession.outputs.contains(movieFileOutput) else {
            return
        }
        
        let connection = movieFileOutput.connection(with: .video)
        connection?.videoScaleAndCropFactor = 1
        if !restartRecordAfterSwitchCamera {
            connection?.videoOrientation = orientation
            cacheVideoOrientation = orientation
        } else {
            connection?.videoOrientation = cacheVideoOrientation
        }
        
        // 解决不同系统版本,因为录制视频编码导致安卓端无法播放的问题
        if movieFileOutput.availableVideoCodecTypes.contains(PTCameraFilterConfig.share.videoCodecType),
           let connection = connection {
            let outputSettings = [AVVideoCodecKey: PTCameraFilterConfig.share.videoCodecType]
            movieFileOutput.setOutputSettings(outputSettings, for: connection)
        }
        // 解决前置摄像头录制视频时候左右颠倒的问题
        if deviceInput?.device.position == .front {
            // 镜像设置
            if connection?.isVideoMirroringSupported == true {
                connection?.isVideoMirrored = true
            }
            closeTorch()
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
                PTNSLogConsole(error.localizedDescription,levelType: .Error,loggerType: .Filter)
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
                PTNSLogConsole(error.localizedDescription,levelType: .Error,loggerType: .Filter)
            }
        }
    }
    
    public func setVideoZoomFactor(_ zoomFactor: CGFloat) {
        guard let device = deviceInput?.device else {
            return
        }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        } catch {
            PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:"PT Camera focus error ".localized() + error.localizedDescription,icon:.Error,style: .Normal)
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

extension C7CollectorCamera {
    
    public func startRunning() {
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }
    
    public func stopRunning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}

extension C7CollectorCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        processing(with: pixelBuffer)
    }
}

extension C7CollectorCamera:AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        self.stopRunning()
        if let data = photo.fileDataRepresentation() {
            let image = UIImage(data: data)?.c7.fixOrientation()
            
            var dest = HarbethIO(element: image, filters: self.filters)
            dest.transmitOutputRealTimeCommit = true
            self.delegate?.preview(self, fliter: (try? dest.output() ?? image!)!)
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
            if duration < Double(PTCameraFilterConfig.share.minRecordDuration) {
                self.recordUrls.forEach { try? FileManager.default.removeItem(at: $0) }
                self.recordUrls.removeAll()
                self.recordDurations.removeAll()
                return
            }
            
            self.captureSession.stopRunning()
            
            // 拼接视频
            if self.recordUrls.count > 1 {
                PTCameraFilterConfig.mergeVideos(fileUrls: self.recordUrls) { [weak self] url, error in
                    if let url = url, error == nil {
                        self?.videoUrl = url
                        self?.playRecordVideo(fileUrl: url)
                    } else if let error = error {
                        self?.videoUrl = nil
                        PTNSLogConsole("\(error)")
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
            animation.duration = Double(PTCameraFilterConfig.share.maxRecordDuration)
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
        haveRecordVideo?()
        stopRunning()
        let asset = AVURLAsset.init(url: fileUrl)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer.init(playerItem: playerItem)
        avPlayer = C7CollectorVideo.init(player: player, delegate: self)
        avPlayer?.filters = self.filters

        avPlayer?.play()
    }
    
    public func saveVideoToAlbum() {
        if let fileUrl = self.videoUrl {
            C7CameraConfig.share.hudShow()
            let provider = VideoX.Provider(with: fileUrl)
            let filtering = FilterInstruction { buffer, time, block in
                let dest = HarbethIO(element: buffer, filters: self.filters)
                dest.transmitOutput(success: block)
            }

            var finish:Bool = false
            
            let exporter = VideoX(provider: provider)
            let _ = exporter.export(options: [.OptimizeForNetworkUse: false,.ExportSessionTimeRange: TimeRangeType.range(CGFloat(PTCameraFilterConfig.share.minRecordDuration)...CGFloat(PTCameraFilterConfig.share.maxRecordDuration))],instructions: [filtering]) { results in
                switch results {
                case .success(let outputUrl):
                    self.rotateVideo(inputURL: outputUrl) { error in
                        if error != nil {
                            PTNSLogConsole("\(error!)")
                        } else {
                            self.savedVideo?()
                        }
                    }
                case .failure(let error):
                    PTNSLogConsole("\(error.description)")
                }
                C7CameraConfig.share.hudHide()
                finish = true
            } progress: { progress in
            }
            
            PTGCDManager.gcdAfter(time: 10) {
                if !finish {
                    C7CameraConfig.share.hudHide()
                    PTNSLogConsole("转换失败")
                }
            }
        }
    }
    
    public func resetCameraView() {
        avPlayer?.pause()
        startRunning()
    }
    
    func rotateVideo(inputURL: URL, completion: @escaping (Error?) -> Void) {
        let asset = AVAsset(url: inputURL)
        _ = AVMutableComposition()
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(NSError(domain: "RotateVideo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get video track"]))
            return
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        videoComposition.frameDuration = videoTrack.minFrameDuration
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let t1 = CGAffineTransform(translationX: videoTrack.naturalSize.height, y: 0)
        let t2 = t1.rotated(by: .pi / 2)
        transformer.setTransform(t2, at: .zero)
        
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(NSError(domain: "RotateVideo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]))
            return
        }
        
        // 创建临时文件路径
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = .mp4
        exportSession.outputURL = outputURL
        
        exportSession.exportAsynchronously {
            if let error = exportSession.error {
                completion(error)
            } else {
                PHPhotoLibrary.pt.saveVideoToAlbum(fileURL: outputURL) { finish, error in
                    if finish {
                        try? FileManager.default.removeItem(at: outputURL)
                        try? FileManager.default.removeItem(at: inputURL)
                        completion(nil)
                    } else {
                        completion(error)
                    }
                }
            }
        }
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
}

extension C7CollectorCamera: C7CollectorImageDelegate {
    public func preview(_ collector: C7Collector, fliter image: C7Image) {
        self.showedImageView.image = image.rotated(by: 90)
    }
}

extension UIImage {
    func rotated(by degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        var newSize = CGRect(origin: .zero, size: self.size)
            .applying(CGAffineTransform(rotationAngle: radians)).integral.size
        // Ensure the new size has even dimensions to avoid rendering issues
        newSize.width = floor(newSize.width / 2) * 2
        newSize.height = floor(newSize.height / 2) * 2
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to the middle of the new size
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate the context
        context.rotate(by: radians)
        // Draw the original image at the rotated position
        self.draw(in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return rotatedImage
    }
}

