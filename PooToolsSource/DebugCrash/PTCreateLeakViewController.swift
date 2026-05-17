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

@MainActor
class PTLeakClass {
    var closure: PTActionTask?
    
    init() {
        PTNSLogConsole("LeakingClass initialized")
    }
    
    // 🌟 注意：在 Swift 6 中，deinit 默认是 nonisolated（非隔离的）。
    // 这里只做简单的打印是安全的，但不要在这里去读取或修改 @MainActor 隔离的 var 属性。
    deinit {
        PTNSLogConsole("LeakingClass deinitialized")
    }
    
    func createLeak() {
        // 🌟 修复 2：将 [unowned self] 改为安全的 [weak self]
        // 🌟 修复 3：因为类标记了 @MainActor，这个闭包会自动推断为 @MainActor，完美匹配 PTActionTask
        closure = { [weak self] in
            // 安全解包：如果 self 已经被释放，直接 return，防止崩溃
            guard let self = self else {
                PTNSLogConsole("对象已被释放，闭包安全退出")
                return
            }
            PTNSLogConsole("\(self) is executing safely")
        }
    }
}
