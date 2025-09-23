//
//  PTVideoEditorBaseFloatingViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

open class PTVideoEditorBaseFloatingViewController: PTBaseViewController {

    lazy var doneButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTVideoEditorConfig.share.doneImage, for: .normal)
        return view
    }()

    lazy var titleStack:PTLayoutButton = {
        let view = PTLayoutButton()
        view.layoutStyle = .leftImageRightTitle
        view.midSpacing = 10
        view.normalTitleColor = .foreground
        view.normalTitleFont = .appfont(size: 12)
        view.imageSize = CGSizeMake(20, 20)
        view.isUserInteractionEnabled = false
        view.normalTitle = viewControl.title
        view.normalImage = viewControl.titleImage
        return view
    }()

    fileprivate var viewControl:PTVideoEditorToolsModel!
    
    init(viewControl:PTVideoEditorToolsModel) {
        super.init(nibName: nil, bundle: nil)
        self.viewControl = viewControl
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true

    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
        view.addSubviews([titleStack,doneButton])
        
        titleStack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.height.equalTo(34)
            make.width.equalTo(100)
            make.centerX.equalToSuperview()
        }
        
        doneButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.size.equalTo(34)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + (CGFloat.kTabbarHeight - 34) / 2)
        }

    }
}
