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
//        view.backgroundColor = .systemGray
        view.borderGradient(type: .LeftToRight, colors: [.systemRed,.systemBlue],radius: 20,borderWidth: 20,corner: [.bottomLeft,.bottomRight])
        view.addActionHandlers { sender in
            self.sideMenuController?.hideMenu(animated: true, completion: { finish in
                if finish {
                    let vc = PTBaseViewController()
                    vc.view.backgroundColor = .systemBlue
                    let button = UIButton(type: .custom)
                    button.backgroundColor = .systemGray
                    vc.view.addSubviews([button])
                    button.snp.makeConstraints { make in
                        make.size.equalTo(150)
                        make.centerX.centerY.equalToSuperview()
                    }
                    button.addActionHandlers { sender in
                        let vcs = PTBaseViewController()
                        vc.navigationController?.pushViewController(vcs)
                    }
                    
                    let nav = PTBaseNavControl(rootViewController: vc)
                    self.currentPresentToSheet(vc: nav,sizes: [.percent(0.5),.fullscreen])
                }
            })
        }
        return view
    }()
    
    lazy var checkBox:PTCheckBox = {
        let view = PTCheckBox()
        view.checkmarkStyle = .Circle
        view.borderStyle = .Circle
        view.boxBorderWidth = 5
        view.checkmarkSize = 0.5
        return view
    }()
    
    lazy var inspectorButton:UIButton = {
        let view = UIButton(type: .custom)
        view.backgroundColor = .random
        view.addActionHandlers { sender in
            Inspector.sharedInstance.present(animated: true)
        }
        return view
    }()
    
    lazy var lcButton:UIButton = {
        let view = UIButton(type:.custom)
        view.backgroundColor = .random
        view.addActionHandlers { sender in
            PTCoreUserDefultsWrapper.AppDebugMode.toggle()
            let lc = LocalConsole.shared
            lc.isVisiable = PTCoreUserDefultsWrapper.AppDebugMode
        }
        return view
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([sideInfoLabel,sideButton,checkBox,inspectorButton,lcButton])
        sideInfoLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }     
        
        sideButton.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.top.equalTo(self.sideInfoLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        
        checkBox.snp.makeConstraints { make in
            make.top.equalTo(self.sideButton.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.height.width.equalTo(34)
        }
        
        inspectorButton.snp.makeConstraints { make in
            make.left.right.equalTo(self.sideButton)
            make.top.equalTo(self.checkBox.snp.bottom).offset(10)
            make.height.equalTo(34)
        }
        
        lcButton.snp.makeConstraints { make in
            make.size.centerX.equalTo(self.inspectorButton)
            make.top.equalTo(self.inspectorButton.snp.bottom).offset(10)
        }
    }
}
