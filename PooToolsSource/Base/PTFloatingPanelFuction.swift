//
//  PTFloatingPanelFuction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import FloatingPanel

public typealias FloatingBlock = () -> Void

public class PTFloatingPanelFuction: NSObject {
    class open func floatPanel_VC(vc:PTBaseViewController,panGesDelegate:(UIViewController & UIGestureRecognizerDelegate)? = PTUtils.getCurrentVC() as! PTBaseViewController,floatingDismiss:FloatingBlock? = nil)
    {
        let fpc = FloatingPanelController()
        fpc.set(contentViewController: vc)
        fpc.contentMode = .fitToBounds
        fpc.contentInsetAdjustmentBehavior = .never
        fpc.isRemovalInteractionEnabled = true
        fpc.panGestureRecognizer.isEnabled = true
        fpc.panGestureRecognizer.delegateProxy = panGesDelegate
        fpc.surfaceView.backgroundColor = .randomColor
        
        let backDropDismiss = UITapGestureRecognizer.init { action in
            vc.dismiss(animated: true)
            if floatingDismiss != nil
            {
                floatingDismiss!()
            }
        }
        fpc.backdropView.addGestureRecognizer(backDropDismiss)

        // Create a new appearance.
        let appearance = SurfaceAppearance()
        
        // Define shadows
        let shadow = SurfaceAppearance.Shadow()
        shadow.color = UIColor.black
        shadow.offset = CGSize(width: 0, height: 16)
        shadow.radius = 16
        shadow.spread = 8
        appearance.shadows = [shadow]

        // Define corner radius and background color
        appearance.cornerRadius = 8.0
        appearance.backgroundColor = .white

        
        // Set the new appearance
        fpc.surfaceView.appearance = appearance
        fpc.delegate = vc
        (PTUtils.getCurrentVC() as? PTBaseViewController)?.present(fpc, animated: true) {
            if floatingDismiss != nil
            {
                floatingDismiss!()
            }
        }
    }
}
