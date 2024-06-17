//
//  PTDevColorPickerViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 15/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import ChromaColorPicker
import SnapKit
import SwifterSwift
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

class PTDevColorPickerViewController: PTBaseViewController {

    var colorSelectedTask:LocalConsoleTextColorTask?
    
    lazy var closeBtn :UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        view.addActionHandlers { sender in
            self.returnFrontVC()
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.size.equalTo(34)
            make.bottom.equalToSuperview().inset(5)
        }
#else
        closeBtn.frame = CGRectMake(0, 0, 34, 34)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeBtn)
#endif

        let lrCount = 16
        
        let colorPicker = ChromaColorPicker(frame: CGRectMake(0, 0, CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * CGFloat(lrCount), CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * CGFloat(lrCount)))
        colorPicker.translatesAutoresizingMaskIntoConstraints = false
        colorPicker.delegate = self
        let brightnessSlider = ChromaBrightnessSlider(frame: .zero)
        
        view.addSubviews([colorPicker,brightnessSlider])
        // Do any additional setup after loading the view.
        
        colorPicker.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace * CGFloat(lrCount / 2))
            make.height.equalTo(colorPicker.snp.width)
#if POOTOOLS_NAVBARCONTROLLER
                make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
                make.top.equalToSuperview()
#endif
        }
        
        brightnessSlider.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace * 2)
            make.height.equalTo(34)
            make.top.equalTo(colorPicker.snp.bottom).offset(10)
        }
        colorPicker.connect(brightnessSlider)
        let terTextColor = UIColor(hexString: PTCoreUserDefultsWrapper.LocalConsoleCurrentFontColor)!
        colorPicker.addHandle(at: terTextColor)
    }
}

extension PTDevColorPickerViewController:ChromaColorPickerDelegate {
    func colorPickerHandleDidChange(_ colorPicker: ChromaColorPicker, handle: ChromaColorHandle, to color: UIColor) {
        if colorSelectedTask != nil {
            colorSelectedTask!(color)
        }
    }
}
