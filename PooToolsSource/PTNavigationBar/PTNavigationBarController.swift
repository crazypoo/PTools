//
//  PTNavigationBarController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 27/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

open class PTNavigationBarController: UIViewController {

    public var jx_navFixHeight:CGFloat = -1
    public var jx_navFixFrame:CGRect = .zero
    public var jx_navHistoryStackContentViewItemMaxLength:CGFloat = PTNavHistoryStackViewItemMaxLength
    public var jx_hideBaseNavBar:Bool = false
    public var jx_disableAutoSetCustomNavBar:Bool = false
    
    public lazy var jx_navBar:PTNavigationBar = {
        let view = PTNavigationBar()
        return view
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if navigationController != nil && !jx_hideBaseNavBar && !jx_disableAutoSetCustomNavBar {
            initNavBar()
            setAutoBack()
        }
        
        checkDoAutoSysBarAlpha()
        handleCustomPopGesture()
    }
    
    private func initNavBar() {
        view.addSubview(jx_navBar)
        view.bringSubviewToFront(jx_navBar)
        
        PTGCDManager.gcdAfter(time: 0.1) {
            self.view.bringSubviewToFront(self.jx_navBar)
        }
    }
    
    private func setAutoBack() {
        
    }
    
    private func checkDoAutoSysBarAlpha() {
        
    }
    
    private func handleCustomPopGesture() {
        
    }
    
    private func getCurrentNavHeight() ->CGFloat {
        if jx_navFixHeight == -1 {
            return CGFloat.statusBarHeight()
        }
        return jx_navFixHeight
    }
}
