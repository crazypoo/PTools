//
//  PTTipsDemoController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 17/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import TipKit
import SnapKit

// MARK: - UIViewController
@available(iOS 17.0,*)
class PTTipsDemoController: PTBaseViewController {
    lazy var button: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        button.setTitle("显示Tip", for: .normal)
        button.center = view.center
        button.addTarget(self, action: #selector(showTip), for: .touchUpInside)
        return button
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Task.init {
            do {
                try? Tips.resetDatastore()
            }
        }
        //这里是用在测试模式下的,强制展示Tips
        Tips.showAllTipsForTesting()
        
        let shared = PTTip.shared
        shared.showTip(tips:TestTip(newId:"new", tipTitles: "2222222",messageTitles: "33333"),sender: button, content: self, actionHandler:  { action in
            if action.id == "id_more" {
                PTNSLogConsole("更多")
            } else if action.id == "id_dismiss" {
                PTNSLogConsole("关闭")
            }
        })
        
        shared.showTipsInView(tips:Test1Tip(),content: self) { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(100)
            make.centerY.equalToSuperview().inset(-100)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemTeal
        view.addSubview(button)

        Task {
            await TestTip.appOpenedCount.donate()
        }
    }

    func showTip() {
        TestTip.showTip = true
    }
}
