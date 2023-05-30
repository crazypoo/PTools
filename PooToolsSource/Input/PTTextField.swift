//
//  PTTextField.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

@objcMembers
public class PTTextCustomRightViewConfig:NSObject {
    var size:CGSize = .zero
    var image:Any?
    var rightSpace:CGFloat = 5
}

@objcMembers
public class PTTextField: UITextField {
    
    public var leftSpace:CGFloat? {
        didSet {
            layoutSubviews()
        }
    }
    
    public var rightTapBlock:(()->Void)?
    
    public var rightConfig:PTTextCustomRightViewConfig? {
        didSet {
            PTGCDManager.gcdAfter(time: 0.5) {
                if !NSObject.checkObject(self.rightConfig!.image as? NSObject) {
                    var viewSize:CGSize = self.rightConfig!.size
                    if self.rightConfig!.size.height > self.frame.size.height {
                        viewSize.height = self.frame.size.height
                    }
                    
                    if (self.leftSpace ?? 0) > 0 {
                        if self.rightConfig!.size.width > (self.frame.size.width - self.leftSpace! - self.rightConfig!.rightSpace) {
                            viewSize.width = (self.frame.size.width - self.leftSpace! - self.rightConfig!.rightSpace)
                        }
                    }
                    self.clearButtonMode = .never
                    
                    self.customRight.frame = CGRect(x: 0, y: (self.frame.size.height - viewSize.height) / 2, width: viewSize.width, height: viewSize.height)
                    
                    if self.rightConfig!.image is String {
                        let link = self.rightConfig!.image as! String
                        if FileManager.pt.judgeFileOrFolderExists(filePath: link) {
                            self.customRight.setImage(UIImage(contentsOfFile: link), for: .normal)
                        } else {
                            if link.isURL() {
                                self.customRight.pt_SDWebImage(imageString: link)
                            } else if link.isSingleEmoji {
                                self.customRight.setImage(link.emojiToImage(), for: .normal)
                            } else {
                                self.customRight.setImage(UIImage(named: link), for: .normal)
                            }
                        }
                    } else if self.rightConfig!.image is UIImage {
                        self.customRight.setImage((self.rightConfig!.image as! UIImage), for: .normal)
                    } else if self.rightConfig!.image is Data {
                        self.customRight.setImage(UIImage(data: (self.rightConfig!.image as! Data)), for: .normal)
                    }

                    let rightViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: viewSize.width + self.rightConfig!.rightSpace, height: self.frame.size.height))
                    rightViewContainer.addSubview(self.customRight)

                    self.rightView = rightViewContainer
                    self.rightViewMode = .always
                }
            }
            layoutSubviews()
        }
    }
    
    private lazy var customRight:UIButton = {
        let view = UIButton(type: .custom)
        view.addActionHandlers { sender in
            if self.rightTapBlock != nil {
                self.rightTapBlock!()
            }
        }
        return view
    }()
    
    private lazy var leftSpaceView:UIView = {
        let view = UIView()
        view.frame = CGRectMake(0, 0, self.leftSpace!, self.frame.size.height)
        return view
    }()
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if (leftSpace ?? 0) > 0 {
            leftView = leftSpaceView
            leftViewMode = .always
        }
    }
}
