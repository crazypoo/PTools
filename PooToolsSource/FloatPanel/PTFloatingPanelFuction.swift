//
//  PTFloatingPanelFuction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import FloatingPanel

public class PTFloatingPanelFuction: NSObject {
    
    //MARK: 初始化創建FloatPanel
    ///初始化創建FloatPanel
    /// - Parameters:
    ///   - vc: 须要显示的ViewController
    ///   - panGesDelegate: 触摸协议
    ///   - currentViewController: 准备跳转前的当前界面
    ///   - fpcContentMode: FPC的contentMode(默认fitToBounds)
    ///   - fpcContentInsetAdjustmentBehavior: FPC的content界面纠正模式(默认never)
    ///   - fpcIsRemovalInteractionEnabled: FPC的交互开关(默认开)
    ///   - fpcPanGestureRecognizer: FPC的Pan交互开关(默认开)
    ///   - fpcSurfaceShadowSize: FPC的SurfaceShadow大小
    ///   - fpcSurfaceShadowColor: FPC的SurfaceShadow颜色
    ///   - fpcSurfaceAppearanceRadius: FPC的SurfaceShadow圆角
    ///   - fpcSurfaceBackgroundColor: FPC的背景颜色
    ///   - floatingDismiss: FPC的关闭回调
    class open func floatPanel_VC(vc:PTBaseViewController,
                                  panGesDelegate:(UIViewController & UIGestureRecognizerDelegate)? = PTUtils.getCurrentVC() as! PTBaseViewController,
                                  currentViewController:UIViewController? = PTUtils.getCurrentVC(),
                                  fpcContentMode:FloatingPanelController.ContentMode = .fitToBounds,
                                  fpcContentInsetAdjustmentBehavior:FloatingPanelController.ContentInsetAdjustmentBehavior = .never,
                                  fpcIsRemovalInteractionEnabled:Bool = true,
                                  fpcPanGestureRecognizer:Bool = true,
                                  fpcSurfaceShadowSize:CGSize = CGSize(width: 0, height: 16),
                                  fpcSurfaceShadowColor:UIColor = .black,
                                  fpcSurfaceAppearanceRadius:CGFloat = 8,
                                  fpcSurfaceBackgroundColor:UIColor = .white,
                                  floatingDismiss:PTActionTask? = nil) {
        let fpc = FloatingPanelController()
        fpc.set(contentViewController: vc)
        fpc.contentMode = fpcContentMode
        fpc.contentInsetAdjustmentBehavior = fpcContentInsetAdjustmentBehavior
        fpc.isRemovalInteractionEnabled = fpcIsRemovalInteractionEnabled
        fpc.panGestureRecognizer.isEnabled = fpcPanGestureRecognizer
        fpc.panGestureRecognizer.delegateProxy = panGesDelegate
        
        let backDropDismiss = UITapGestureRecognizer.init { action in
            vc.dismiss(animated: true)
            if floatingDismiss != nil {
                floatingDismiss!()
            }
        }
        fpc.backdropView.addGestureRecognizer(backDropDismiss)

        // Create a new appearance.
        let appearance = SurfaceAppearance()
        
        // Define shadows
        let shadow = SurfaceAppearance.Shadow()
        shadow.color = fpcSurfaceShadowColor
        shadow.offset = fpcSurfaceShadowSize
        shadow.radius = fpcSurfaceShadowSize.height
        shadow.spread = fpcSurfaceShadowSize.height / 2
        appearance.shadows = [shadow]

        // Define corner radius and background color
        appearance.cornerRadius = fpcSurfaceAppearanceRadius
        appearance.backgroundColor = fpcSurfaceBackgroundColor

        // Set the new appearance
        fpc.surfaceView.appearance = appearance
        fpc.delegate = vc
        currentViewController!.present(fpc, animated: true)
    }
}
