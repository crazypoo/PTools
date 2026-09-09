//
//  PTBaseMaskView.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 16/3/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import UIKit

// English: The mask view owns UIKit hit-testing state and is MainActor isolated.
// Español: La vista de máscara posee estado de hit-testing de UIKit y está aislada en MainActor.
// 中文：遮罩视图持有 UIKit 命中测试状态，因此隔离到 MainActor。
@MainActor
@objcMembers
open class PTBaseMaskView: UIView {

    open var isMask : Bool = false
        
    public override func hitTest(_ point: CGPoint,
                                 with event: UIEvent?) -> UIView? {
        if isMask {
            return super.hitTest(point, with: event)
        } else {
            for view in subviews {
                if let responder : UIView = view.hitTest(view.convert(point, from: self), with: event) {
                    return responder
                }
            }
            return nil
        }
    }
}
