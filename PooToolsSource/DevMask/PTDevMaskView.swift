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
public class PTDevMaskConfig:NSObject {
    public var isMask:Bool = false
    public var maskString:String = "测试模式"
    public var maskFont:UIFont = .appfont(size: 100,bold: true)
}

@objcMembers
public class PTDevMaskView: PTBaseMaskView {

    var viewConfig : PTDevMaskConfig = PTDevMaskConfig()
    
    let bundlePath = Bundle.init(path: PTUtils.cgBaseBundle().path(forResource: "PooTools", ofType: "bundle")!)

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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
