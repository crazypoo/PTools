//
//  PTSearchBar.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/27.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTSearchBar: UISearchBar {
    @objc var searchPlaceholder : String? = "请输入文字"

    @objc var searchPlaceholderFont : UIFont? = .systemFont(ofSize: 16)
    
    @objc var searchBarTextFieldBorderColor : UIColor? = UIColor.random
    
    @objc var searchBarImage : UIImage? = PTUtils.createImageWithColor(color: UIColor.clear)
    
    @objc var cursorColor : UIColor? = .lightGray
    
    @objc var searchPlaceholderColor : UIColor? = UIColor.random
    
    @objc var searchTextColor : UIColor? = UIColor.random
    
    @objc var searchBarOutViewColor : UIColor? = UIColor.random
    
    @objc var searchBarTextFieldCornerRadius : NSDecimalNumber?  = 5
    
    @objc var searchBarTextFieldBorderWidth : NSDecimalNumber? = 0.5

    @objc var searchTextFieldBackgroundColor : UIColor? = UIColor.random
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 13.0, *)
        {
            searchTextField.backgroundColor = searchTextFieldBackgroundColor!
            searchTextField.tintColor = cursorColor!
            searchTextField.textColor = searchTextColor!
            searchTextField.font = searchPlaceholderFont!
            searchTextField.attributedPlaceholder = NSAttributedString(string: searchPlaceholder!, attributes: [NSAttributedString.Key.font:searchPlaceholderFont!,NSAttributedString.Key.foregroundColor:searchPlaceholderColor!])
            backgroundImage = PTUtils.createImageWithColor(color: searchBarOutViewColor!)
            setImage(searchBarImage!, for: .search, state: .normal)
            searchTextField.viewCorner(radius: (searchBarTextFieldCornerRadius as! CGFloat), borderWidth: (searchBarTextFieldBorderWidth as! CGFloat), borderColor: searchBarTextFieldBorderColor!)
        }
        else
        {
            var searchField : UITextField?
            let subviewArr  = self.subviews
            for i in 0..<subviewArr.count {
                let viewSub = subviewArr[i]
                let arrSub = viewSub.subviews
                for j in 0..<arrSub.count {
                    let tempID = arrSub[j]
                    if tempID is UITextField
                    {
                        searchField = (tempID as! UITextField)
                    }
                }
            }
            
            if searchField != nil
            {
                searchField?.placeholder = searchPlaceholder!
                searchField?.borderStyle = .roundedRect
                searchField?.backgroundColor = searchTextFieldBackgroundColor!
                searchField?.attributedPlaceholder = NSAttributedString(string: searchPlaceholder!, attributes: [NSAttributedString.Key.font:searchPlaceholderFont!,NSAttributedString.Key.foregroundColor:searchPlaceholderColor!])
                searchField?.textColor = searchTextColor!
                searchField?.font = searchPlaceholderFont!
                searchField?.viewCorner(radius: (searchBarTextFieldCornerRadius as! CGFloat), borderWidth: (searchBarTextFieldBorderWidth as! CGFloat), borderColor: searchBarTextFieldBorderColor!)

                if searchBarImage == PTUtils.createImageWithColor(color: UIColor.clear)
                {
                    searchField?.leftView = nil
                }
                else
                {
                    let view = UIImageView(image: searchBarImage!)
                    view.frame = CGRect.init(x: 0, y: 0, width: 16, height: 16)
                    searchField?.leftView = view
                }
                (self.subviews[0].subviews[1] as! UITextField).tintColor = cursorColor!
                let outView = UIView.init(frame: self.bounds)
                outView.backgroundColor = searchBarOutViewColor!
                insertSubview(outView, at: 1)
            }
        }
    }
}
