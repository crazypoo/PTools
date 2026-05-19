//
//  PTTestLoginViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/5/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

public struct PTEmptyParams<VC: UIViewController>: PTRoutableParams {
    public typealias Target = VC
    
    public init() {}
    
    public func toDictionary() -> [String: any Sendable] {
        return [:] // 无参，返回空字典
    }
}

class PTTestLoginViewController: PTBaseViewController,@MainActor PTRoutableStaticController {
    typealias Params = PTEmptyParams<PTTestLoginViewController>
    
    required init(routerParams: [String : Sendable]) {
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

extension PTTestLoginViewController:@MainActor PTRouterable {
    
    static var priority: UInt {
        PTRouterDefaultPriority
    }
    
    static var patternString: [String] {
        ["ptools://login"]
    }
}
