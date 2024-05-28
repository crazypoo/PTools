//
//  PTDebugSnapshotViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SafeSFSymbols

class PTDebugSnapshotViewController: PTBaseViewController {

    fileprivate var snapshotImage:UIImage!
    
    lazy var fakeNav : UIView = {
        let view = UIView()
        return view
    }()

    lazy var snapshotImageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.image = snapshotImage
        return view
    }()
    
    init(snapshotImage: UIImage!) {
        self.snapshotImage = snapshotImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#else
        navigationController?.navigationBar.isHidden = true
#endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([fakeNav,snapshotImageView])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight)
            make.top.equalTo(20)
        }
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        fakeNav.addSubviews([button])
        button.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        button.addActionHandlers { sender in
            self.navigationController?.popViewController()
        }
        
        snapshotImageView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
    }
}
