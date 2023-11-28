//
//  PTFloatingBaseViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import FloatingPanel

open class PTFloatingBaseViewController: PTBaseViewController {

    open var viewScale:CGFloat = 0.5
    
    public var completion:PTActionTask?
    public var dismissCompletion:PTActionTask?

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if completion != nil {
            completion!()
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if dismissCompletion != nil {
            dismissCompletion!()
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }    
}

extension PTFloatingBaseViewController {
    open override func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        let layout = PTCustomControlScalePanelLayout()
        layout.viewHeight = CGFloat.kSCREEN_HEIGHT * viewScale
        return layout
    }
}
