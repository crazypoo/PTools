//
//  PTTabBarTestOneViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

class PTTabBarTestOneViewController: PTBaseViewController {

    private lazy var customToolView: UIView = {
        let view = UIView()
        // ⚠️ 重点：务必保持透明，让底层的 TabBar 容器毛玻璃透过来
        view.backgroundColor = .clear
        
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal // 推荐使用 minimal 样式与毛玻璃更配
        searchBar.placeholder = "搜索..."
        
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            // 自动垂直居中填满父容器即可
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(12)
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.pt_tabBarAccessoryView = customToolView

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
