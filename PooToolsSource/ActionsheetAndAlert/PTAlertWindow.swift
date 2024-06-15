//
//  PTAlertWindow.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTAlertWindow: UIWindow {
    public var allowsEventPenetration = false

    public var autoHideWhenPenetrated = false

    public var rootPopoverController: PTAlertProtocol? {
        rootViewController as? PTAlertProtocol
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        guard view == rootViewController?.view else { return view }

        guard allowsEventPenetration else { return view }

        autoHideWhenPenetrated ? (rootViewController as? (PTAlertController & PTAlertProtocol))?.dismissAnimation(completion: nil) : ()

        return nil
    }

}
