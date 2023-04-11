//
//  PTDevMaskView.swift
//  Diou
//
//  Created by ken lam on 2021/10/22.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SnapKit

@objcMembers
open class PTDevMaskConfig:NSObject {
    public var isMask:Bool = false
    public var maskString:String = "测试模式"
    public var maskFont:UIFont = .appfont(size: 100,bold: true)
    public var motionColor:UIColor = .randomColor
}

@objcMembers
open class PTDevMaskView: PTBaseMaskView {

    private var viewConfig : PTDevMaskConfig = PTDevMaskConfig()
    
    let bundlePath = Bundle.init(path: PTUtils.cgBaseBundle().path(forResource: "PooTools", ofType: "bundle")!)

    private lazy var springMotionView: SpringMotionView = {
        let view = SpringMotionView()
        view.backgroundColor = self.viewConfig.motionColor
        view.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        return view
    }()
    
    public init(config:PTDevMaskConfig?) {
        super.init(frame: .zero)
        self.viewConfig = (config == nil ? PTDevMaskConfig() : config)!
        self.isMask = self.viewConfig.isMask
        
        let image = UIImage.init(contentsOfFile: bundlePath!.path(forResource: "icon_clear", ofType: "png")!)

        let imageContent = UIImageView()
        addSubview(imageContent)
        imageContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        imageContent.image = image!.watermark(title: self.viewConfig.maskString,font: self.viewConfig.maskFont, color: UIColor(red: 1, green: 1, blue: 1, alpha: 0.4))
        
        self.addSubview(self.springMotionView)
        self.springMotionView.onPositionUpdate = { point in
            let size = self.springMotionView.frame.size
            self.springMotionView.frame = CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: 20, height: 20)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        self.springMotionView.move(to: point)
        return super.hitTest(point, with: event)
    }
}
