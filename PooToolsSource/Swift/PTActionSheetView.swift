//
//  PTActionSheetView.swift
//  Diou
//
//  Created by ken lam on 2021/10/19.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import pop
import SnapKit

public class PTActionCell:UIView
{
    private var blur:SSBlurView?
    
    lazy var cellButton : UIButton = {
        let view = UIButton(type: .custom)
        return view
    }()

    public override func layoutSubviews()
    {
        super.layoutSubviews()
        
        self.addSubview(cellButton)
        cellButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
                
        blur = SSBlurView.init(to: self)
        blur!.alpha = 0.9
        if #available(iOS 13.0, *) {
            blur!.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
        } else {
            blur!.style = .extraLight
            // Fallback on earlier versions
        }
        blur!.enable()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                // 适配代码
                blur!.style = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .extraLight
            }
        }
    }
}

@objcMembers
public class PTActionSheetView: UIView {
    public static let CancelButtonTag = 99999
    public static let DestructiveButtonTag = 99998
    
    public var actionSheetSelectBlock:((_ sheet:PTActionSheetView,_ selectIndex:Int)->Void)?
    
    private let kRowLineHeight:CGFloat = 0.5
    private let kRowHeight:CGFloat = 54
    private let kSeparatorHeight:CGFloat = 5
    private let LeftAndRightviewSpace:CGFloat = 10
    
    private var cornerRadii : CGFloat = 15
    private var actionSheetTitle:String = ""
    private var actionSheetMessage:String = ""
    private var cancelButtonTitle:String = ""
    private var destructiveButtonTitle:String = ""
    private var otherTitles:[String] = [String]()
    private var viewFont:UIFont = .systemFont(ofSize: 20)
    private var decisionFont:UIFont = .boldSystemFont(ofSize: 20)
    private var titleFont:UIFont = .boldSystemFont(ofSize: 16)
    private var normalTitleColor:UIColor = .clear
    private var destructiveTitleColor:UIColor = .clear
    private var cancelTitleColor:UIColor = .clear
    private var titleTitleColor:UIColor = .clear
    private var heightlightColor:UIColor = .clear
    private var dismissWithTapBackground:Bool = true
    
    private lazy var backgroundView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.DevMaskColor
        return view
    }()
    
    private lazy var actionSheetView : UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var actionSheetScroll : UIScrollView = {
        let view = UIScrollView()
        return view
    }()
    
    private lazy var titleLbale : PTActionCell = {
        let view = PTActionCell()
        view.cellButton.titleLabel!.textAlignment = .center
        view.cellButton.titleLabel!.font = titleFont
        view.cellButton.titleLabel!.numberOfLines = 0
        view.cellButton.setTitleColor(titleTitleColor, for: .normal)
        return view
    }()

    private lazy var destructiveButton : PTActionCell = {
        let view = PTActionCell()
        view.cellButton.addActionHandlers(handler: { (sender) in
            self.didSelection(sender: sender)
        })
        view.cellButton.tag = PTActionSheetView.DestructiveButtonTag
        view.cellButton.setTitle(destructiveButtonTitle, for: .normal)
        view.cellButton.titleLabel!.font = decisionFont
        view.cellButton.setTitleColor(destructiveTitleColor, for: .normal)
        return view
    }()
    
    private lazy var cancelBtn : PTActionCell = {
        let view = PTActionCell()
        view.cellButton.addActionHandlers(handler: { (sender) in
            self.didSelection(sender: sender)
        })
        view.cellButton.tag = PTActionSheetView.CancelButtonTag
        view.cellButton.setTitle(cancelButtonTitle, for: .normal)
        view.cellButton.titleLabel!.font = decisionFont
        view.cellButton.setTitleColor(cancelTitleColor, for: .normal)
        return view
    }()
        
    public init(title:String? = "",
         subTitle:String? = "",
         cancelButton:String? = "取消",
         destructiveButton:String? = "",
         otherButtonTitles:[String]? = [String](),
         buttonFont:UIFont? = .systemFont(ofSize: 20),
         comfirFont:UIFont? = .boldSystemFont(ofSize: 20),
         titleCellFont:UIFont? = .systemFont(ofSize: 16),
         normalCellTitleColor:UIColor? = UIColor.systemBlue,
         destructiveCellTitleColor:UIColor? = UIColor.systemBlue,
         cancelCellTitleColor:UIColor? = UIColor.systemBlue,
         titleCellTitleColor:UIColor? = UIColor.systemGray,
         selectedColor:UIColor? = UIColor.lightGray,
         corner:CGFloat? = 15,
         dismissWithTapBG:Bool? = true) {
        super.init(frame: .zero)
        self.createData(title: title!, subTitle: subTitle!, cancelButton: cancelButton!, destructiveButton: destructiveButton!, otherButtonTitles: otherButtonTitles!, buttonFont: buttonFont!, comfirFont: comfirFont!, titleCellFont: titleCellFont!, normalCellTitleColor: normalCellTitleColor!, destructiveCellTitleColor: destructiveCellTitleColor!, cancelCellTitleColor: cancelCellTitleColor!, titleCellTitleColor: titleCellTitleColor!, selectedColor: selectedColor!, corner: (corner! > (kRowHeight / 2)) ? (kRowHeight / 2) : corner!, dismissWithTapBG: dismissWithTapBG!)
        self.createView()
    }
    
    @objc public init(title:String? = "",subTitle:String? = "",cancelButton:String? = "",destructiveButton:String? = "",otherButtonTitles:[String]? = [String]()) {
        super.init(frame: .zero)
        self.createData(title: title!, subTitle: subTitle!, cancelButton: cancelButton!, destructiveButton: destructiveButton!, otherButtonTitles: otherButtonTitles!)
        self.createView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createData(title:String? = "",
                    subTitle:String? = "",
                    cancelButton:String? = "取消",
                    destructiveButton:String? = "",
                    otherButtonTitles:[String]? = [String](),
                    buttonFont:UIFont? = .systemFont(ofSize: 20),
                    comfirFont:UIFont? = .boldSystemFont(ofSize: 20),
                    titleCellFont:UIFont? = .systemFont(ofSize: 16),
                    normalCellTitleColor:UIColor? = UIColor.systemBlue,
                    destructiveCellTitleColor:UIColor? = UIColor.systemBlue,
                    cancelCellTitleColor:UIColor? = UIColor.systemBlue,
                    titleCellTitleColor:UIColor? = UIColor.systemGray,
                    selectedColor:UIColor? = UIColor.lightGray,
                    corner:CGFloat? = 15,
                    dismissWithTapBG:Bool? = true)
    {
        actionSheetTitle = title!
        actionSheetMessage = subTitle!
        cancelButtonTitle = cancelButton!
        destructiveButtonTitle = destructiveButton!
        otherTitles = otherButtonTitles!
        viewFont = buttonFont!
        normalTitleColor = normalCellTitleColor!
        destructiveTitleColor = destructiveCellTitleColor!
        titleTitleColor = titleCellTitleColor!
        heightlightColor = selectedColor!
        cornerRadii = (corner! > (kRowHeight / 2)) ? (kRowHeight / 2) : corner!
        decisionFont = comfirFont!
        cancelTitleColor = cancelCellTitleColor!
        titleFont = titleCellFont!
        dismissWithTapBackground = dismissWithTapBG!
    }
    
    func createView()
    {
        UIApplication.shared.delegate!.window!!.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(backgroundView)
        self.addSubview(actionSheetView)
        actionSheetView.addSubview(actionSheetScroll)
        
        if (!actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) || (actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) || (!actionSheetTitle.stringIsEmpty() && actionSheetMessage.stringIsEmpty())
        {
            let enterString = (!actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) ? "\n" : ""
            let titleStr = String(format: "%@%@%@", actionSheetTitle as CVarArg,enterString,actionSheetMessage as CVarArg)
            titleLbale.cellButton.setTitle(titleStr, for: .normal)
            actionSheetView.addSubview(titleLbale)
        }
        
        let highlightedImage = heightlightColor.createImageWithColor()
        
        if !destructiveButtonTitle.stringIsEmpty()
        {
            destructiveButton.cellButton.setBackgroundImage(highlightedImage, for: .highlighted)
            actionSheetView.addSubview(destructiveButton)
        }
                
        cancelBtn.cellButton.setBackgroundImage(highlightedImage, for: .highlighted)
        actionSheetView.addSubview(cancelBtn)
    }
    
    func destlineH()->CGFloat
    {
        return destructiveButtonTitle.stringIsEmpty() ? 0 : kRowLineHeight
    }
    
    func destRowH()->CGFloat
    {
        return destructiveButtonTitle.stringIsEmpty() ? 0 : kRowHeight
    }
    
    func titleHeight()->CGFloat
    {
        var spacing:CGFloat = 0
        
        var titleStr = ""
        if (!actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) || (actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) || (!actionSheetTitle.stringIsEmpty() && actionSheetMessage.stringIsEmpty())
        {
            spacing = 25
            let enterString = (!actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) ? "\n" : ""
            titleStr = String(format: "%@%@%@", actionSheetTitle as CVarArg,enterString,actionSheetMessage as CVarArg)
        }
        else
        {
            spacing = 0
            titleStr = ""
        }
        
        return PTUtils.sizeFor(string: titleStr, font: viewFont, height: CGFloat(MAXFLOAT), width: kSCREEN_WIDTH).height + spacing * 2
    }
    
    func scrollContentHeight()->CGFloat
    {
        let realH = CGFloat(otherTitles.count) * kRowHeight + kRowLineHeight * CGFloat(otherTitles.count)
        return realH
    }
    
    func actionSheetRealHeight()->CGFloat
    {
        return scrollContentHeight() + (titleHeight() + kRowLineHeight) + (kSeparatorHeight + kRowHeight) + destRowH() + destlineH() + kRowLineHeight * 2
    }
    
    func actionSheetHeight(orientation:UIDeviceOrientation)->CGFloat
    {
        let realH = actionSheetRealHeight()
        let canshowViewH:CGFloat = kSCREEN_HEIGHT - kTabbarSaveAreaHeight - kStatusBarHeight - 10
        if actionSheetRealHeight() >= canshowViewH
        {
            return canshowViewH
        }
        else
        {
            return realH
        }
    }
    
    func scrollHieght(orientation:UIDeviceOrientation)->CGFloat
    {
        let a:CGFloat = self.actionSheetHeight(orientation: orientation)
        let b:CGFloat = kSCREEN_HEIGHT
        if (a - b) <= 0
        {
            return a - (self.titleHeight() + kRowLineHeight) - (kSeparatorHeight + kRowHeight) - (self.destRowH() + self.destlineH() + kRowLineHeight * 2)
        }
        else
        {
            return self.scrollContentHeight()
        }
    }
    
    public override func layoutSubviews()
    {
        super.layoutSubviews()
        
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let device = UIDevice.current
        
        actionSheetView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(LeftAndRightviewSpace)
            make.bottom.equalToSuperview().inset(kTabbarSaveAreaHeight + 10)
            make.height.equalTo(self.actionSheetHeight(orientation: device.orientation))
        }
                
        if (!actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) || (actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) || (!actionSheetTitle.stringIsEmpty() && actionSheetMessage.stringIsEmpty())
        {
            titleLbale.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(self.titleHeight())
            }
            
            let actionSheetScrollBottom = destructiveButtonTitle.stringIsEmpty() ? (kRowHeight + kSeparatorHeight + kRowLineHeight) : ((kRowHeight*2) + kSeparatorHeight * 1.5 + kRowLineHeight)
            actionSheetScroll.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(titleLbale.snp.bottom).offset(kRowLineHeight)
                make.height.equalTo(self.scrollHieght(orientation: device.orientation))
                make.bottom.equalToSuperview().inset(actionSheetScrollBottom)
            }
            
            PTUtils.gcdAfter(time: 0.1) {
                self.titleLbale.viewCornerRectCorner(cornerRadii: self.cornerRadii, corner: [.topLeft,.topRight])
            }
        }
        else
        {
            let actionSheetScrollBottom = destructiveButtonTitle.stringIsEmpty() ? (kRowHeight + kSeparatorHeight + kRowLineHeight) : ((kRowHeight*2) + kSeparatorHeight * 1.5 + kRowLineHeight)
            actionSheetScroll.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(self.scrollHieght(orientation: device.orientation))
                make.bottom.equalToSuperview().inset(actionSheetScrollBottom)
            }
        }
        
        let contentW : CGFloat = kSCREEN_WIDTH - LeftAndRightviewSpace * 2
        actionSheetScroll.contentSize = CGSize.init(width: contentW, height: self.scrollContentHeight())
        actionSheetScroll.showsVerticalScrollIndicator = false
        actionSheetScroll.isScrollEnabled = (actionSheetRealHeight() >= kSCREEN_HEIGHT) ? true : false
        
        let highlightedImage = heightlightColor.createImageWithColor()

        if otherTitles.count > 0
        {
            otherTitles.enumerated().forEach({ (index,value) in
                let lineView = UIView()
                lineView.backgroundColor = .lightGray
                self.actionSheetScroll.addSubview(lineView)
                lineView.snp.makeConstraints { make in
                    make.height.equalTo(kRowLineHeight)
                    make.width.equalTo(kSCREEN_WIDTH - LeftAndRightviewSpace * 2)
                    make.centerX.equalToSuperview()
                    make.top.equalTo(kRowHeight * CGFloat(index) + kRowLineHeight * CGFloat(index))
                }

                let btn = PTActionCell()
                btn.cellButton.tag = index + 100
                btn.cellButton.titleLabel?.font = viewFont
                btn.cellButton.setTitleColor(normalTitleColor, for: .normal)
                btn.cellButton.setTitle(value, for: .normal)
                btn.cellButton.setBackgroundImage(highlightedImage, for: .highlighted)
                btn.cellButton.addActionHandlers { sender in
                    self.didSelection(sender: sender)
                }
                self.actionSheetScroll.addSubview(btn)

                btn.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.left.right.equalTo(lineView)
                    make.top.equalTo(lineView.snp.bottom)
                    make.height.equalTo(kRowHeight)
                }
                
                if (!actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) || (actionSheetTitle.stringIsEmpty() && !actionSheetMessage.stringIsEmpty()) || (!actionSheetTitle.stringIsEmpty() && actionSheetMessage.stringIsEmpty())
                {
                    
                }
                else
                {
                    if index == 0
                    {
                        lineView.isHidden = true
                        PTUtils.gcdAfter(time: 0.1) {
                            btn.viewCornerRectCorner(cornerRadii: self.cornerRadii, corner: [.topLeft,.topRight])
                        }
                    }
                    
                }
                
                if index == (self.otherTitles.count - 1)
                {
                    PTUtils.gcdAfter(time: 0.1) {
                        btn.viewCornerRectCorner(cornerRadii: self.cornerRadii, corner: [.bottomLeft,.bottomRight])
                    }
                }
            })
        }
                
        if !destructiveButtonTitle.stringIsEmpty()
        {
            destructiveButton.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(kRowHeight + kSeparatorHeight / 2)
                make.height.equalTo(kRowHeight)
            }
            
            PTUtils.gcdAfter(time: 0.1) {
                self.destructiveButton.viewCornerRectCorner(cornerRadii: self.cornerRadii, corner: .allCorners)
            }
        }
                
        cancelBtn.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(kRowHeight)
        }
        
        PTUtils.gcdAfter(time: 0.1) {
            self.cancelBtn.viewCornerRectCorner(cornerRadii: self.cornerRadii, corner: .allCorners)
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let view = touches.first
        let point = view!.location(in: backgroundView)
        if !actionSheetView.frame.contains(point)
        {
            if dismissWithTapBackground
            {
                dismiss {
                    
                }
            }
        }
    }
    
    public func dismiss(block:(()->Void)?)
    {
        let offscreenAnimation = POPBasicAnimation.easeOut()
        offscreenAnimation?.property = (POPAnimatableProperty.property(withName: kPOPLayerTranslationY) as! POPAnimatableProperty)
        offscreenAnimation?.toValue = actionSheetRealHeight() + 10
        offscreenAnimation!.duration = 0.35
        offscreenAnimation?.completionBlock = { (anim,finish) in
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.7, options: [.curveEaseOut,.beginFromCurrentState,.layoutSubviews]) {
                self.backgroundView.alpha = 0
            } completion: { animationFinish in
                self.removeFromSuperview()
                if block != nil
                {
                    block!()
                }
            }
        }
        actionSheetView.layer.pop_add(offscreenAnimation, forKey: "offscreenAnimation")
    }
    
    public func show()
    {
        let animation = POPSpringAnimation.init(propertyNamed: kPOPLayerTranslationY)
        actionSheetView.layer.transform = CATransform3DMakeTranslation(0, self.actionSheetRealHeight(), 0)
        animation?.toValue = 0
        animation?.springBounciness = 1
        actionSheetView.layer.pop_add(animation, forKey: "ActionSheetAnimation")
    }
    
    func didSelection(sender:UIButton)
    {
        if actionSheetSelectBlock != nil
        {
            var index = 0
            if sender == cancelBtn.cellButton
            {
                index = PTActionSheetView.CancelButtonTag
            }
            else if sender == destructiveButton.cellButton
            {
                index = PTActionSheetView.DestructiveButtonTag
            }
            else
            {
                index = sender.tag - 100
            }
            dismiss {
                self.actionSheetSelectBlock!(self,index)
            }
        }
    }
}
