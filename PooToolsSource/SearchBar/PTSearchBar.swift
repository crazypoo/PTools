//
//  PTSearchBar.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/27.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTSearchBarTextFieldClearButtonConfig:NSObject {
    open var clearAction:PTActionTask?
    open var clearImage:Any?
    open var clearTopSpace:CGFloat = 12.5
}

@objcMembers
public class PTSearchBar: UISearchBar {
    //MARK: 輸入框Placeholder
    ///輸入框Placeholder
    open var searchPlaceholder : String? = "PT Input text".localized()
    //MARK: 輸入框Placeholder字體
    ///輸入框Placeholder字體
    open var searchPlaceholderFont : UIFont? = .systemFont(ofSize: 16)
    //MARK: 輸入框邊框顏色
    ///輸入框邊框顏色
    open var searchBarTextFieldBorderColor : UIColor? = UIColor.random
    //MARK: 輸入框放大鏡位置的圖片
    ///輸入框放大鏡位置的圖片
    open var searchBarImage : UIImage? = UIColor.clear.createImageWithColor()
    //MARK: 輸入框光標顏色
    ///輸入框光標顏色
    open var cursorColor : UIColor? = .lightGray
    //MARK: 輸入框Placeholder字體顏色
    ///輸入框Placeholder字體顏色
    open var searchPlaceholderColor : UIColor? = UIColor.random
    //MARK: 輸入框字體顏色
    ///輸入框字體顏色
    open var searchTextColor : UIColor? = UIColor.random
    //MARK: 輸入框外邊框顏色
    ///輸入框外邊框顏色
    open var searchBarOutViewColor : UIColor? = UIColor.random
    //MARK: 輸入框角弧度
    ///輸入框角弧度
    open var searchBarTextFieldCornerRadius : NSDecimalNumber?  = 5
    //MARK: 輸入框邊框粗度
    ///輸入框邊框粗度
    open var searchBarTextFieldBorderWidth : NSDecimalNumber? = 0.5
    //MARK: 輸入框底部顏色
    ///輸入框底部顏色
    open var searchTextFieldBackgroundColor : UIColor? = UIColor.random

    open var clearConfig:PTSearchBarTextFieldClearButtonConfig? {
        didSet {
            guard let clearConfig = clearConfig else { return }
            
            if let searchField = self.value(forKey: "searchField") as? UITextField,
               let clearBtn = searchField.value(forKey: "_clearButton") as? UIButton {
                
                Task {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    
                    let clearTopSpace = min(max(clearConfig.clearTopSpace, 0), self.frame.height - 15)
                    let clearHeight = self.frame.height - clearTopSpace * 2
                    
                    clearBtn.imageView?.contentMode = .scaleAspectFit
                    clearBtn.bounds = CGRect(x: 0, y: clearTopSpace, width: clearHeight, height: clearHeight)
                    
                    if let clearImage = clearConfig.clearImage {
                        let result = await PTLoadImageFunction.loadImage(contentData: clearImage)
                        
                        if let images = result.0, !images.isEmpty {
                            if images.count > 1 {
                                clearBtn.setImage(UIImage.animatedImage(with: images, duration: 2), for: .normal)
                            } else if let image = result.1 {
                                let resizedImage = image.transformImage(size: CGSize(width: clearHeight, height: clearHeight))
                                clearBtn.setImage(resizedImage, for: .normal)
                            }
                        }
                    }
                    
                    clearBtn.addActionHandlers { _ in
                        clearConfig.clearAction?()
                    }
                }
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if let searchTextField = self.value(forKey: "searchField") as? UITextField {
            searchTextField.backgroundColor = searchTextFieldBackgroundColor
            searchTextField.tintColor = cursorColor
            searchTextField.textColor = searchTextColor
            searchTextField.font = searchPlaceholderFont
            searchTextField.attributedPlaceholder = NSAttributedString(
                string: searchPlaceholder ?? "",
                attributes: [
                    .font: searchPlaceholderFont!,
                    .foregroundColor: searchPlaceholderColor!
                ]
            )
            backgroundImage = searchBarOutViewColor?.createImageWithColor()
            setImage(searchBarImage, for: .search, state: .normal)
            searchTextField.viewCorner(radius: searchBarTextFieldCornerRadius as! CGFloat, borderWidth: searchBarTextFieldBorderWidth as! CGFloat, borderColor: searchBarTextFieldBorderColor!)
        }
    }
}
