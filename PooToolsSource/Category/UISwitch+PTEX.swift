//
//  UISwitch+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/15.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public typealias SwitchBlock = (_ sender:UISwitch) -> Void

public extension UISwitch {    
    @objc func addSwitchAction(handler:@escaping SwitchBlock) {
        self.addActionHandler(for: .valueChanged, handler: handler)
    }
}
