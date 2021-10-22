//
//  PTDevMaskView.swift
//  Diou
//
//  Created by ken lam on 2021/10/22.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SnapKit

public class PTDevMaskView: UIView {

    public var isMask : Bool? = true
    
    public init(maskImage:String,maskString:String)
    {
        super.init(frame: .zero)
        
        let image = UIImage(named: maskImage)
        
        let imageContent = UIImageView()
        addSubview(imageContent)
        imageContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        imageContent.image = PTUtils.watermark(originalImage: image!, title: maskString, font: UIFont.systemFont(ofSize: 100), color: UIColor(red: 1, green: 1, blue: 1, alpha: 0.4))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        if isMask!
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
