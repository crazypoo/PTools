//
//  PTCustomerAlertViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/15.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

public typealias PTCustomerCustomerBlock = (_ alertCustomerView:UIView) -> Void

@objc public enum PTAlertAnimationType:Int {
    case Top
    case Bottom
    case Left
    case Right
    case Normal
}

@objcMembers
public class PTCustomBottomButtonModel:NSObject {
    public var titleName:String? = ""
    public var titleColor:UIColor? = UIColor.systemBlue
}

public class PTCustomerAlertController: PTAlertController {

    public var bottomButtonTapCallback:((_ title:String,_ index:Int)->Void)? = nil
    
    fileprivate lazy var contentView:UIView = {
        let view = UIView()
        view.backgroundColor = DynamicColor(hexString: "c3c3c8")
        view.alpha = 0.0
        view.layer.cornerRadius = cornerSize
        view.clipsToBounds = true
        return view
    }()
    
    @PTClampedProperyWrapper(range:0...15) fileprivate var cornerSize:CGFloat = 15
    
    fileprivate lazy var titleMessage:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.font = titleFont
        view.textColor = titleColor
        view.text = alertTitle
        return view
    }()
    
    fileprivate var alertTitle:String!
    fileprivate var titleFont:UIFont!
    fileprivate var titleColor:UIColor!
    
    fileprivate lazy var customView:UIView = {
        let view = UIView()
        return view
    }()
    
    fileprivate var buttons:[String]!
    fileprivate var buttonsColors:[UIColor]!
    fileprivate var buttonModels = [PTCustomBottomButtonModel]()
    fileprivate var buttonsFont:UIFont = .appfont(size: 15)

    fileprivate var titleHeight:CGFloat = 0
    @PTClampedProperyWrapper(range:25...100) fileprivate var contentSpace:CGFloat = 25
    let titleSpace:CGFloat = 10
    fileprivate var contentWidth:CGFloat = CGFloat.kSCREEN_WIDTH
    
    fileprivate var customerViewCallback:PTCustomerCustomerBlock? = nil
    fileprivate var customerViewHeight:CGFloat = 100
    fileprivate var blur:SSBlurView?

    public init(title:String = "",
                titleFont:UIFont = .appfont(size: 15),
                titleColor:UIColor = .systemBlue,
                customerViewHeight:CGFloat = 100,
                customerViewCallback:PTCustomerCustomerBlock? = nil,
                buttons:[String],
                buttonsColors:[UIColor],
                buttonsFont:UIFont = .appfont(size: 15),
                cornerSize: CGFloat = 15,
                contentSpace:CGFloat = 25) {
        self.alertTitle = title
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.buttons = buttons
        self.buttonsColors = buttonsColors
        self.buttonsFont = buttonsFont
        self.cornerSize = cornerSize
        self.contentSpace = contentSpace
        self.customerViewHeight = customerViewHeight
        self.customerViewCallback = customerViewCallback
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        contentWidth = CGFloat.kSCREEN_WIDTH - contentSpace * 2
        
        let haveTitle = !alertTitle.isEmpty
        titleHeight = haveTitle ? (self.titleMessage.sizeFor(width: contentWidth - titleSpace * 2).height + 10) : 0
        if haveTitle {
            if titleHeight < 44 {
                titleHeight = 44
            }
        }
        
        buttons.enumerated().forEach { index,value in
            let model = PTCustomBottomButtonModel()
            if buttonsColors.count < buttons.count {
                if index > (buttonsColors.count - 1) {
                    model.titleColor = .systemBlue
                } else {
                    model.titleColor = buttonsColors[index]
                }
            } else {
                model.titleColor = buttonsColors[index]
            }
            model.titleName = value
            buttonModels.append(model)
        }
        
        view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00)
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(contentWidth)
            make.height.equalTo(haveTitle ? (titleHeight + 44 + customerViewHeight) : (44 + customerViewHeight))
        }
        
        blur = SSBlurView.init(to: contentView)
        blur!.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
        blur!.alpha = 0.9
        blur!.enable()

        contentSubsSet()
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                self.blur!.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    fileprivate func contentSubsSet() {
        contentView.addSubviews([titleMessage,customView])
        titleMessage.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(self.titleSpace)
            make.height.equalTo(self.titleHeight)
        }
        
        customView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.titleMessage.snp.bottom)
            make.bottom.equalToSuperview().inset(44)
        }
        self.customerViewCallback?(customView)
        
        let buttonsWidth:CGFloat = contentWidth / CGFloat(self.buttons.count)
        self.buttonModels.enumerated().forEach { index,value in
            let buttonsSet = UIButton(type: .custom)
            buttonsSet.titleLabel?.font = self.buttonsFont
            buttonsSet.setTitleColor(value.titleColor, for: .normal)
            buttonsSet.setTitle(value.titleName, for: .normal)
            buttonsSet.setTitleColor(.lightGray, for: .highlighted)
            buttonsSet.titleLabel?.textAlignment = .center
            buttonsSet.contentHorizontalAlignment = .center
            buttonsSet.tag = 100 + index
            buttonsSet.addActionHandlers { sender in
                self.dismissAnimation {
                    self.bottomButtonTapCallback?(value.titleName ?? "",index)
                    self.bottomButtonTapCallback = nil
                }
            }
            self.contentView.addSubview(buttonsSet)
            buttonsSet.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(CGFloat(index) * buttonsWidth)
                make.height.equalTo(44)
                make.width.equalTo(buttonsWidth)
                make.bottom.equalToSuperview()
            }
        }
    }
    
    @available(iOS, introduced: 8.0, deprecated: 17.0,message: "17後不再支持了")
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // 适配代码
            blur!.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
        }
    }
}

extension PTCustomerAlertController {
    public override func showAnimation(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = UIColor.DevMaskColor
            self.contentView.alpha = 1.0
        }
        contentView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        UIView.animate(withDuration: 0.35, delay: 0.0, options: UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(7 << 16)), animations: {
            self.contentView.transform = CGAffineTransform.identity
        }) { _ in
            completion?()
        }
    }
    
    public override func dismissAnimation(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00)
            self.contentView.alpha = 0.0
        }) { _ in
            PTAlertManager.dismiss(self.key)
            completion?()
        }
    }
}
