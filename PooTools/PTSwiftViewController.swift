//
//  PTSwiftViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/3.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

class PTSwiftViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        _ = PTCountryCodes.share.codesModels()
        
        self.view.backgroundColor = .random
        // Do any additional setup after loading the view.
    }
}
