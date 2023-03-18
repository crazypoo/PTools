//
//  PTBaseMaskView.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 16/3/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import UIKit

@objcMembers
public class PTBaseMaskView: UIView {

    public var isMask : Bool = false

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        if self.isMask
        {
            return super.hitTest(point, with: event)
        }
        else
        {
            for view in self.subviews
            {
                if let responder : UIView = view.hitTest(view.convert(point, from: self), with: event)
                {
                    return responder
                }
            }
            return nil
        }
    }
}
