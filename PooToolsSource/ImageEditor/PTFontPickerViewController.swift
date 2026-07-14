//
//  PTFontPickerViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/7/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

public class PTFontPickerViewController: PTBaseViewController {

    open override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }

    public lazy var picker:UIFontPickerViewController = {
        let config = UIFontPickerViewController.Configuration()
        config.includeFaces = true // 允许选择字体的具体字重 (如 Light, Black 等)
        config.displayUsingSystemFont = false // 强制使用字体原本的样貌展示列表
        
        let fontPicker = UIFontPickerViewController(configuration: config)
        fontPicker.delegate = self
        return fontPicker
    }()

    public var selectedFontCallback:((UIFont)->Void)?
    public var viewDismiss:PTActionTask?
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTGCDManager.shared.delayOnMain(time: 0.2) {
            self.changeStatusBar(type: .Dark)
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewDismiss?()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupPicker()
    }

    private func setupPicker() {
        addChild(picker)
        view.addSubview(picker.view)

        picker.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        picker.didMove(toParent: self)
    }
}

extension PTFontPickerViewController: UIFontPickerViewControllerDelegate {
    
    public func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let descriptor = viewController.selectedFontDescriptor else { return }
        
        let newFont = UIFont(descriptor: descriptor, size: PTTextStickerView.fontSize)
        
        self.selectedFontCallback?(newFont)
        self.closeFontPicker()
    }
    
    public func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) {
        self.closeFontPicker()
    }
    
    // 统一处理退出逻辑
    private func closeFontPicker() {
        if self.checkVCIsPresenting() {
            self.dismissAnimated()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
