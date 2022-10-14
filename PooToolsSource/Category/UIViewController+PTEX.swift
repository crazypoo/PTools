//
//  UIViewController+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import AVKit
import Photos
import Dispatch

// MARK: - 状态栏扩展
public extension UIViewController {
    
    /// 控制器的状态栏唯一键
    var statusBarKey: String {
        "\(self)"
    }
    
    /// 设置该控制器的状态栏状态
    func setStatusBar(isHidden: Bool? = nil, style: UIStatusBarStyle? = nil, animation: UIStatusBarAnimation? = nil) {
        StatusBarManager.shared.setState(for: statusBarKey, isHidden: isHidden, style: style, animation: animation)
    }
    
    /// 添加一个子状态
    func addSubStatusBar(for viewController: UIViewController) {
        let superKey = statusBarKey
        let subKey = viewController.statusBarKey
        StatusBarManager.shared.addSubState(with: subKey, root: superKey)
    }
    
    /// 批量添加子状态,树横向生长
    func addSubStatusBars(for viewControllers: [UIViewController]) {
        viewControllers.forEach { (vc) in
            addSubStatusBar(for: vc)
        }
    }
    
    /// 从整个状态树上删除当前状态
    func removeFromSuperStatusBar() {
        let key = statusBarKey
        StatusBarManager.shared.removeState(with: key)
    }
    
    /// 设置当前状态下的所有子状态
    func setSubStatusBars(for viewControllers: [UIViewController]?) {
        clearSubStatusBars()
        if let vcs = viewControllers {
            addSubStatusBars(for: vcs)
        }
    }
    
    /// 通过类似压栈的形式,压入一组状态,树纵向生长
    func pushStatusBars(for viewControllers: [UIViewController]) {
        var lastVC: UIViewController? = self
        viewControllers.forEach { (vc) in
            if let superController = lastVC {
                superController.addSubStatusBar(for: vc)
                lastVC = vc
            }
        }
    }
    
    /// 切换多个子状态的某个子状态
    func showStatusBar(for viewController: UIViewController?) {
        guard let vc = viewController else { return }
        let superKey = statusBarKey
        let subKey = vc.statusBarKey
        StatusBarManager.shared.showState(for: subKey, root: superKey)
    }
    
    /// 清楚所有子状态
    func clearSubStatusBars(isUpdate: Bool = true) {
        StatusBarManager.shared.clearSubStates(with: statusBarKey, isUpdate: isUpdate)
    }
    
    func checkVCIsPresenting() ->Bool
    {
        let vcs = self.navigationController?.viewControllers
        if (vcs?.count ?? 0) > 1
        {
            if vcs![vcs!.count - 1] == self
            {
                return false
            }
        }
        else
        {
            return true
        }
        return false
    }
    
    func viewDismiss(dismissBolck:(()->Void)? = nil)
    {
        if self.presentingViewController != nil
        {
            self.dismiss(animated: true) {
                if dismissBolck != nil
                {
                    dismissBolck!()
                }
            }
        }
        else
        {
            self.navigationController?.popViewController(animated: true) {
                if dismissBolck != nil
                {
                    dismissBolck!()
                }
            }
        }
    }
    
    func popToViewController(vcType:AnyClass) -> Bool {
        guard let childrens = self.navigationController?.children else { return false }
        for thisVC in childrens {
            if thisVC.isKind(of: vcType) {
                self.navigationController?.popToViewController(thisVC, animated: true)
                return true
            }
        }
        return false
    }

    @objc func popover(popoverVC:UIViewController,contentView:UIView,sender:UIButton,arrowDirections:UIPopoverArrowDirection)
    {
        PTUtils.gcdAfter(time: 0.1) {
            popoverVC.preferredContentSize = contentView.bounds.size
            popoverVC.modalPresentationStyle = .popover
            popoverVC.view.addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.edges.equalTo(popoverVC.view)
            }
            
            let presentationCtr = popoverVC.popoverPresentationController
            presentationCtr?.sourceView = sender
            presentationCtr?.sourceRect = sender.bounds
            presentationCtr?.permittedArrowDirections = arrowDirections
            presentationCtr?.delegate = self
            if (self.navigationController?.viewControllers.count ?? 0) > 0
            {
                self.navigationController?.present(popoverVC, animated: true)
            }
            else
            {
                self.present(popoverVC, animated: true)
            }
        }
    }
    
    /* .restricted     ---> 受限制，系统原因，无法访问
     * .notDetermined  ---> 系统还未知是否访问，第一次开启时
     * .authorized     ---> 允许、已授权
     * .denied         ---> 受限制，系统原因，无法访问
     */
    
    /// 定位权限
    func locationAuthorize() {
        DispatchQueue.main.async {
            PTUtils.base_alertVC(title:"打开定位开关",msg: "定位服务未开启,请进入系统设置>隐私>定位服务中打开开关,并允许App使用定位服务",okBtns: ["设置"],cancelBtn: "取消",showIn: PTUtils.getCurrentVC()) { index, title in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }
    
    /// 相机、麦克风权限
    func avCaptureDeviceAuthorize(avMediaType: AVMediaType) -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: avMediaType)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            // 请求授权
            AVCaptureDevice.requestAccess(for: avMediaType) { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        _ = self.avCaptureDeviceAuthorize(avMediaType: avMediaType)
                    }
                }
            }
            return false
        default:
            var title: String?
            var msg: String?
            switch avMediaType {
            case .video:
                title = "相机访问受限"
                msg = "请在iPhone的\"设置-隐私-相机\"中允许访问相机"
            case .audio:
                title = "麦克风访问受限"
                msg = "点击\"设置\"，允许访问您的麦克风"
            default:
                break
            }
            DispatchQueue.main.async {
                PTUtils.base_alertVC(title:title,msg: msg,okBtns: ["设置"],cancelBtn: "取消",showIn: PTUtils.getCurrentVC()) { index, title in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }
            }
            return false
        }
    }
    
    /// 相册权限
    func photoAuthorize() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            // 请求授权
            PHPhotoLibrary.requestAuthorization({ (status) in
                DispatchQueue.main.async {
                    _ = self.photoAuthorize()
                }
            })
            return false
        default:
            DispatchQueue.main.async {
                PTUtils.base_alertVC(title:"相册访问受限",msg: "请在iPhone的\"设置-隐私-相册\"中允许访问相册",okBtns: ["设置"],cancelBtn: "取消",showIn: PTUtils.getCurrentVC()) { index, title in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }

            }
            return false
        }
    }

}

extension UIViewController:UIPopoverPresentationControllerDelegate
{
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
