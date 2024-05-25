//
//  PTDevMaskView.swift
//  Diou
//
//  Created by ken lam on 2021/10/22.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import DeviceKit

@objcMembers
public class PTDevMaskConfig:NSObject {
    open var isMask:Bool = false
    open var maskString:String = "PT Debug mode".localized()
    open var maskFont:UIFont = .appfont(size: 100,bold: true)
    open var motionColor:UIColor = .randomColor
    open var showTouch:Bool = PTCoreUserDefultsWrapper.AppDebbugTouchBubble
}

@objcMembers
public class PTDevMaskView: PTBaseMaskView {

    open var showTouch:Bool? {
        didSet {
            viewConfig.showTouch = showTouch!
        }
    }
    
    private var viewConfig : PTDevMaskConfig = PTDevMaskConfig()
    
    private lazy var springMotionView: SpringMotionView = {
        let view = SpringMotionView()
        view.backgroundColor = self.viewConfig.motionColor
        view.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        return view
    }()
    
#if POOTOOLS_DEBUGTRACKINGEYES
    private var eyeTrackingFunction = PTFaceEye.share
    
    private lazy var eyeTracking:PTSwitch = {
        let view = PTSwitch()
        view.onTintColor = .randomColor
        view.isOn = false
        view.valueChangeCallBack = { value in
            if value {
                self.eyeTrackingFunction.createEye()
            } else {
                self.eyeTrackingFunction.dismissEye()
            }
        }
        return view
    }()
    
    private lazy var eyeTrackingLabel:UILabel = {
        let view = UILabel()
        view.textColor = .randomColor
        view.text = "PT Debug eye switch".localized()
        return view
    }()
    
    private var focusBool:Bool = false
    
    private lazy var eyeTrackingFocus:PTSwitch = {
        let view = PTSwitch()
        view.onTintColor = .randomColor
        view.isOn = false
        view.valueChangeCallBack = { value in
            self.focusBool = value
            if value {
                self.eyeTrackingFunction.hideCursorView()
            } else {
                self.eyeTrackingFunction.showCursorView()
            }
        }
        return view
    }()
    
    private lazy var eyeTrackingLabelFocus:UILabel = {
        let view = UILabel()
        view.textColor = .randomColor
        view.text = "PT Debug eys track".localized()
        return view
    }()
#endif
    
    public init(config:PTDevMaskConfig?) {
        super.init(frame: .zero)
        viewConfig = (config == nil ? PTDevMaskConfig() : config)!
        isMask = viewConfig.isMask
        
        let image = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_clear")

        let imageContent = UIImageView()
        addSubview(imageContent)
        imageContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        imageContent.image = image.watermark(title: viewConfig.maskString,font: viewConfig.maskFont, color: UIColor(red: 1, green: 1, blue: 1, alpha: 0.4))
        
        if viewConfig.showTouch {
            addSubview(springMotionView)
            springMotionView.onPositionUpdate = { point in
                let size = self.springMotionView.frame.size
                self.springMotionView.frame = CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: 20, height: 20)
            }
        }
        
#if POOTOOLS_DEBUGTRACKINGEYES
        if Gobal_device_info.isFaceIDCapable {
            PTPermission.camera.request {
                self.addSubviews([self.eyeTracking,self.eyeTrackingLabel,self.eyeTrackingFocus,self.eyeTrackingLabelFocus])
                self.eyeTracking.snp.makeConstraints { make in
                    make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                    make.bottom.equalToSuperview().inset(CGFloat.kTabbarHeight_Total)
                    make.width.equalTo(51)
                    make.height.equalTo(31)
                }
                
                self.eyeTrackingLabel.snp.makeConstraints { make in
                    make.left.equalTo(self.eyeTracking.snp.right).offset(10)
                    make.centerY.equalTo(self.eyeTracking)
                }
                
                self.eyeTrackingFocus.snp.makeConstraints { make in
                    make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                    make.bottom.equalTo(self.eyeTracking.snp.top).offset(-10)
                    make.width.equalTo(51)
                    make.height.equalTo(31)
                }
                
                self.eyeTrackingLabelFocus.snp.makeConstraints { make in
                    make.left.equalTo(self.eyeTrackingFocus.snp.right).offset(10)
                    make.centerY.equalTo(self.eyeTrackingFocus)
                }

                self.eyeTrackingFunction.eyeLookAt = { point in
                    if self.focusBool {
                        self.springMotionView.move(to: point)
                    }
                }
            }
        }
#endif
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if viewConfig.showTouch {
             subviews.enumerated().forEach({ index,value in
                if value is SpringMotionView {
                    springMotionView.move(to: point)
                } else {
                    addSubview(springMotionView)
                }
            })
            
            let touchPointSize:CGFloat = 64
            let animation = PTTouchAnimationView(touchPoint: point)
            addSubview(animation)
            animation.snp.makeConstraints { make in
                make.width.height.equalTo(touchPointSize)
                make.left.equalTo(point.x / 2)
                make.top.equalTo(point.y / 2)
            }
            UIView.animate(withDuration: 0.5) {
                animation.transform = CGAffineTransformScale(animation.transform, 4, 4)
                animation.alpha = 0
            } completion: { finish in
                animation.removeFromSuperview()
            }
        } else {
            springMotionView.removeFromSuperview()
        }

        return super.hitTest(point, with: event)
    }
}

fileprivate class PTTouchAnimationView :UIView {
    
    private var touchPoint:CGPoint!
    
    init(touchPoint:CGPoint) {
        super.init(frame: .zero)
        self.touchPoint = touchPoint
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let redbius:CGFloat = 40
        let startAngle:CGFloat = 0
        let point = CGPoint(x: touchPoint.x / 2, y: touchPoint.y / 2)
        let endAngle = 2 * Double.pi
        
        let path = UIBezierPath(arcCenter: point, radius: redbius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = UIColor.randomColor.cgColor
        layer.fillColor = UIColor.randomColor.cgColor
        self.layer.addSublayer(layer)
    }
}
