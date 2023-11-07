//
//  PTRouteViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

class PTRouterExampleModel:PTBaseModel {
    var foo:String = "1"
    var poo:String = "2"
}

typealias PTRouteHandler = (_ value:String) -> Void

class PTRouteViewController: PTBaseViewController {

    var viewModels:PTRouterExampleModel?
    var handle:PTRouteHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if viewModels != nil {
            PTNSLogConsole(">>>>>>>\(viewModels!.poo)")
        }
        
        PTGCDManager.gcdAfter(time: 2) {
            if self.handle != nil {
                self.handle!("OKOK")
            }
        }
    }
}

extension PTRouteViewController:PTRouterable {
    static var patternString: [String] {
        ["scheme://route/route"]
    }
    
    static func registerAction(info: [String : Any]) -> Any {
        PTNSLogConsole(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\(info)")
        let vc = PTRouteViewController()
        vc.viewModels = (info["model"] as? PTRouterExampleModel)
        vc.handle = info["task"] as? PTRouteHandler
        return vc
    }
    
}
