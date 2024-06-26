//
//  PTNumberKeyBoard.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/26.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

@objc public enum PTKeyboardType:Int {
    case Normal
    case Call
    case Point
    case InputID
}

public typealias PTNumberKeyBoardBackSpace = (_ keyboard:PTNumberKeyBoard)->Void
public typealias PTNumberKeyBoardReturnSTH = (_ keyboard:PTNumberKeyBoard,_ result:String)->Void

extension PTNumberKeyBoard {
    static func createKeyboard(type:PTKeyboardType,backSpace:@escaping PTNumberKeyBoardBackSpace,returnSTH:@escaping PTNumberKeyBoardReturnSTH) -> Self {
        PTNumberKeyBoard.init(type: type, backSpace: backSpace, returnSTH: returnSTH) as! Self
     }
}

@objcMembers
public class PTNumberKeyBoard: UIView {
    private static let kKeyBoardH : CGFloat = 216
    private static let kLineWidth : CGFloat = 1
    private static let kButtonSpaceTop : CGFloat = 5
    private static let kButtonSpaceLeft : CGFloat = 5
    private static let kKeyH : CGFloat = (PTNumberKeyBoard.kKeyBoardH - CGFloat(PTNumberKeyBoard.kLineWidth * 3) - CGFloat(PTNumberKeyBoard.kButtonSpaceTop * 5)) / 4
    
    fileprivate var kKeyW : CGFloat {
        get {
            (bounds.size.width - CGFloat(PTNumberKeyBoard.kLineWidth * 2) - CGFloat(PTNumberKeyBoard.kButtonSpaceLeft * 4))/3
        } set {
            if kKeyW != newValue {
                self.kKeyW = newValue
            }
        }
    }
                
    public init(type: PTKeyboardType, backSpace: @escaping PTNumberKeyBoardBackSpace, returnSTH: @escaping PTNumberKeyBoardReturnSTH) {
        super.init(frame: .zero)
        
        bounds = CGRect(x: 0, y: 0, width: CGFloat.kSCREEN_WIDTH, height: PTNumberKeyBoard.kKeyBoardH + CGFloat.kTabbarSaveAreaHeight)
        
        let colorNormal = UIColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1)
        let colorHighlighted = UIColor(red: 186/255, green: 189/255, blue: 194/255, alpha: 1)
        
        for i in 0..<4 {
            for j in 0..<3 {
                let button = UIButton(type: .custom)
                button.tag = j + 3 * i + 1
                
                button.addActionHandlers { sender in
                    if sender.tag == 12 {
                        backSpace(self)
                    } else {
                        var num = String(sender.tag)
                        if sender.tag == 11 {
                            num = "0"
                        } else if sender.tag == 10 {
                            switch type {
                            case .Normal:
                                num = ""
                            case .Call:
                                num = "+"
                            case .Point:
                                num = "."
                            case .InputID:
                                num = "X"
                            }
                        }
                        returnSTH(self, num)
                    }
                }
                
                addSubview(button)
                
                let buttonTopInset = PTNumberKeyBoard.kKeyH * CGFloat(i) + CGFloat(i) * PTNumberKeyBoard.kLineWidth + PTNumberKeyBoard.kButtonSpaceTop * CGFloat(i + 1)
                let buttonLeftInset = self.kKeyW * CGFloat(j) + CGFloat(j) * PTNumberKeyBoard.kLineWidth + PTNumberKeyBoard.kButtonSpaceLeft * CGFloat(j + 1)
                
                button.snp.makeConstraints { make in
                    make.height.equalTo(PTNumberKeyBoard.kKeyH)
                    make.width.equalTo(self.kKeyW)
                    make.top.equalToSuperview().inset(buttonTopInset)
                    make.left.equalToSuperview().inset(buttonLeftInset)
                }
                
                button.viewCorner(radius: 5)
                
                let cN: UIColor = (button.tag == 10 || button.tag == 12) ? colorHighlighted : colorNormal
                let cH: UIColor = (button.tag == 10 || button.tag == 12) ? colorNormal : colorHighlighted
                
                button.titleLabel?.font = .systemFont(ofSize: 25)
                button.setTitleColor(.black, for: .normal)
                
                switch button.tag {
                case 1...9:
                    button.setTitle(String(button.tag), for: .normal)
                case 11:
                    button.setTitle("0", for: .normal)
                case 10:
                    switch type {
                    case .Call:
                        button.setTitle("+", for: .normal)
                    case .Point:
                        button.setTitle(".", for: .normal)
                    case .InputID:
                        button.setTitle("X", for: .normal)
                    default:
                        button.setTitle("", for: .normal)
                    }
                case 12:
                    button.setTitle("PT Button delete".localized(), for: .normal)
                default:
                    break
                }
                
                button.setBackgroundImage(cN.createImageWithColor(), for: .normal)
                button.setBackgroundImage(cH.createImageWithColor(), for: .highlighted)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        for i in 0..<4 {
            for j in 0..<3 {
                let button  = viewWithTag(j + 3 * i + 1)
                button!.snp.makeConstraints { make in
                    
                    let hValue = PTNumberKeyBoard.kKeyH * CGFloat(i)
                    let spaceValue = CGFloat(i) * PTNumberKeyBoard.kLineWidth
                    let tValue = PTNumberKeyBoard.kButtonSpaceTop * CGFloat(i + 1)
                    
                    make.height.equalTo(PTNumberKeyBoard.kKeyH)
                    make.width.equalTo(self.kKeyW)
                    make.top.equalToSuperview().inset(hValue + spaceValue + tValue)
                    make.left.equalTo(self.kKeyW * CGFloat(j) + CGFloat(j) * PTNumberKeyBoard.kLineWidth + PTNumberKeyBoard.kButtonSpaceLeft * CGFloat(j + 1))
                }
            }
        }
    }
}
