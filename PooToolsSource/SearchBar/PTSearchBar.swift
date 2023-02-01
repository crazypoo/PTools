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
    //MARK: 輸入框Placeholder
    ///輸入框Placeholder
    public var searchPlaceholder : String? = "请输入文字"
    //MARK: 輸入框Placeholder字體
    ///輸入框Placeholder字體
    public var searchPlaceholderFont : UIFont? = .systemFont(ofSize: 16)
    //MARK: 輸入框邊框顏色
    ///輸入框邊框顏色
    public var searchBarTextFieldBorderColor : UIColor? = UIColor.random
    //MARK: 輸入框放大鏡位置的圖片
    ///輸入框放大鏡位置的圖片
    public var searchBarImage : UIImage? = UIColor.clear.createImageWithColor()
    //MARK: 輸入框光標顏色
    ///輸入框光標顏色
    public var cursorColor : UIColor? = .lightGray
    //MARK: 輸入框Placeholder字體顏色
    ///輸入框Placeholder字體顏色
    public var searchPlaceholderColor : UIColor? = UIColor.random
    //MARK: 輸入框字體顏色
    ///輸入框字體顏色
    public var searchTextColor : UIColor? = UIColor.random
    //MARK: 輸入框外邊框顏色
    ///輸入框外邊框顏色
    public var searchBarOutViewColor : UIColor? = UIColor.random
    //MARK: 輸入框角弧度
    ///輸入框角弧度
    public var searchBarTextFieldCornerRadius : NSDecimalNumber?  = 5
    //MARK: 輸入框邊框粗度
    ///輸入框邊框粗度
    public var searchBarTextFieldBorderWidth : NSDecimalNumber? = 0.5
    //MARK: 輸入框底部顏色
    ///輸入框底部顏色
    public var searchTextFieldBackgroundColor : UIColor? = UIColor.random

    public override func layoutSubviews() {
        super.layoutSubviews()
        
        searchTextField.backgroundColor = searchTextFieldBackgroundColor!
        searchTextField.tintColor = cursorColor!
        searchTextField.textColor = searchTextColor!
        searchTextField.font = searchPlaceholderFont!
        searchTextField.attributedPlaceholder = NSAttributedString(string: searchPlaceholder!, attributes: [NSAttributedString.Key.font:searchPlaceholderFont!,NSAttributedString.Key.foregroundColor:searchPlaceholderColor!])
        backgroundImage = searchBarOutViewColor!.createImageWithColor()
        setImage(searchBarImage!, for: .search, state: .normal)
        searchTextField.viewCorner(radius: (searchBarTextFieldCornerRadius as! CGFloat), borderWidth: (searchBarTextFieldBorderWidth as! CGFloat), borderColor: searchBarTextFieldBorderColor!)
    }
}
