//
//  PTTextView.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/27.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTTextView: UITextView {
    private var placeholder:String?
    
    private var realTextColor:UIColor? = .black
    private var realText:String? = ""
    
//    public init(frame:CGRect,ssss:String)
//    {
//        super.init(frame: .zero)
//        placeholder = ssss
//    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func beginEditing(notification:NSNotification)
    {
        if realText == placeholder
        {
            super.text = nil
            self.textColor = self.realTextColor
        }
    }
    
    private func endEditing(notification:NSNotification)
    {
        if realText!.stringIsEmpty()
        {
            super.text = placeholder
            self.textColor = .lightGray
        }
    }
}
