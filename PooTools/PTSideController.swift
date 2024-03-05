//
//  PTSideController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit

class PTSideController: PTBaseSideController {

    lazy var sideInfoLabel:UILabel = {
        let view = UILabel()
        view.font = .appfont(size: 25)
        view.text = "Side Control"
        view.textColor = .randomColor
        view.textAlignment = .center
        return view
    }()
    
    lazy var sideButton:UIButton = {
        let view = UIButton(type: .custom)
        view.backgroundColor = .randomColor
        view.addActionHandlers { sender in
            self.sideMenuController?.hideMenu(animated: true, completion: { finish in
                if finish {
                    let vc = PTBaseViewController()
                    vc.view.backgroundColor = .systemBlue
                    let button = UIButton(type: .custom)
                    button.backgroundColor = .systemGray
                    vc.view.addSubviews([button])
                    button.snp.makeConstraints { make in
                        make.size.equalTo(100)
                        make.centerX.centerY.equalToSuperview()
                    }
                    button.addActionHandlers { sender in
                        let vcs = PTBaseViewController()
                        vc.navigationController?.pushViewController(vcs)
                    }
                    
                    let nav = PTBaseNavControl(rootViewController: vc)
                    let sheet = PTSheetViewController(controller: nav,sizes: [.percent(0.5),.fullscreen])
                    PTUtils.getCurrentVC().present(sheet, animated: true)
//                    let vc = PTFuncDetailViewController(typeString: String.sortButton)
//                    PTFloatingPanelFuction.floatPanel_VC(vc: vc,panGesDelegate: PTUtils.getCurrentVC() as! PTBaseViewController,currentViewController: PTUtils.getCurrentVC())
                }
            })
        }
        return view
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([sideInfoLabel,sideButton])
        sideInfoLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }     
        
        sideButton.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.top.equalTo(self.sideInfoLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
    }
}
