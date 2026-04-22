//
//  PTTabBarTestOneViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

class PTTabBarTestOneViewController: PTBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pt_Title = "11111111111111111"
        
        let buttons = UIButton(type: .custom)
        buttons.backgroundColor = .random
        buttons.addActionHandlers { sender in
            self.pt_Title = "2222222222222"
        }
        view.addSubviews([buttons])
        buttons.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(64)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
