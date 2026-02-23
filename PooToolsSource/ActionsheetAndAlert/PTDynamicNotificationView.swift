//
//  PTDynamicNotificationView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import pop
import DeviceKit

public class PTDynamicNotificationView: UIView {

    public var hideHandler:PTActionTask?
    
    let contentHeight:CGFloat = 160
    private lazy var cameraArea:UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var contentViews:UIView = {
        let view = UIView()
        return view
    }()
    
    fileprivate var showTime:TimeInterval = 3
    fileprivate var canTap:Bool = true

    public init(showTimes:TimeInterval = 3,canTap:Bool = true,content:((UIView) -> Void)) {
        super.init(frame: .zero)
        self.showTime = showTimes
        self.canTap = canTap
        
        backgroundColor = PTDarkModeOption.colorLightDark(lightColor: .white, darkColor: .Black25PercentColor)
        viewCorner(radius: 15)
        
        if let windows = AppWindows {
            addSubviews([cameraArea,contentViews])
            cameraArea.snp.makeConstraints { make in
                make.width.equalTo(CGFloat.ScaleW(w: 104))
                make.height.equalTo(CGFloat.ScaleW(w: 36.67))
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
            }
            
            contentViews.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(self.cameraArea.snp.bottom)
            }
            
            content(contentViews)
            windows.addSubviews([self])
            self.snp.makeConstraints { make in
                make.width.equalTo(CGFloat.ScaleW(w: 371))
                make.height.equalTo(contentHeight)
                make.centerX.equalToSuperview()

                if Gobal_device_info.isOneOf([.iPhone14Pro,.iPhone14ProMax,.iPhone15,.iPhone15Pro,.iPhone15ProMax,.iPhone15Plus,.iPhone16,.iPhone16e,.iPhone16Pro,.iPhone16ProMax,.iPhone16Plus,.iPhone17,.iPhone17Pro,.iPhone17ProMax]) {
                    make.top.equalToSuperview().inset(10)
                } else if Gobal_device_info.isOneOf([.iPhoneX, .iPhoneXS, .iPhoneXSMax, .iPhoneXR, .iPhone11, .iPhone11Pro, .iPhone11ProMax, .iPhone12, .iPhone12Mini, .iPhone12Pro, .iPhone12ProMax, .iPhone13, .iPhone13Mini, .iPhone13Pro, .iPhone13ProMax, .iPhone14, .iPhone14Plus]) {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
                }
            }
        }
        
        if canTap {
            let tap = UITapGestureRecognizer { _ in
                self.hideNotification()
            }
            addGestureRecognizer(tap)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    
    
    public func showNotification() {
        PTAnimationFunction.animationIn(animationView: self, animationType: .Top, transformValue: contentHeight)
        PTGCDManager.gcdAfter(time: showTime) {
            self.hideNotification()
        }
    }
    
    public func hideNotification() {
        PTAnimationFunction.animationOut(animationView: self, animationType: .Top,toValue: -(self.contentHeight + 10)) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
            self.hideHandler?()
        }
    }
}
