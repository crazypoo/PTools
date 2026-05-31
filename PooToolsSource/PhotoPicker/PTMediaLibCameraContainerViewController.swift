//
//  PTMediaLibCameraContainerViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 31/5/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Photos
import SnapKit

public class PTMediaLibCameraContainerViewController: PTBaseViewController {

    open override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }

    public let picker = UIImagePickerController()
    public var handleNewAssetCallback:((_ asset: PHAsset) -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupPicker()
    }
    
    private func setupPicker() {
        picker.delegate = self
        picker.sourceType = .camera
        picker.videoQuality = .typeHigh
        picker.mediaTypes = calculateMediaTypes()
        picker.videoMaximumDuration = TimeInterval(PTMediaLibConfig.share.maxRecordDuration)

        addChild(picker)
        view.addSubview(picker.view)

        picker.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        picker.didMove(toParent: self)
    }
    
    private func calculateMediaTypes() -> [String] {
        var types: [String] = []
        if PTMediaLibConfig.share.cameraConfiguration.allowTakePhoto { types.append("public.image") }
        if PTMediaLibConfig.share.cameraConfiguration.allowRecordVideo { types.append("public.movie") }
        return types
    }
}

extension PTMediaLibCameraContainerViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    // MARK: - ImagePicker Delegate
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        let url = info[.mediaURL] as? URL
        
        self.saveMediaToAlbum(image: image, videoUrl: url)
        picker.dismiss(animated: true)
    }

    /// 统一保存逻辑
    fileprivate func saveMediaToAlbum(image: UIImage?, videoUrl: URL?) {
        PTAlertTipsViewController.tipsAlertShow(title: "",subtitle: PTMediaLibUIConfig.share.alertDoingTitle, icon: .Heart)

        let completion: @Sendable (Bool, PHAsset?) -> Void = { [weak self] success, asset in
            guard success, let asset = asset else {
                PTGCDManager.shared.runOnMain {
                    let errorMsg = image != nil ? PTMediaLibUIConfig.share.saveImageError : PTMediaLibUIConfig.share.saveVideoError
                    PTAlertTipsViewController.tipsAlertShow(title: "Error",subtitle: errorMsg, icon: .Error)
                }
                return
            }
            PTGCDManager.shared.runOnMain { [weak self] in
                self?.handleNewAsset(asset)
            }
        }

        if let img = image {
            PHPhotoLibrary.pt.saveImageToAlbum(image: img, completion: completion)
        } else if let url = videoUrl {
            PTMediaLibManager.saveVideoToAlbum(url: url, completion: completion)
        }
    }

    /// 处理新生成的资源并插入到当前列表
    private func handleNewAsset(_ asset: PHAsset) {
        handleNewAssetCallback?(asset)
    }
}

