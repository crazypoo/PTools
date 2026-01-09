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
import SafeSFSymbols

class PTDebugSnapshotViewController: PTBaseViewController {

    fileprivate var snapshotImage:UIImage!
    
    lazy var snapshotImageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.image = snapshotImage
        return view
    }()
    
    lazy var backButton:UIButton = {
        let button = baseButtonCreate(image: UIImage(.arrow.uturnLeftCircle))
        button.addActionHandlers { sender in
            self.navigationController?.popViewController()
        }
        return button
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
        setCustomBackButtonView(backButton)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([snapshotImageView])
        snapshotImageView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
        }
    }
}
