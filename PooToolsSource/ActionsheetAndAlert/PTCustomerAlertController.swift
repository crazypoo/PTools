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
public class PTCustomBottomButtonModel: NSObject {
    public var titleName:String? = ""
    public var titleColor:UIColor? = UIColor.systemBlue
}

public class PTCustomerAlertController: PTAlertController {

    public var bottomButtonTapCallback:((_ title:String,_ index:Int) -> Void)? = nil
    public var backgroundTapCallback:((PTCustomerAlertController) -> Void)? = nil
    public var contentBackgroundColor: UIColor? {
        didSet {
            updateContentBackgroundIfLoaded()
        }
    }

    fileprivate lazy var contentView:UIView = {
        let view = UIView()
        view.backgroundColor = contentBackgroundColor ?? .clear
        view.alpha = 0.0
        view.layer.cornerRadius = cornerSize
        view.clipsToBounds = true
        return view
    }()
    
    @PTClampedPropertyWrapper(range:0...15) fileprivate var cornerSize:CGFloat = 15
    
    fileprivate lazy var titleMessage:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.font = titleFont
        view.textColor = titleColor
        view.text = alertTitle
        return view
    }()
    
    fileprivate let alertTitle: String
    fileprivate let titleFont: UIFont
    fileprivate let titleColor: UIColor
    
    fileprivate lazy var customView:UIView = {
        let view = UIView()
        return view
    }()
    
    fileprivate let buttons: [String]
    fileprivate let buttonsColors: [UIColor]
    fileprivate var buttonModels = [PTCustomBottomButtonModel]()
    fileprivate var buttonsFont:UIFont = .appfont(size: 15)

    fileprivate var titleHeight:CGFloat = 0
    @PTClampedPropertyWrapper(range:25...100) fileprivate var contentSpace:CGFloat = 25
    let titleSpace:CGFloat = 10
    fileprivate var contentWidth: CGFloat = 0
    
    fileprivate var customerViewCallback:PTCustomerCustomerBlock? = nil
    fileprivate var customerViewHeight:CGFloat = 100
    private lazy var blur:SSBlurView = {
        let view = SSBlurView(frame: .zero)
        view.style = .systemMaterial
        view.animationDuration = 0.01
        view.enable(animated: false)
        return view
    }()
    fileprivate var canTapBackground:Bool = false
    
    public init(title:String = "",
                titleFont:UIFont = .appfont(size: 15),
                titleColor:UIColor = .systemBlue,
                customerViewHeight:CGFloat = 100,
                customerViewCallback:PTCustomerCustomerBlock? = nil,
                buttons:[String],
                buttonsColors:[UIColor],
                buttonsFont:UIFont = .appfont(size: 15),
                cornerSize: CGFloat = 15,
                contentSpace:CGFloat = 25,
                canTapBackground:Bool = false) {
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
        self.canTapBackground = canTapBackground
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        contentWidth = max(0, view.bounds.width - contentSpace * 2)
        
        let haveTitle = !alertTitle.isEmpty
        titleHeight = haveTitle ? (self.titleMessage.sizeFor(width: contentWidth - titleSpace * 2).height + 10) : 0
        if haveTitle {
            if titleHeight < 44 {
                titleHeight = 44
            }
        }
        
        buttonModels = buttons.enumerated().map { index, title in
            let model = PTCustomBottomButtonModel()
            model.titleName = title
            model.titleColor = (index < buttonsColors.count) ? buttonsColors[index] : .systemBlue
            return model
        }
        
        view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00)
        let buttonHeight: CGFloat = buttons.count <= 2 ? (buttons.isEmpty ? 0 : 44) : CGFloat(buttons.count) * 44

        view.addSubview(contentView)
        contentView.backgroundColor = contentBackgroundColor ?? .clear
        contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(contentWidth)
            make.height.equalTo((haveTitle ? titleHeight : 0) + customerViewHeight + buttonHeight)
        }
        
        if canTapBackground {
            let tap = UITapGestureRecognizer { _ in
                PTGCDManager.shared.runOnMain {
                    self.dismissSelf { [weak self = self] in
                        guard let self else { return }
                        PTGCDManager.shared.runOnMain {
                            self.backgroundTapCallback?(self)
                        }
                    }
                }
            }
            tap.cancelsTouchesInView = false
            tap.delegate = self
            view.addGestureRecognizer(tap)
        }

        contentView.addSubview(blur)
        blur.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentSubsSet()
    }

    private func updateContentBackgroundIfLoaded() {
        guard isViewLoaded else { return }
        contentView.backgroundColor = contentBackgroundColor ?? .clear
    }
    
    fileprivate func contentSubsSet() {
        contentView.addSubviews([titleMessage,customView])
        titleMessage.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(self.titleSpace)
            make.height.equalTo(self.titleHeight)
        }
        
        let buttonHeight: CGFloat = buttons.count <= 2 ? (buttons.isEmpty ? 0 : 44) : CGFloat(buttons.count) * 44
        customView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.titleMessage.snp.bottom)
            make.bottom.equalToSuperview().inset(buttonHeight)
        }
        self.customerViewCallback?(customView)

        guard !buttonModels.isEmpty else { return }

        let isVertical = buttonModels.count > 2
        let buttonsWidth: CGFloat = isVertical ? contentWidth : contentWidth / CGFloat(buttonModels.count)
        self.buttonModels.enumerated().forEach { index,value in
            let buttonTitle = value.titleName ?? ""
            let buttonsSet = UIButton(type: .custom)
            buttonsSet.titleLabel?.font = self.buttonsFont
            buttonsSet.setTitleColor(value.titleColor, for: .normal)
            buttonsSet.setTitle(value.titleName, for: .normal)
            buttonsSet.setTitleColor(.systemGray, for: .highlighted)
            buttonsSet.titleLabel?.textAlignment = .center
            buttonsSet.contentHorizontalAlignment = .center
            buttonsSet.tag = 100 + index
            buttonsSet.addActionHandlers { [weak self] _ in
                self?.dismissSelf { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.bottomButtonTapCallback?(buttonTitle, index)
                        self.bottomButtonTapCallback = nil
                    }
                }
            }
            self.contentView.addSubview(buttonsSet)
            buttonsSet.snp.makeConstraints { make in
                if isVertical {
                    make.left.right.equalToSuperview()
                    make.top.equalTo(self.customView.snp.bottom).offset(CGFloat(index) * 44)
                } else {
                    make.left.equalToSuperview().inset(CGFloat(index) * buttonsWidth)
                    make.width.equalTo(buttonsWidth)
                }
                make.height.equalTo(44)
                if isVertical {
                    if index == self.buttonModels.count - 1 {
                        make.bottom.equalToSuperview()
                    }
                } else {
                    make.bottom.equalToSuperview()
                }
            }
        }
    }
    
}

extension PTCustomerAlertController {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldReceive touch: UITouch) -> Bool {
        touch.view === view
    }
}

extension PTCustomerAlertController {
    public override func showAnimation(completion: PTActionTask?) {
        UIView.animate(withDuration: config.showAlertDuration) {
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
    
    public override func dismissAnimation(completion: PTActionTask?) {
        UIView.animate(withDuration: config.hideAlertDuration, animations: {
            self.view.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.00)
            self.contentView.alpha = 0.0
        }) { _ in
            completion?()
        }
    }
}
