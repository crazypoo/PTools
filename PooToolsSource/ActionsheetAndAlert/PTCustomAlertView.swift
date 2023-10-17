//
//  PTCustomAlertView.swift
//  Diou
//
//  Created by ken lam on 2021/10/18.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import pop
import SwifterSwift
import SnapKit

public let BottomButtonHeight : CGFloat = 44
public let AlertLine : CGFloat = 0.5

public typealias PTCustomerAlertClickBlock = (_ alert:PTCustomAlertView,_ index:Int) -> Void
public typealias PTCustomerDidDismissBlock = (_ alert:PTCustomAlertView) -> Void
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

@objcMembers
public class PTCustomAlertView: UIView {

    ///按钮点击回调
    public var buttonClick:PTCustomerAlertClickBlock?
    ///Alert消失回调
    public var didDismissBlock:PTCustomerDidDismissBlock?
    ///Alert自定义界面回调
    public var customerBlock:PTCustomerCustomerBlock?

    //MARK: 计算标题高度
    ///计算标题高度
    /// - Parameters:
    ///   - font: 字体
    ///   - alertWidth: 弹框width
    ///   - title: 标题
    class public func getAlertTitleHeight(font:UIFont,
                                          alertWidth:CGFloat,
                                          title:String)->CGFloat {
        let height = UIView.sizeFor(string: title, font: font, height: CGFloat(MAXFLOAT), width: (alertWidth - 20)).height + 5
        let viewHeight = CGFloat.kSCREEN_HEIGHT / 3
        return title.stringIsEmpty() ? 0 : ((height >= viewHeight) ? viewHeight : height)
    }
    
    //MARK: 计算下按钮高度
    ///计算下按钮高度
    /// - Parameters:
    ///   - font: 字体
    ///   - alertWidth: 弹框width
    ///   - moreButtonTitles: 按钮s
    class public func getBottomButtonHiehgt(font:UIFont,
                                            alertWidth:CGFloat,
                                            moreButtonTitles:[PTCustomBottomButtonModel])->CGFloat {
        let buttonH = UIView.sizeFor(string: "HOLA", font: font, height: CGFloat(MAXFLOAT), width: (alertWidth - 20)).height + 5
        return (moreButtonTitles.count == 0 || moreButtonTitles.isEmpty) ? 0 : ((buttonH > BottomButtonHeight) ? buttonH : BottomButtonHeight)
    }
    
    //MARK: 计算标题&下按钮高度
    ///计算标题&下按钮高度
    /// - Parameters:
    ///   - font: 字体
    ///   - width: 弹框width
    ///   - moreButtonTitles: 按钮s
    ///   - title: 标题
    class public func titleAndBottomViewNormalHeight(width:CGFloat,
                                                     title:String,
                                                     font:UIFont,
                                                     buttonArray:[PTCustomBottomButtonModel])->CGFloat {
        var titleH : CGFloat? = 0
        titleH = PTCustomAlertView.getAlertTitleHeight(font: font, alertWidth: width, title: title)
        let btnW : CGFloat = (width - CGFloat(buttonArray.count - 1) * AlertLine) / CGFloat(buttonArray.count)
        var isEX : Bool?  = false
        if !(buttonArray.count == 0 || buttonArray.isEmpty) {
            for string in buttonArray {
                if (font.pointSize * CGFloat((string.titleName! as NSString).length) + 10) > btnW {
                    isEX = true
                    break
                }
            }
        } else {
            isEX = true
        }
        
        let bottomButtonH = PTCustomAlertView.getBottomButtonHiehgt(font: font, alertWidth: width, moreButtonTitles: buttonArray)
        
        let planA : CGFloat = (titleH! + bottomButtonH * CGFloat(buttonArray.count) + AlertLine * CGFloat(buttonArray.count))
        let planB : CGFloat = (titleH! + bottomButtonH + AlertLine + 10)
        
        return isEX! ? planA : planB
    }
    
    private lazy var backgroundView : UIView = {
        let view = UIView()
        view.backgroundColor = .DevMaskColor
        return view
    }()
    
    private lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.font = viewFont
        label.textColor = alertTitleColor
        label.textAlignment = .center
        label.lineBreakMode = .byCharWrapping
        label.numberOfLines = 0
        label.backgroundColor = .clear
        return label
    }()
    
    private lazy var titleScroller : UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = true
        return view
    }()
    
    private var blur:SSBlurView?
    private var bottombuttonArray = [PTCustomBottomButtonModel]()
    private var mainView = UIView()
    private var viewFont = UIFont()
    private var alertTitleColor = UIColor()
    private var verLineColor = UIColor()
    private var titleString = String()
    private var alertViewBackgroundColor = UIColor()
    private var heightlightedColorColor = UIColor()
    private var animationType : PTAlertAnimationType = .Bottom
    private lazy var customView : UIView = {
        let view = UIView()
        return view
    }()
        
    //MARK: 初始化創建Alert
    ///初始化創建Alert
    /// - Parameters:
    ///   - superView: 加載在?上
    ///   - titleString: 標題
    ///   - titleFont: 字體
    ///   - titleColor: 標題的字體顏色
    ///   - alertVerLineColor: 按鈕線的顏色
    ///   - alertBackgroundColor: Alert的背景顏色
    ///   - alertHeightlightedColor: 按鈕點以後的顏色
    ///   - alertAnimationType: 動畫形式
    ///   - buttons: 按鈕設置
    ///   - buttonColor: 按鈕顏色
    ///   - touchBackground: 是否支持點擊背景消失Alert
    ///   - cornerSize: Alert邊框角弧度
    ///   - customAlertHeight: 自定義View高度
    ///   - alertLeftAndRightSpace: Alert的左右邊距
    ///   - customerBlock: 自定義View回調
    ///   - tapBlock: 點擊回調
    ///   - alertDismissBlock: 界面離開後的回調
    public class func alertFunction(superView:UIView = AppWindows!,
                                          titleString:String = "",
                                          titleFont:UIFont = .appfont(size: 15),
                                          titleColor:UIColor = .systemBlue,
                                          alertVerLineColor:UIColor = .lightGray,
                                          alertBackgroundColor:UIColor = .white,
                                          alertHeightlightedColor:UIColor = .systemBlue,
                                          alertAnimationType:PTAlertAnimationType = .Bottom,
                                          buttons:[String],
                                          buttonColor:[UIColor],
                                          touchBackground:Bool = true,
                                          cornerSize:CGFloat = 15,
                                          customAlertHeight:CGFloat = 100,
                                          alertLeftAndRightSpace:CGFloat = CGFloat.ScaleW(w: 20),
                                          customerBlock: @escaping PTCustomerCustomerBlock,
                                          tapBlock: @escaping (_ index:NSInteger)->Void,
                                          alertDismissBlock: @escaping PTActionTask) {
        var buttonModels = [PTCustomBottomButtonModel]()
        buttons.enumerated().forEach { index,value in
            let model = PTCustomBottomButtonModel()
            if buttonColor.count < buttons.count {
                if index > (buttonColor.count - 1) {
                    model.titleColor = .systemBlue
                } else {
                    model.titleColor = buttonColor[index]
                }
            } else {
                model.titleColor = buttonColor[index]
            }
            model.titleName = value
            buttonModels.append(model)
        }
        
        let alertWidth = CGFloat.kSCREEN_WIDTH - alertLeftAndRightSpace * 2
        
        let alerts = PTCustomAlertView(superView: superView,alertTitle: titleString,font: titleFont,titleColor: titleColor,alertVerLineColor: alertVerLineColor,alertBackgroundColor: alertBackgroundColor,heightlightedColor: alertHeightlightedColor,moreButtons: buttonModels, alertAnimationType: alertAnimationType,touchBackground: touchBackground,cornerSize: cornerSize)
        alerts.snp.makeConstraints { make in
            make.height.equalTo(customAlertHeight + PTCustomAlertView.titleAndBottomViewNormalHeight(width: alertWidth, title: titleString, font: titleFont, buttonArray: buttonModels))
            make.width.equalTo(alertWidth)
            make.centerX.centerY.equalTo(superView)
        }
        alerts.customerBlock = { customView in
            customerBlock(customView)
        }
        alerts.buttonClick = { alertView,index in
            tapBlock(index)
            alertView.dismiss()
        }
        alerts.didDismissBlock = { alertView in
            alertDismissBlock()
        }
    }

    //MARK: 初始化創建Alert
    ///初始化創建Alert
    /// - Parameters:
    ///   - superView: 加載在?上
    ///   - alertTitle: 標題
    ///   - font: 字體
    ///   - titleColor: 標題的字體顏色
    ///   - alertVerLineColor: 按鈕線的顏色
    ///   - alertBackgroundColor: Alert的背景顏色
    ///   - heightlightedColor: 按鈕點以後的顏色
    ///   - moreButtons: 按鈕設置
    ///   - alertAnimationType: 動畫形式
    ///   - touchBackground: 是否支持點擊背景消失Alert
    ///   - cornerSize: Alert邊框角弧度
    public init(superView:UIView,
         alertTitle:String = "",
         font:UIFont = UIFont.boldSystemFont(ofSize: 20),
         titleColor:UIColor = UIColor.black,
         alertVerLineColor:UIColor = UIColor.lightGray,
         alertBackgroundColor:UIColor = UIColor.white,
         heightlightedColor:UIColor = UIColor.lightGray,
         moreButtons:[PTCustomBottomButtonModel] = [PTCustomBottomButtonModel](),
         alertAnimationType:PTAlertAnimationType,
         touchBackground:Bool = true,
         cornerSize:CGFloat = 15) {
        super.init(frame: .zero)
        createAlertView(superView: superView, alertTitle: alertTitle, font: font, titleColor: titleColor, alertVerLineColor: alertVerLineColor, alertBackgroundColor: alertBackgroundColor, heightlightedColor: heightlightedColor, moreButtons: moreButtons, alertAnimationType: alertAnimationType, touchBackground: touchBackground, cornerSize: cornerSize)
    }
    
    func createAlertView(superView:UIView,
                         alertTitle:String? = "",
                         font:UIFont? = UIFont.boldSystemFont(ofSize: 20),
                         titleColor:UIColor? = UIColor.black,
                         alertVerLineColor:UIColor? = UIColor.lightGray,
                         alertBackgroundColor:UIColor? = UIColor.white,
                         heightlightedColor:UIColor? = UIColor.lightGray,
                         moreButtons:[PTCustomBottomButtonModel]? = [PTCustomBottomButtonModel](),
                         alertAnimationType:PTAlertAnimationType,
                         touchBackground:Bool? = true,
                         cornerSize:CGFloat? = 15) {
        bottombuttonArray = moreButtons!
        mainView = superView
        
        mainView.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        viewFont = font!
        alertTitleColor = titleColor!
        verLineColor = alertVerLineColor!
        titleString = alertTitle!
        alertViewBackgroundColor = alertBackgroundColor!
        heightlightedColorColor = heightlightedColor!
        animationType = alertAnimationType
        
        if touchBackground! {
            let tapBackgroundView = UITapGestureRecognizer.init(target: self, action: #selector(dismiss))
            tapBackgroundView.numberOfTouchesRequired = 1
            tapBackgroundView.numberOfTapsRequired = 1
            backgroundView.addGestureRecognizer(tapBackgroundView)
        }
        
        blur = SSBlurView.init(to: self)
        blur!.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
        blur!.alpha = 0.9
        blur!.enable()

        mainView.addSubview(self)
        PTGCDManager.gcdAfter(time: 0.1) {
            self.viewCornerRectCorner(cornerRadii: cornerSize!, corner: .allCorners)
        }
                
        addSubview(customView)

        var propertyNamed = ""
        var transform = CATransform3DMakeTranslation(0, 0, 0)

        switch animationType {
        case .Top:
            propertyNamed = kPOPLayerTranslationY
            transform = CATransform3DMakeTranslation(0, -(CGFloat.kSCREEN_HEIGHT / 2), 0)
        case .Bottom:
            propertyNamed = kPOPLayerTranslationY
            transform = CATransform3DMakeTranslation(0, (CGFloat.kSCREEN_HEIGHT / 2), 0)
        case .Left:
            propertyNamed = kPOPLayerTranslationX
            transform = CATransform3DMakeTranslation(-(CGFloat.kSCREEN_HEIGHT / 2), 0, 0)
        case .Right:
            propertyNamed = kPOPLayerTranslationX
            transform = CATransform3DMakeTranslation((CGFloat.kSCREEN_HEIGHT / 2), 0, 0)
        default:
            propertyNamed = kPOPLayerTranslationX
            transform = CATransform3DMakeTranslation(0, 0, 0)
        }
        
        let animation = POPSpringAnimation.init(propertyNamed: propertyNamed)
        layer.transform = transform
        animation?.toValue = 0
        animation?.springBounciness = 1
        layer.pop_add(animation, forKey: "AlertAnimation")
        
        PTGCDManager.gcdAfter(time: 0.1) {
            if self.customerBlock != nil {
                self.customerBlock!(self.customView)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let textH = PTCustomAlertView.getAlertTitleHeight(font: viewFont, alertWidth: frame.size.width - 20, title: titleString)
        if textH >= (CGFloat.kSCREEN_HEIGHT / 3) {
            titleLabel.text = titleString
            addSubview(titleScroller)
            titleScroller.contentSize = CGSize.init(width: frame.size.width - 20, height: UIView.sizeFor(string: titleString, font: viewFont, height: CGFloat(MAXFLOAT), width: (frame.size.width - 20)).height)
            titleScroller.snp.makeConstraints { make in
                make.height.equalTo(textH)
                make.top.equalToSuperview().inset(titleString.stringIsEmpty() ? 0 : 10)
                make.left.right.equalToSuperview().inset(10)
            }
            
            titleScroller.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.width.equalTo(frame.size.width - 20)
                make.centerX.equalToSuperview()
            }
        } else {
            titleLabel.text = titleString
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.height.equalTo(textH)
                make.top.equalToSuperview().inset(titleString.stringIsEmpty() ? 0 : 10)
                make.left.right.equalToSuperview().inset(10)
            }
        }
        
        let btnW = (frame.size.width - (CGFloat(bottombuttonArray.count) - 1) * AlertLine) / CGFloat(bottombuttonArray.count)
        var isEX : Bool?  = false
        for string in bottombuttonArray {
            if (viewFont.pointSize * CGFloat((string.titleName! as NSString).length) + 10) > btnW {
                isEX = true
                break
            } else {
                isEX = false
            }
        }
        let bottomButtonHeight = PTCustomAlertView.getBottomButtonHiehgt(font: viewFont, alertWidth: frame.size.width, moreButtonTitles: bottombuttonArray)
        let bottomHeight = isEX! ? (bottomButtonHeight * CGFloat(bottombuttonArray.count) + AlertLine * CGFloat(bottombuttonArray.count)) : (bottomButtonHeight + AlertLine)
        customView.snp.makeConstraints { make in
            if textH >= (CGFloat.kSCREEN_HEIGHT / 3) {
                make.top.equalTo(self.titleScroller.snp.bottom)
            } else {
                make.top.equalTo(self.titleLabel.snp.bottom)
            }
            make.bottom.equalToSuperview().inset(bottomHeight)
            make.left.right.equalToSuperview()
        }
        setBottomView()
    }
    
    func setBottomView() {
        let btnW = (frame.size.width - (CGFloat(bottombuttonArray.count) - 1) * AlertLine) / CGFloat(bottombuttonArray.count)
        var isEX : Bool?  = false
        for string in bottombuttonArray {
            if (viewFont.pointSize * CGFloat((string.titleName! as NSString).length) + 10) > btnW {
                isEX = true
                break
            } else {
                isEX = false
            }
        }
        
        if !(bottombuttonArray.count == 0 || bottombuttonArray.isEmpty) {
            let btnView = UIView()
            addSubview(btnView)
            btnView.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(self.customView.snp.bottom)
            }
            
            let controlSquareLine = UIView()
            controlSquareLine.backgroundColor = .lightGray
            btnView.addSubview(controlSquareLine)
            controlSquareLine.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(AlertLine)
            }
            
            let bottomButtonHeight = PTCustomAlertView.getBottomButtonHiehgt(font: viewFont, alertWidth: frame.size.width, moreButtonTitles: bottombuttonArray)
            bottombuttonArray.enumerated().forEach { (index,value) in
                let cancelBtn = UIButton.init(type: .custom)
                cancelBtn.setBackgroundImage(heightlightedColorColor.createImageWithColor(), for: .highlighted)
                cancelBtn.setTitleColor(value.titleColor, for: .normal)
                cancelBtn.setTitle(value.titleName, for: .normal)
                cancelBtn.titleLabel?.font = viewFont
                cancelBtn.tag = 100 + index
                cancelBtn.addActionHandlers { sender in
                    if self.buttonClick != nil {
                        self.buttonClick!(self,(sender.tag - 100))
                    }
                }
                btnView.addSubview(cancelBtn)
                cancelBtn.snp.makeConstraints { make in
                    if isEX! {
                        make.left.right.equalToSuperview()
                        make.top.equalToSuperview().inset(bottomButtonHeight * CGFloat(index) + AlertLine * CGFloat(index) + AlertLine)
                        make.height.equalTo(bottomButtonHeight)
                    } else {
                        make.width.equalTo(btnW)
                        make.top.equalToSuperview().inset(AlertLine)
                        make.bottom.equalToSuperview()
                        make.left.equalToSuperview().inset(btnW * CGFloat(index) + AlertLine * CGFloat(index))
                    }
                }
                
                let lineView = UIView()
                lineView.backgroundColor = .lightGray
                btnView.addSubview(lineView)
                lineView.snp.makeConstraints { make in
                    if isEX! {
                        make.left.right.equalToSuperview()
                        make.top.equalTo(cancelBtn.snp.bottom)
                        make.height.equalTo(AlertLine)
                    } else {
                        make.width.equalTo(AlertLine)
                        make.top.equalToSuperview().inset(AlertLine)
                        make.bottom.equalToSuperview()
                        make.left.equalTo(cancelBtn.snp.right)
                    }
                }
            }
        }
    }
    
    //MARK: 界面消失
    ///界面消失
    public func dismiss() {
        var propertyNamed = ""
        var offsetValue : CGFloat = 0

        switch animationType {
        case .Top:
            propertyNamed = kPOPLayerTranslationY
            offsetValue = -layer.position.y
        case .Bottom:
            propertyNamed = kPOPLayerTranslationY
            offsetValue = layer.position.y
        case .Left:
            propertyNamed = kPOPLayerTranslationX
            offsetValue = -layer.position.x - frame.size.width / 2
        case .Right:
            propertyNamed = kPOPLayerTranslationX
            offsetValue = layer.position.x + frame.size.width / 2
        default:
            propertyNamed = kPOPLayerTranslationX
            offsetValue = -layer.position.x
        }
        
        let offscreenAnimation = POPBasicAnimation.easeOut()
        offscreenAnimation?.property = (POPAnimatableProperty.property(withName: propertyNamed) as! POPAnimatableProperty)
        offscreenAnimation?.toValue = offsetValue
        offscreenAnimation?.duration = 0.35
        offscreenAnimation?.completionBlock = { (anim,finish) in
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.7, options: [.curveEaseOut,.beginFromCurrentState,.layoutSubviews]) {
                self.backgroundView.alpha = 0
                self.alpha = 0
            } completion: { ok in
                self.backgroundView.removeFromSuperview()
                self.customView.removeSubviews()
                self.removeFromSuperview()
                if self.didDismissBlock != nil {
                    self.didDismissBlock!(self)
                }
            }
        }
        layer.pop_add(offscreenAnimation, forKey: "offscreenAnimation")
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // 适配代码
            blur!.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
        }
    }
}
