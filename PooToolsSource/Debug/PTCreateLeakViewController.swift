//
//  PTCreateLeakViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SafeSFSymbols

class PTCreateLeakViewController: PTBaseViewController {

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemOrange
        let triangleIMage:UIImage
        triangleIMage = UIImage(.drop.triangle)
        let imageView = UIImageView(image: triangleIMage)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        imageView.center = view.center
        imageView.tintColor = .black
        view.addSubview(imageView)
        
        let leakingObject = PTLeakClass()
        leakingObject.createLeak()
    }
}

class PTLeakClass {
    var closure:(()->Void)?
    
    init() {
        PTNSLogConsole("LeakingClass initialized")
    }
    
    deinit {
        PTNSLogConsole("LeakingClass deinitialized")
    }
    
    func createLeak() {
        closure = { [unowned self] in
            PTNSLogConsole("\(self) is causing a leak")
        }
    }
}
