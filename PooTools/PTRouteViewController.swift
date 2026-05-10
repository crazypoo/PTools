//
//  PTRouteViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

struct PTRouterExampleModel:PTRoutableParams {
    typealias Target = PTRouteViewController
    let foo:String
    let poo:String

    func toDictionary() -> [String : Any] {
        ["foo":foo,"poo":poo]
    }
}

typealias PTRouteHandler = (_ value:String) -> Void

class PTRouteViewController: PTBaseViewController,PTRoutableStaticController {
    typealias Params = PTRouterExampleModel

    var id = ""
    required init(routerParams: [String : Any]) {
        self.id = (routerParams["foo"] as? String) ?? ""
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var viewModels:PTRouterExampleModel?
    var handle:PTRouteHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if viewModels != nil {
            PTNSLogConsole(">>>>>>>\(viewModels!.poo)")
        }
        
        PTGCDManager.gcdAfter(time: 2) {
            self.handle?("OKOK")
        }
    }
}

extension PTRouteViewController:PTRouterable {
    
    static var priority: UInt {
        PTRouterDefaultPriority
    }
    
    static var patternString: [String] {
        ["ptools://routerTest"]
    }
}
