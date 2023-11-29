//
//  PTMediaLibConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import Photos
import AVFoundation
import Accelerate
import MobileCoreServices

let PTMaxImageWidth: CGFloat = 500

/// Adjust slider type
@objc public enum PTAdjustSliderType: Int {
    case vertical
    case horizontal
}

@objc public enum PTPhotoBrowserStyle: Int {
    /// The album list is embedded in the navigation of the thumbnail interface, click the drop-down display.
    case embedAlbumList
    
    /// The display relationship between the album list and the thumbnail interface is push.
    case externalAlbumList
}

public class PTMediaLibConfig:NSObject {
    public static let share = PTMediaLibConfig()
    
    public typealias Second = Int
    
    public typealias KBUnit = CGFloat
    
    /// The theme color of framework.
    /// 框架主题色
    public var themeColor: UIColor = .purple

    /// The normal color of adjust slider.
    /// 编辑图片，调整饱和度、对比度、亮度时，右侧slider背景色
    public var adjustSliderNormalColor: UIColor = .white
    private var pri_adjustSliderTintColor: UIColor?
    /// The tint color of adjust slider.
    /// 编辑图片，调整饱和度、对比度、亮度时，右侧slider背景高亮色
    public var adjustSliderTintColor: UIColor {
        get {
            pri_adjustSliderTintColor ?? themeColor
        }
        set {
            pri_adjustSliderTintColor = newValue
        }
    }
    
    public var selectedBorderColor:UIColor = UIColor.purple
    /// Whether to callback directly after taking a photo. Defaults to false.
    public var callbackDirectlyAfterTakingPhoto = false

    /// Photo sorting method, the preview interface is not affected by this parameter. Defaults to true.
    public var sortAscending = true

    /// The maximum number of frames for GIF images. To avoid crashes due to memory spikes caused by loading GIF images with too many frames, it is recommended that this value is not too large. Defaults to 50.
    public var maxFrameCountForGIF = 50

    /// Allow select Gif, it only controls whether it is displayed in Gif form.
    /// If value is false, the Gif logo is not displayed. Defaults to true.
    public var allowSelectGif = true

    /// Save the edited image to the album after editing. Defaults to true.
    public var saveNewImageAfterEdit = true

    /// Allow select full image. Defaults to true.
    public var allowSelectOriginal = true
    /// Always return the original photo.
    /// - warning: Only valid when `allowSelectOriginal = false`, Defaults to false.
    public var alwaysRequestOriginal = false

    /// The configuration for camera.
    public var cameraConfiguration = PTCameraConfig()

    private var pri_allowTakePhotoInLibrary = true
    /// Allow take photos in the album. Defaults to true.
    /// - warning: If allowTakePhoto and allowRecordVideo are both false, it will not be displayed.
    public var allowTakePhotoInLibrary: Bool {
        get {
            pri_allowTakePhotoInLibrary && (cameraConfiguration.allowTakePhoto || cameraConfiguration.allowRecordVideo)
        }
        set {
            pri_allowTakePhotoInLibrary = newValue
        }
    }
    
    ///允许选择图片
    open var allowSelectImage = true
    ///允许选择视频
    open var allowSelectVideo = true
    
    public var maxPreviewCount = 9
    public var allowMixSelect = true
    private var pri_maxSelectCount = 9
    /// Anything superior than 1 will enable the multiple selection feature. Defaults to 9.
    public var maxSelectCount: Int {
        get {
            pri_maxSelectCount
        }
        set {
            pri_maxSelectCount = max(1, newValue)
        }
    }
    private var pri_minVideoSelectCount = 0
    /// A count for video min selection. Defaults to 0.
    /// - warning: Only valid in mix selection mode. (i.e. allowMixSelect = true)
    public var minVideoSelectCount: Int {
        get {
            min(maxSelectCount, max(pri_minVideoSelectCount, 0))
        }
        set {
            pri_minVideoSelectCount = newValue
        }
    }

    private var pri_maxVideoSelectCount = 0
    /// A count for video max selection. Defaults to 0.
    /// - warning: Only valid in mix selection mode. (i.e. allowMixSelect = true)
    public var maxVideoSelectCount: Int {
        get {
            if pri_maxVideoSelectCount <= 0 {
                return maxSelectCount
            } else {
                return max(minVideoSelectCount, min(pri_maxVideoSelectCount, maxSelectCount))
            }
        }
        set {
            pri_maxVideoSelectCount = newValue
        }
    }

    /// In single selection mode, whether to display the selection button. Defaults to false.
    public var showSelectBtnWhenSingleSelect = false
    public var didDeselectAsset: ((PHAsset) -> Void)?
    public var canSelectAsset: ((PHAsset) -> Bool)?
    /// This block will be called when selecting an asset.
    public var didSelectAsset: ((PHAsset) -> Void)?

    /// Allow to choose the maximum duration of the video. Defaults to 120.
    public var maxSelectVideoDuration: PTMediaLibConfig.Second = 120
    /// Allow to choose the minimum duration of the video. Defaults to 0.
    public var minSelectVideoDuration: PTMediaLibConfig.Second = 0
    /// Allow to choose the maximum data size of the video. Defaults to infinite.
    public var maxSelectVideoDataSize: PTMediaLibConfig.KBUnit = .greatestFiniteMagnitude
    
    /// Allow to choose the minimum data size of the video. Defaults to 0 KB.
    public var minSelectVideoDataSize: PTMediaLibConfig.KBUnit = 0
    public var downloadVideoBeforeSelecting = false
    /// After selecting a image/video in the thumbnail interface, enter the editing interface directly. Defaults to false.
    /// - discussion: Editing image is only valid when allowEditImage is true and maxSelectCount is 1.
    /// Editing video is only valid when allowEditVideo is true and maxSelectCount is 1.
    public var editAfterSelectThumbnailImage = false
    private var pri_allowEditImage = true
    public var allowEditImage: Bool {
        get {
            pri_allowEditImage
        }
        set {
            pri_allowEditImage = newValue
        }
    }
    /// - warning: The video can only be edited when no photos are selected, or only one video is selected, and the selection callback is executed immediately after editing is completed.
    private var pri_allowEditVideo = false
    public var allowEditVideo: Bool {
        get {
            pri_allowEditVideo
        }
        set {
            pri_allowEditVideo = newValue
        }
    }
    public var cropVideoAfterSelectThumbnail = true
}

public class PTMediaLibUIConfig:NSObject {
    public static let share = PTMediaLibUIConfig()
    
    /// Adjust Slider Type
    public var adjustSliderType: PTAdjustSliderType = .vertical
    public var sortAscending = true
    public var style: PTPhotoBrowserStyle = .embedAlbumList
    public var animateSelectBtnWhenSelectInThumbVC = false
    public var showInvalidMask = true
}

//MARK: Edit config
public class PTMediaEditConfig:NSObject {
    public static let share = PTMediaEditConfig()

    /// Give an impact feedback when the adjust slider value is zero. Defaults to true.
    public var impactFeedbackWhenAdjustSliderValueIsZero = true
    @discardableResult
    func impactFeedbackStyle(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> PTMediaEditConfig {
        impactFeedbackStyle = style
        return self
    }
    /// Impact feedback style. Defaults to .medium
    public var impactFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium

    private var pri_filters: [PTFilter] = PTFilter.all
    /// Filters for image editor.
    public var filters: [PTFilter] {
        get {
            if pri_filters.isEmpty {
                return PTFilter.all
            } else {
                return pri_filters
            }
        }
        set {
            pri_filters = newValue
        }
    }
    /// The default text sticker color. If this color not in textStickerTextColors, will pick the first color in textStickerTextColors as the default.
    public var textStickerDefaultTextColor = UIColor.white

    /// The default font of text sticker.
    public var textStickerDefaultFont: UIFont?

    private var pri_clipRatios: [PTImageClipRatio] = [.custom,.circle,.wh1x1,.wh3x4,.wh4x3,.wh2x3,.wh3x2,.wh9x16,.wh16x9]
    /// Edit ratios for image editor.
    public var clipRatios: [PTImageClipRatio] {
        get {
            if pri_clipRatios.isEmpty {
                return [.custom]
            } else {
                return pri_clipRatios
            }
        }
        set {
            pri_clipRatios = newValue
        }
    }

    /// Whether to keep clipped area dimmed during adjustments. Defaults to false
    public var dimClippedAreaDuringAdjustments = false

    @objc public enum EditTool: Int, CaseIterable {
        case draw
        case clip
        case textSticker
        case mosaic
        case filter
        case adjust
    }
    
    private var pri_tools: [PTMediaEditConfig.EditTool] = PTMediaEditConfig.EditTool.allCases
    /// Edit image tools. (Default order is draw, clip, imageSticker, textSticker, mosaic, filtter)
    /// Because Objective-C Array can't contain Enum styles, so this property is invalid in Objective-C.
    /// - warning: If you want to use the image sticker feature, you must provide a view that implements ZLImageStickerContainerDelegate.
    public var tools: [PTMediaEditConfig.EditTool] {
        get {
            if pri_tools.isEmpty {
                return PTMediaEditConfig.EditTool.allCases
            } else {
                return pri_tools
            }
        }
        set {
            pri_tools = newValue
        }
    }


    /// Minimum zoom scale, allowing the user to make the edited photo smaller, so it does not overlap top and bottom tools menu. Defaults to 1.0
    public var minimumZoomScale = 1.0
    
    @objc enum AdjustTool: Int, CaseIterable {
        case brightness
        case contrast
        case saturation
        
        var key: String {
            switch self {
            case .brightness:
                return kCIInputBrightnessKey
            case .contrast:
                return kCIInputContrastKey
            case .saturation:
                return kCIInputSaturationKey
            }
        }
        
        func filterValue(_ value: Float) -> Float {
            switch self {
            case .brightness:
                // 亮度范围-1---1，默认0，这里除以3，取 -0.33---0.33
                return value / 3
            case .contrast:
                // 对比度范围0---4，默认1，这里计算下取0.5---2.5
                let v: Float
                if value < 0 {
                    v = 1 + value * (1 / 2)
                } else {
                    v = 1 + value * (3 / 2)
                }
                return v
            case .saturation:
                // 饱和度范围0---2，默认1
                return value + 1
            }
        }
    }
}

@objcMembers
public class PTCameraConfig: NSObject {
    private var pri_allowTakePhoto = true
    /// Allow taking photos in the camera (Need allowSelectImage to be true). Defaults to true.
    public var allowTakePhoto: Bool {
        get {
            pri_allowTakePhoto && PTMediaLibConfig.share.allowSelectImage
        }
        set {
            pri_allowTakePhoto = newValue
        }
    }
    
    private var pri_allowRecordVideo = true
    /// Allow recording in the camera (Need allowSelectVideo to be true). Defaults to true.
    public var allowRecordVideo: Bool {
        get {
            pri_allowRecordVideo && PTMediaLibConfig.share.allowSelectVideo
        }
        set {
            pri_allowRecordVideo = newValue
        }
    }
    
    private var pri_minRecordDuration: PTMediaLibConfig.Second = 0
    /// Minimum recording duration. Defaults to 0.
    public var minRecordDuration: PTMediaLibConfig.Second {
        get {
            pri_minRecordDuration
        }
        set {
            pri_minRecordDuration = max(0, newValue)
        }
    }
    
    private var pri_maxRecordDuration: PTMediaLibConfig.Second = 20
    /// Maximum recording duration. Defaults to 20, minimum is 1.
    public var maxRecordDuration: PTMediaLibConfig.Second {
        get {
            pri_maxRecordDuration
        }
        set {
            pri_maxRecordDuration = max(1, newValue)
        }
    }
    
    /// Video resolution. Defaults to hd1920x1080.
    public var sessionPreset: PTCameraConfig.CaptureSessionPreset = .hd1920x1080
    
    /// Camera focus mode. Defaults to continuousAutoFocus
    public var focusMode: PTCameraConfig.FocusMode = .continuousAutoFocus
    
    /// Camera exposure mode. Defaults to continuousAutoExposure
    public var exposureMode: PTCameraConfig.ExposureMode = .continuousAutoExposure
    
    /// Camera flahs switch. Defaults to true.
    public var showFlashSwitch = true
    
    /// Whether to support switch camera. Defaults to true.
    public var allowSwitchCamera = true
    
    /// Video export format for recording video and editing video. Defaults to mov.
    public var videoExportType: PTCameraConfig.VideoExportType = .mov
    
    /// The default camera position after entering the camera. Defaults to back.
    public var devicePosition: PTCameraConfig.DevicePosition = .back
    
    private var pri_videoCodecType: Any?
    /// The codecs for video capture. Defaults to .h264
    @available(iOS 11.0, *)
    public var videoCodecType: AVVideoCodecType {
        get {
            (pri_videoCodecType as? AVVideoCodecType) ?? .h264
        }
        set {
            pri_videoCodecType = newValue
        }
    }
}

public extension PTCameraConfig {
    @objc enum CaptureSessionPreset: Int {
        var avSessionPreset: AVCaptureSession.Preset {
            switch self {
            case .cif352x288:
                return .cif352x288
            case .vga640x480:
                return .vga640x480
            case .hd1280x720:
                return .hd1280x720
            case .hd1920x1080:
                return .hd1920x1080
            case .hd4K3840x2160:
                return .hd4K3840x2160
            case .photo:
                return .photo
            }
        }
        
        case cif352x288
        case vga640x480
        case hd1280x720
        case hd1920x1080
        case hd4K3840x2160
        case photo
    }
    
    @objc enum FocusMode: Int {
        var avFocusMode: AVCaptureDevice.FocusMode {
            switch self {
            case .autoFocus:
                return .autoFocus
            case .continuousAutoFocus:
                return .continuousAutoFocus
            }
        }
        
        case autoFocus
        case continuousAutoFocus
    }
    
    @objc enum ExposureMode: Int {
        var avFocusMode: AVCaptureDevice.ExposureMode {
            switch self {
            case .autoExpose:
                return .autoExpose
            case .continuousAutoExposure:
                return .continuousAutoExposure
            }
        }
        
        case autoExpose
        case continuousAutoExposure
    }
    
    @objc enum VideoExportType: Int {
        var format: String {
            switch self {
            case .mov:
                return "mov"
            case .mp4:
                return "mp4"
            }
        }
        
        var avFileType: AVFileType {
            switch self {
            case .mov:
                return .mov
            case .mp4:
                return .mp4
            }
        }
        
        case mov
        case mp4
    }
    
    @objc enum DevicePosition: Int {
        case back
        case front
        
        /// For custom camera
        var avDevicePosition: AVCaptureDevice.Position {
            switch self {
            case .back:
                return .back
            case .front:
                return .front
            }
        }
        
        /// For system camera
        var cameraDevice: UIImagePickerController.CameraDevice {
            switch self {
            case .back:
                return .rear
            case .front:
                return .front
            }
        }
    }
}

// MARK: chaining

public extension PTCameraConfig {
    @discardableResult
    func allowTakePhoto(_ value: Bool) -> PTCameraConfig {
        allowTakePhoto = value
        return self
    }
    
    @discardableResult
    func allowRecordVideo(_ value: Bool) -> PTCameraConfig {
        allowRecordVideo = value
        return self
    }
    
    @discardableResult
    func minRecordDuration(_ duration: PTMediaLibConfig.Second) -> PTCameraConfig {
        minRecordDuration = duration
        return self
    }
    
    @discardableResult
    func maxRecordDuration(_ duration: PTMediaLibConfig.Second) -> PTCameraConfig {
        maxRecordDuration = duration
        return self
    }
    
    @discardableResult
    func sessionPreset(_ sessionPreset: PTCameraConfig.CaptureSessionPreset) -> PTCameraConfig {
        self.sessionPreset = sessionPreset
        return self
    }
    
    @discardableResult
    func focusMode(_ mode: PTCameraConfig.FocusMode) -> PTCameraConfig {
        focusMode = mode
        return self
    }
    
    @discardableResult
    func exposureMode(_ mode: PTCameraConfig.ExposureMode) -> PTCameraConfig {
        exposureMode = mode
        return self
    }
    
    @discardableResult
    func showFlashSwitch(_ value: Bool) -> PTCameraConfig {
        showFlashSwitch = value
        return self
    }
    
    @discardableResult
    func allowSwitchCamera(_ value: Bool) -> PTCameraConfig {
        allowSwitchCamera = value
        return self
    }
    
    @discardableResult
    func videoExportType(_ type: PTCameraConfig.VideoExportType) -> PTCameraConfig {
        videoExportType = type
        return self
    }
    
    @discardableResult
    func devicePosition(_ position: PTCameraConfig.DevicePosition) -> PTCameraConfig {
        devicePosition = position
        return self
    }
    
    @available(iOS 11.0, *)
    @discardableResult
    func videoCodecType(_ type: AVVideoCodecType) -> PTCameraConfig {
        videoCodecType = type
        return self
    }
}

public extension PTPOP where Base: UIImage {
    /// 加马赛克
    func mosaicImage() -> UIImage? {
        guard let cgImage = base.cgImage else {
            return nil
        }
        
        let scale = 8 * base.size.width / UIScreen.main.bounds.width
        let currCiImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(currCiImage, forKey: kCIInputImageKey)
        filter?.setValue(scale, forKey: kCIInputScaleKey)
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        
        if let cgImage = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: base.size)) {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }

    func toCIImage() -> CIImage? {
        var ciImage = base.ciImage
        if ciImage == nil, let cgImage = base.cgImage {
            ciImage = CIImage(cgImage: cgImage)
        }
        return ciImage
    }

    func blurImage(level: CGFloat) -> UIImage? {
        guard let ciImage = toCIImage() else {
            return nil
        }
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: "inputImage")
        blurFilter?.setValue(level, forKey: "inputRadius")
        
        guard let outputImage = blurFilter?.outputImage else {
            return nil
        }
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    func clipImage(angle: CGFloat, editRect: CGRect, isCircle: Bool) -> UIImage {
        let a = ((Int(angle) % 360) - 360) % 360
        var newImage: UIImage = base
        if a == -90 {
            newImage = rotate(orientation: .left)
        } else if a == -180 {
            newImage = rotate(orientation: .down)
        } else if a == -270 {
            newImage = rotate(orientation: .right)
        }
        guard editRect.size != newImage.size else {
            return newImage
        }
        
        let origin = CGPoint(x: -editRect.minX, y: -editRect.minY)
        
        let temp = UIGraphicsImageRenderer.pt.renderImage(size: editRect.size) { format in
            format.scale = newImage.scale
        } imageActions: { context in
            if isCircle {
                context.addEllipse(in: CGRect(origin: .zero, size: editRect.size))
                context.clip()
            }
            newImage.draw(at: origin)
        }
        
        guard let cgi = temp.cgImage else { return temp }
        
        let clipImage = UIImage(cgImage: cgi, scale: newImage.scale, orientation: .up)
        return clipImage
    }

    /// 旋转方向
    func rotate(orientation: UIImage.Orientation) -> UIImage {
        guard let imagRef = base.cgImage else {
            return base
        }
        let rect = CGRect(origin: .zero, size: CGSize(width: CGFloat(imagRef.width), height: CGFloat(imagRef.height)))
        
        var bnds = rect
        
        var transform = CGAffineTransform.identity
        
        switch orientation {
        case .up:
            return base
        case .upMirrored:
            transform = transform.translatedBy(x: rect.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .down:
            transform = transform.translatedBy(x: rect.width, y: rect.height)
            transform = transform.rotated(by: .pi)
        case .downMirrored:
            transform = transform.translatedBy(x: 0, y: rect.height)
            transform = transform.scaledBy(x: 1, y: -1)
        case .left:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: 0, y: rect.width)
            transform = transform.rotated(by: CGFloat.pi * 3 / 2)
        case .leftMirrored:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: rect.height, y: rect.width)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: CGFloat.pi * 3 / 2)
        case .right:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: rect.height, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .rightMirrored:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: CGFloat.pi / 2)
        @unknown default:
            return base
        }
        
        UIGraphicsBeginImageContext(bnds.size)
        let context = UIGraphicsGetCurrentContext()
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.scaleBy(x: -1, y: 1)
            context?.translateBy(x: -rect.height, y: 0)
        default:
            context?.scaleBy(x: 1, y: -1)
            context?.translateBy(x: 0, y: -rect.height)
        }
        context?.concatenate(transform)
        context?.draw(imagRef, in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? base
    }

    func swapRectWidthAndHeight(_ rect: CGRect) -> CGRect {
        var r = rect
        r.size.width = rect.height
        r.size.height = rect.width
        return r
    }

    func fixOrientation() -> UIImage {
        if base.imageOrientation == .up {
            return base
        }
        
        var transform = CGAffineTransform.identity
        
        switch base.imageOrientation {
        case .down, .downMirrored:
            transform = CGAffineTransform(translationX: base.size.width, y: base.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = CGAffineTransform(translationX: base.size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .right, .rightMirrored:
            transform = CGAffineTransform(translationX: 0, y: base.size.height)
            transform = transform.rotated(by: -CGFloat.pi / 2)
        default:
            break
        }
        
        switch base.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: base.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: base.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let cgImage = base.cgImage, let colorSpace = cgImage.colorSpace else {
            return base
        }
        let context = CGContext(
            data: nil,
            width: Int(base.size.width),
            height: Int(base.size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )
        context?.concatenate(transform)
        switch base.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: base.size.height, height: base.size.width))
        default:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height))
        }
        
        guard let newCgImage = context?.makeImage() else {
            return base
        }
        return UIImage(cgImage: newCgImage)
    }

    /// Resize image. Processing speed is better than resize(:) method
    /// - Parameters:
    ///   - size: Dest size of the image
    ///   - scale: The scale factor of the image
    func resize_vI(_ size: CGSize, scale: CGFloat? = nil) -> UIImage? {
        guard let cgImage = base.cgImage else { return nil }
        
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: nil,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
        var sourceBuffer = vImage_Buffer()
        defer {
            if #available(iOS 13.0, *) {
                sourceBuffer.free()
            } else {
                sourceBuffer.data.deallocate()
            }
        }
        
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }
        
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let destBytesPerRow = destWidth * bytesPerPixel
        
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
        
        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }
        
        // create a CGImage from vImage_Buffer
        guard let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue() else { return nil }
        guard error == kvImageNoError else { return nil }
        
        // create a UIImage
        return UIImage(cgImage: destCGImage, scale: scale ?? base.scale, orientation: base.imageOrientation)
    }


    func hasAlphaChannel() -> Bool {
        guard let info = base.cgImage?.alphaInfo else {
            return false
        }
        
        return info == .first || info == .last || info == .premultipliedFirst || info == .premultipliedLast
    }

    static func animateGifImage(data: Data) -> UIImage? {
        // Kingfisher
        let info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, info as CFDictionary) else {
            return UIImage(data: data)
        }
        
        var frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 1 else {
            return UIImage(data: data)
        }
        
        let maxFrameCount = PTMediaLibConfig.share.maxFrameCountForGIF
        
        let ratio = CGFloat(max(frameCount, maxFrameCount)) / CGFloat(maxFrameCount)
        frameCount = min(frameCount, maxFrameCount)
        
        var images = [UIImage]()
        var frameDuration = [Int]()
        
        for i in 0..<frameCount {
            let index = Int(floor(CGFloat(i) * ratio))
            
            guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, info as CFDictionary) else {
                return nil
            }
            
            // Get current animated GIF frame duration
            let currFrameDuration = getFrameDuration(from: imageSource, at: index) * min(ratio, 3)
            // Second to ms
            frameDuration.append(Int(currFrameDuration * 1000))
            
            images.append(UIImage(cgImage: imageRef, scale: 1, orientation: .up))
        }
        
        let duration: Int = {
            var sum = 0
            for val in frameDuration {
                sum += val
            }
            return sum
        }()
        
        // 求出每一帧的最大公约数
        let gcd = gcdForArray(frameDuration)
        var frames = [UIImage]()

        for i in 0..<frameCount {
            let frameImage = images[i]
            // 每张图片的时长除以最大公约数，得出需要展示的张数
            let count = Int(frameDuration[i] / gcd)

            for _ in 0..<count {
                frames.append(frameImage)
            }
        }
        
        return .animatedImage(with: frames, duration: TimeInterval(duration) / 1000)
    }

    /// Calculates frame duration at a specific index for a gif from an `imageSource`.
    static func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
            as? [String: Any] else { return 0.0 }

        let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        return getFrameDuration(from: gifInfo)
    }
    
    /// Calculates frame duration for a gif frame out of the kCGImagePropertyGIFDictionary dictionary.
    static func getFrameDuration(from gifInfo: [String: Any]?) -> TimeInterval {
        let defaultFrameDuration = 0.1
        guard let gifInfo = gifInfo else { return defaultFrameDuration }
        
        let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let duration = unclampedDelayTime ?? delayTime
        
        guard let frameDuration = duration else {
            return defaultFrameDuration
        }
        return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : defaultFrameDuration
    }

    private static func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }

        var gcd = array[0]

        for val in array {
            gcd = gcdForPair(val, gcd)
        }

        return gcd
    }

    private static func gcdForPair(_ num1: Int?, _ num2: Int?) -> Int {
        guard var num1 = num1, var num2 = num2 else {
            return num1 ?? (num2 ?? 0)
        }
        
        if num1 < num2 {
            swap(&num1, &num2)
        }

        var rest: Int
        while true {
            rest = num1 % num2

            if rest == 0 {
                return num2
            } else {
                num1 = num2
                num2 = rest
            }
        }
    }

    /// 调整图片亮度、对比度、饱和度
    /// - Parameters:
    ///   - brightness: value in [-1, 1]
    ///   - contrast: value in [-1, 1]
    ///   - saturation: value in [-1, 1]
    func adjust(brightness: Float, contrast: Float, saturation: Float) -> UIImage? {
        guard let ciImage = toCIImage() else {
            return base
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(PTMediaEditConfig.AdjustTool.brightness.filterValue(brightness), forKey: PTMediaEditConfig.AdjustTool.brightness.key)
        filter?.setValue(PTMediaEditConfig.AdjustTool.contrast.filterValue(contrast), forKey: PTMediaEditConfig.AdjustTool.contrast.key)
        filter?.setValue(PTMediaEditConfig.AdjustTool.saturation.filterValue(saturation), forKey: PTMediaEditConfig.AdjustTool.saturation.key)
        let outputCIImage = filter?.outputImage
        return outputCIImage?.pt.toUIImage()
    }
}
