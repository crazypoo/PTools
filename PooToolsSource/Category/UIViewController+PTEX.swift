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
#if POOTOOLS_NOTIFICATIONBANNER
import NotificationBannerSwift
#endif

@objc public enum PTSheetPresentType:Int {
    case large
    case medium
    case custom
}

// MARK: - 状态栏扩展
public extension UIViewController {
    
    /**
        Indicate if controller is loaded and presented.
     */
    var isVisible: Bool {
        isViewLoaded && view.window != nil
    }
        
    var systemSafeAreaInsets: UIEdgeInsets {
        UIEdgeInsets(
                top: view.safeAreaInsets.top - additionalSafeAreaInsets.top,
                left: view.safeAreaInsets.left - additionalSafeAreaInsets.left,
                bottom: view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom,
                right: view.safeAreaInsets.right - additionalSafeAreaInsets.right
        )
    }
    
    func addChildWithView(_ childController: UIViewController, to containerView: UIView) {
        childController.willMove(toParent: self)
        addChild(childController)
        switch childController {
        case let collectionController as UICollectionViewController:
            containerView.addSubview(collectionController.collectionView)
        case let tableController as UITableViewController:
            containerView.addSubview(tableController.tableView)
        default:
            containerView.addSubview(childController.view)
        }
        childController.didMove(toParent: self)
    }

    //MARK: 控制器的状态栏唯一键
    /// 控制器的状态栏唯一键
    var statusBarKey: String {
        "\(self)"
    }
    
    //MARK: 设置该控制器的状态栏状态
    /// 设置该控制器的状态栏状态
    func setStatusBar(isHidden: Bool? = nil, 
                      style: UIStatusBarStyle? = nil,
                      animation: UIStatusBarAnimation? = nil) {
        StatusBarManager.shared.setState(for: statusBarKey, isHidden: isHidden, style: style, animation: animation)
    }
    
    //MARK: 添加一个子状态
    /// 添加一个子状态
    func addSubStatusBar(for viewController: UIViewController) {
        let superKey = statusBarKey
        let subKey = viewController.statusBarKey
        StatusBarManager.shared.addSubState(with: subKey, root: superKey)
    }
    
    //MARK: 批量添加子状态,树横向生长
    /// 批量添加子状态,树横向生长
    func addSubStatusBars(for viewControllers: [UIViewController]) {
        viewControllers.forEach { (vc) in
            addSubStatusBar(for: vc)
        }
    }
    
    //MARK: 从整个状态树上删除当前状态
    /// 从整个状态树上删除当前状态
    func removeFromSuperStatusBar() {
        let key = statusBarKey
        StatusBarManager.shared.removeState(with: key)
    }
    
    //MARK: 设置当前状态下的所有子状态
    /// 设置当前状态下的所有子状态
    func setSubStatusBars(for viewControllers: [UIViewController]?) {
        clearSubStatusBars()
        if let vcs = viewControllers {
            addSubStatusBars(for: vcs)
        }
    }
    
    //MARK: 通过类似压栈的形式,压入一组状态,树纵向生长
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
    
    //MARK: 切换多个子状态的某个子状态
    /// 切换多个子状态的某个子状态
    func showStatusBar(for viewController: UIViewController?) {
        guard let vc = viewController else { return }
        let superKey = statusBarKey
        let subKey = vc.statusBarKey
        StatusBarManager.shared.showState(for: subKey, root: superKey)
    }
    
    //MARK: 清楚所有子状态
    /// 清楚所有子状态
    func clearSubStatusBars(isUpdate: Bool = true) {
        StatusBarManager.shared.clearSubStates(with: statusBarKey, isUpdate: isUpdate)
    }
    
    //MARK: 檢查當前的ViewController是Push還是Pop
    ///檢查當前的ViewController是Push還是Pop
    func checkVCIsPresenting() ->Bool {
        let vcs = navigationController?.viewControllers
        if (vcs?.count ?? 0) > 1 {
            if vcs![vcs!.count - 1] == self {
                return false
            }
        } else {
            return true
        }
        return false
    }
    
    //MARK: ViewController退出
    ///ViewController退出
    func viewDismiss(dismissBolck:PTActionTask? = nil) {
        if presentingViewController != nil {
            dismiss(animated: true) {
                if dismissBolck != nil {
                    dismissBolck!()
                }
            }
        } else {
            navigationController?.popViewController(animated: true) {
                if dismissBolck != nil {
                    dismissBolck!()
                }
            }
        }
    }
    
    //MARK: Pop to ViewController
    ///Pop to ViewController
    func popToViewController(vcType:AnyClass) -> Bool {
        guard let childrens = navigationController?.children else { return false }
        for thisVC in childrens {
            if thisVC.isKind(of: vcType) {
                navigationController?.popToViewController(thisVC, animated: true)
                return true
            }
        }
        return false
    }
    
    //MARK: Popover
    ///Popover
    @objc func popover(popoverVC:UIViewController,
                       popoverSize:CGSize,
                       sender:UIButton,
                       arrowDirections:UIPopoverArrowDirection) {
        PTGCDManager.gcdAfter(time: 0.1) {
            popoverVC.preferredContentSize = popoverSize
            popoverVC.modalPresentationStyle = .popover
            
            let presentationCtr = popoverVC.popoverPresentationController
            presentationCtr?.sourceView = sender
            presentationCtr?.sourceRect = sender.bounds
            presentationCtr?.permittedArrowDirections = arrowDirections
            presentationCtr?.delegate = self
            if (self.navigationController?.viewControllers.count ?? 0) > 0 {
                self.navigationController?.present(popoverVC, animated: true)
            } else {
                self.present(popoverVC, animated: true)
            }
        }
    }
    
    @objc func listPopover(popoverConfig:PTPopoverConfig = PTPopoverConfig(),
                           items:[PTPopoverItem],
                           popoverWidth:CGFloat,
                           sender:UIButton,
                           arrowDirections:UIPopoverArrowDirection,
                           selectedHandler:@escaping PTPopoverHandler) {
        let popoverVC = PTPopoverMenuContent(config:popoverConfig,viewModel: items)
        popoverVC.didSelectedHandler = selectedHandler
        let popoverSize = CGSize(width: popoverWidth, height: CGFloat(items.count) * popoverConfig.rowHeight)
        popoverVC.preferredContentSize = popoverSize
        popoverVC.modalPresentationStyle = .popover
        // 在需要显示的地方使用 popoverPresentationController 来 present
        let presentationCtr = popoverVC.popoverPresentationController
        presentationCtr?.sourceView = sender
        presentationCtr?.sourceRect = sender.bounds
        presentationCtr?.permittedArrowDirections = arrowDirections
        presentationCtr?.delegate = self
        presentationCtr?.backgroundColor = popoverConfig.backgroundColor
        if (self.navigationController?.viewControllers.count ?? 0) > 0 {
            self.navigationController?.present(popoverVC, animated: true)
        } else {
            self.present(popoverVC, animated: true)
        }
    }
    
    /* .restricted     ---> 受限制，系统原因，无法访问
     * .notDetermined  ---> 系统还未知是否访问，第一次开启时
     * .authorized     ---> 允许、已授权
     * .denied         ---> 受限制，系统原因，无法访问
     */
    
    //MARK: 定位权限
    /// 定位权限
    func locationAuthorize() {
        PTGCDManager.gcdMain {
            UIAlertController.base_alertVC(title:String.LocationAuthorizationFail,msg: String.authorizationSet(type: PTPermission.Kind.location(access: .whenInUse)),okBtns: ["PT Setting".localized()],cancelBtn: "PT Button cancel".localized(),moreBtn: { index, title in
                PTOpenSystemFunction.openSystemFunction(config:  PTOpenSystemConfig())
            })
        }
    }
    
    //MARK: 相机、麦克风权限
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
                    PTGCDManager.gcdMain {
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
                title = String.CameraAuthorizationFail
                msg = String.authorizationSet(type: PTPermission.Kind.camera)
            case .audio:
                title = String.MicAuthorizationFail
                msg = String.authorizationSet(type: PTPermission.Kind.microphone)
            default:
                break
            }
            PTGCDManager.gcdMain {
                UIAlertController.base_alertVC(title:title,msg: msg,okBtns: ["PT Setting".localized()],cancelBtn: "PT Button cancel".localized(),moreBtn: { index, title in
                    PTOpenSystemFunction.openSystemFunction(config:  PTOpenSystemConfig())
                })
            }
            return false
        }
    }
    
    //MARK: 相册权限
    /// 相册权限
    func photoAuthorize() -> Bool {
        
        switch PTPermission.photoLibrary.status {
        case .authorized:
            return true
        case .notDetermined:
            PTPermission.photoLibrary.request {
                _ = self.photoAuthorize()
            }
            return false
        default:
            PTGCDManager.gcdMain {
                UIAlertController.base_alertVC(title:String.PhotoAuthorizationFail,msg: String.authorizationSet(type: PTPermission.Kind.photoLibrary),okBtns: ["PT Setting".localized()],cancelBtn: "PT Button cancel".localized(),moreBtn: { index,title in
                    PTOpenSystemFunction.openSystemFunction(config:  PTOpenSystemConfig())
                })
            }
            return false
        }
    }

    //MARK: 弹出框
    /// - Parameters:
    ///   - title: 标题
    ///   - titleFont: 标题字号
    ///   - titleColor: 字体颜色
    ///   - subTitle: 子标题
    ///   - subTitleFont: 子标题字号
    ///   - subTitleColor: 子标题颜色
    ///   - duration: 点击回调
    ///   - bannerBackgroundColor: 背景颜色
    ///   - notifiTap: 点击回调
    ///   - notifiDismiss:
    @objc class func gobal_drop(title:String?,
                                titleFont:UIFont? = UIFont.appfont(size: 16),
                                titleColor:UIColor? = .black,
                                subTitle:String? = nil,
                                subTitleFont:UIFont? = UIFont.appfont(size: 16),
                                subTitleColor:UIColor? = .black,
                                duration:CGFloat = 1.5,
                                bannerBackgroundColor:UIColor? = .white,
                                notifiTap:PTActionTask? = nil,
                                notifiDismiss:PTActionTask? = nil) {
        var titleStr = ""
        if title == nil || (title ?? "").stringIsEmpty() {
            titleStr = ""
        } else {
            titleStr = title!
        }

        var subTitleStr = ""
        if subTitle == nil || (subTitle ?? "").stringIsEmpty() {
            subTitleStr = ""
        } else {
            subTitleStr = subTitle!
        }
#if POOTOOLS_NOTIFICATIONBANNER
        let banner = FloatingNotificationBanner(title:titleStr,subtitle: subTitleStr)
        banner.duration = duration
        banner.backgroundColor = bannerBackgroundColor!
        banner.subtitleLabel?.textAlignment = UIView.sizeFor(string: subTitleStr, font: subTitleFont!, height:44).width > (CGFloat.kSCREEN_WIDTH - 36) ? .left : .center
        banner.subtitleLabel?.font = subTitleFont
        banner.subtitleLabel?.textColor = subTitleColor!
        banner.titleLabel?.textAlignment = UIView.sizeFor(string: titleStr, font: titleFont!, height:44).width > (CGFloat.kSCREEN_WIDTH - 36) ? .left : .center
        banner.titleLabel?.font = titleFont
        banner.titleLabel?.textColor = titleColor!
        banner.show(queuePosition: .front, bannerPosition: .top ,cornerRadius: 15)
        banner.onTap = {
            if notifiTap != nil {
                notifiTap!()
            }
        }
        PTGCDManager.gcdAfter(time: duration) {
            if notifiDismiss != nil {
                notifiDismiss!()
            }
        }
#else
        UIAlertController.base_alertVC(title: titleStr,titleColor: titleColor,titleFont: titleFont,msg: subTitleStr,msgColor: subTitleColor,msgFont: subTitleFont,cancelBtn: "PT Button comfirm".localized()) {
            if notifiDismiss != nil {
                notifiDismiss!()
            }
        }
#endif
    }
    
    @available(iOS 13, tvOS 13, *)
    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    func destruct(scene name: String) {
        guard let session = view.window?.windowScene?.session else {
            dismissAnimated()
            return
        }
        if session.configuration.name == name {
            UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
        } else {
            dismissAnimated()
        }
    }
    
    @objc func dismissAnimated() {
        dismiss(animated: true, completion: nil)
    }

    
    #if os(iOS)
    var closeBarButtonItem: UIBarButtonItem {
        if #available(iOS 14.0, *) {
            return UIBarButtonItem.init(systemItem: .close, primaryAction: .init(handler: { [weak self] (action) in
                self?.dismissAnimated()
            }), menu: nil)
        } else {
            return UIBarButtonItem.init(barButtonSystemItem: .close, target: self, action: #selector(self.dismissAnimated))
        }
    }
    
    @available(iOS 14, *)
    @available(iOSApplicationExtension, unavailable)
    func closeBarButtonItem(sceneName: String? = nil) -> UIBarButtonItem {
        UIBarButtonItem.init(systemItem: .close, primaryAction: .init(handler: { [weak self] (action) in
            guard let self = self else {
                return
            }
            if let name = sceneName {
                self.destruct(scene: name)
            } else {
                self.dismissAnimated()
            }
        }), menu: nil)
    }
    #endif

    //MARK: 增加了当点击需要隐藏键盘时观察的手势。应该添加下面的使用视图，如文本字段。
    func dismissKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboardTappedAround(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboardTappedAround(_ gestureRecognizer: UIPanGestureRecognizer) {
        dismissKeyboard()
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func pt_present(_ vc:UIViewController,animated:Bool? = true,completion:(()->Void)? = nil) {

#if POOTOOLS_DEBUG
        present(vc, animated: animated!) {
            if completion != nil {
                completion!()
            }
            let share = LocalConsole.shared
            if share.isVisiable {
                SwizzleTool().swizzleDidAddSubview {
                    // Configure console window.
                    if share.maskView != nil {
                        PTUtils.fetchWindow()?.bringSubviewToFront(share.maskView!)
                    }
                    PTUtils.fetchWindow()?.bringSubviewToFront(share.terminal!)
                }
            }
        }
#else
        present(vc, animated: animated!, completion:completion)
#endif
    }
    
    @available(iOS 15.0,*)
    func sheetPresent(modalViewController:UIViewController,type:PTSheetPresentType,@PTClampedProperyWrapper(range:0.2...1) scale:CGFloat,completion:PTActionTask?) {
        if let sheet = modalViewController.sheetPresentationController {
            // 支持的自定义显示大小
            switch type {
            case .large:
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            case .medium:
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            case .custom:
                if #available(iOS 16.0, *) {
                    let small = UISheetPresentationController.Detent.Identifier("small")
                    sheet.detents = [
                        .custom(identifier: small) { context in
                            scale * context.maximumDetentValue
                        }
                    ]
                    sheet.largestUndimmedDetentIdentifier = small
                    sheet.prefersGrabberVisible = true
                } else {
                    sheet.detents = [.large()]
                    sheet.prefersGrabberVisible = true
                }
            }
        }
        present(modalViewController, animated: true,completion: completion)
    }
    
#if POOTOOLS_FLOATINGPANEL
    func sheetPresent_floating(modalViewController:PTFloatingBaseViewController,type:PTSheetPresentType,@PTClampedProperyWrapper(range:0.2...1) scale:CGFloat,panGesDelegate:(UIViewController & UIGestureRecognizerDelegate)? = PTUtils.getCurrentVC() as! PTBaseViewController,completion:PTActionTask?,dismissCompletion:PTActionTask?) {
        if #available(iOS 15.0, *) {
            modalViewController.dismissCompletion = dismissCompletion
            sheetPresent(modalViewController: modalViewController, type: type, scale: scale, completion: completion)
        } else {
            switch type {
            case .large:
                modalViewController.viewScale = 0.9
            case .medium:
                modalViewController.viewScale = 0.5
            case .custom:
                modalViewController.viewScale = scale
            }
            modalViewController.completion = completion
            PTFloatingPanelFuction.floatPanel_VC(vc: modalViewController,panGesDelegate: panGesDelegate,currentViewController: self,floatingDismiss: dismissCompletion)
        }
    }
#endif
}

extension UIViewController:UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }
}

extension UIViewController {
    public func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        if let vc = PTUtils.getCurrentVC() as? PTPopoverMenuContent {
            vc.arrowDirections = popoverPresentationController.arrowDirection
        }
    }
}
