//
//  PTColorPickerContainerViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 12/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

open class PTColorPickerContainerViewController: PTBaseViewController {

    public let picker = UIColorPickerViewController()

    public var selectedColorCallback:((UIColor)->Void)?
    
    public lazy var backButton:UIButton = {
        let colorPickerBack = UIButton(type: .custom)
        colorPickerBack.bounds = CGRectMake(0, 0, 34, 34)
        colorPickerBack.addActionHandlers { sender in
            if self.checkVCIsPresenting() {
                self.dismissAnimated()
            } else {
                self.navigationController?.popViewController()
            }
        }
        return colorPickerBack
    }()
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(backButton)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupPicker()
    }

    private func setupPicker() {
        picker.delegate = self
        picker.supportsAlpha = true

        addChild(picker)
        view.addSubview(picker.view)

        picker.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        picker.didMove(toParent: self)
    }
}

extension PTColorPickerContainerViewController: UIColorPickerViewControllerDelegate {
    public func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        selectedColorCallback?(color)
    }
}
