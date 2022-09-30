//
//  UIViewController+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

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
}

extension UIViewController:UIPopoverPresentationControllerDelegate
{
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
