//
//  PTSheetView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

class PTSheetView: UIView {
    
    var sheetPointHandler:((_ point:CGPoint,_ event:UIEvent?) -> Bool)?
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return self.sheetPointHandler?(point,event) ?? true
    }
}
#endif
