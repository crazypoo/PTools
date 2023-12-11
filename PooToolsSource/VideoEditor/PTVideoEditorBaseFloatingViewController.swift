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
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

open class PTVideoEditorBaseFloatingViewController: PTFloatingBaseViewController {

    lazy var doneButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("✅".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        return view
    }()

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#else
        self.navigationController?.isNavigationBarHidden = true
#endif
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
        view.addSubviews([doneButton])
        
        doneButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.size.equalTo(34)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + (CGFloat.kTabbarHeight - 34) / 2)
        }

    }
}
