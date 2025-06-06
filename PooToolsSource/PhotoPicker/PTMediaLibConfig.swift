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
import UIKit
import SafeSFSymbols

let PTMaxImageWidth: CGFloat = 500

@objc public enum PTPhotoBrowserStyle: Int {
    /// The album list is embedded in the navigation of the thumbnail interface, click the drop-down display.
    case embedAlbumList
    
    /// The display relationship between the album list and the thumbnail interface is push.
    case externalAlbumList
}

@objcMembers
public class PTMediaLibConfig:NSObject {
    public static let share = PTMediaLibConfig()
        
    public typealias KBUnit = CGFloat
    
    @PTClampedProperyWrapper(range: 1...5) public var videoDownloadBorderWidth:CGFloat = 1.5
    
    /// The theme color of framework.
    /// 框架主题色
    public var themeColor: UIColor = .purple
    
    public var selectedBorderColor:UIColor = UIColor.purple
    /// Whether to callback directly after taking a photo. Defaults to false.
    public var callbackDirectlyAfterTakingPhoto = false

    /// Photo sorting method, the preview interface is not affected by this parameter. Defaults to true.
    public var sortAscending = true

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
    ///只允许选择LivePhoto
    open var allowOnlySelectLivePhoto = false
    ///只允许选择Photo
//    open var allowOnlySelectRegularImage = false

    /// Whether to use custom camera. Defaults to true.
    public var useCustomCamera = true

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

    private var pri_maxRecordDuration: Int = 20
    /// Maximum recording duration. Defaults to 20, minimum is 1.
    public var maxRecordDuration: Int {
        get {
            pri_maxRecordDuration
        }
        set {
            pri_maxRecordDuration = max(1, newValue)
        }
    }
    
#if POOTOOLS_FILTERCAMERA
    /// Allow to choose the maximum duration of the video. Defaults to 120.
    public var maxSelectVideoDuration: PTCameraFilterConfig.Second = 120
    /// Allow to choose the minimum duration of the video. Defaults to 0.
    public var minSelectVideoDuration: PTCameraFilterConfig.Second = 0
#else
    /// Allow to choose the maximum duration of the video. Defaults to 120.
    public var maxSelectVideoDuration: Int = 120
    /// Allow to choose the minimum duration of the video. Defaults to 0.
    public var minSelectVideoDuration: Int = 0
#endif
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
    
    //MARK: NAV
    public var backImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20))
    public var submitImage:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 20))
    public var arrowDownImage:UIImage = "🔽".emojiToImage(emojiFont: .appfont(size: 10))
    public var ablumListBackImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20))
    public var albumSelectedImage:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 15))
    public var cameraImage:UIImage = "📸".emojiToImage(emojiFont: .appfont(size: 24))
    public var albumListNavName:String = "PT Photo picker album list title".localized()
    public var editImage:UIImage = UIImage(.pencil)
    public var emptyTitle:String = "PT Alert Opps".localized()
    public var emptySubDesc:String = "PT Photo picker empty media".localized()
    public var alertTitle:String = "PT Alert Opps".localized()
    public var alertDoingTitle:String = "PT Alert Doning".localized()
    public var mediaCoutError:String = "PT Photo picker select cout more than".localized()
    public var videoTimeMoreError:String = "PT Photo picker video time more than".localized()
    public var videoTimeLessError:String = "PT Photo picker video time less than".localized()
    public var videoSizeMoreError:String = "PT Photo picker video size more than".localized()
    public var videoSizeLessError:String = "PT Photo picker video size less than".localized()
    public var downloadTimeOutError:String = "PT Photo picker time out".localized()
    public var cameraError:String = "PT Photo picker bad".localized()
    public var takePhotoError:String = "PT Photo picker can not take photo".localized()
    public var saveImageError:String = "PT Photo picker save image error".localized()
    public var saveVideoError:String = "PT Photo picker save video error".localized()
    public var mediaCount:String = "PT Photo picker selected count".localized()
    public var mediaCountMax:String = "PT Photo picker video select more than max".localized()
    public var mediaCountMin:String = "PT Photo picker video select less than min".localized()
    public var selectLibTitleFont:UIFont = .appfont(size: 15)
    public var selectLibSubTitleFont:UIFont = .appfont(size: 12)
    public var albumCellTitleFont:UIFont = .appfont(size: 18,bold: true)
    public var albumCellDescFont:UIFont = .appfont(size: 14)
}

public class PTMediaLibUIConfig:NSObject {
    public static let share = PTMediaLibUIConfig()
    
    public var sortAscending = true
    public var style: PTPhotoBrowserStyle = .embedAlbumList
    public var animateSelectBtnWhenSelectInThumbVC = false
    public var showInvalidMask = true
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
        
    /// Video resolution. Defaults to hd1920x1080.
    public var sessionPreset: AVCaptureSession.Preset = .hd1920x1080

        
    /// Camera flahs switch. Defaults to true.
    public var showFlashSwitch = true
    
    /// Whether to support switch camera. Defaults to true.
    public var allowSwitchCamera = true
}

public extension PTCameraConfig {
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
    func showFlashSwitch(_ value: Bool) -> PTCameraConfig {
        showFlashSwitch = value
        return self
    }
    
    @discardableResult
    func allowSwitchCamera(_ value: Bool) -> PTCameraConfig {
        allowSwitchCamera = value
        return self
    }
}

