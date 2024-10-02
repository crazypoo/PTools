//
//  PTSlider.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/2.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

let thumbBound_y:CGFloat = 20
let thumbBound_x:CGFloat = 10

public enum PTSliderTitleShowType:Int {
    case Top
    case Bottom
}

@objcMembers
public class PTSlider: UISlider {
    fileprivate var isShowTitle:Bool? {
        didSet {
            layoutSubviews()
        }
    }
    
    fileprivate var isTitleValue:Bool? {
        didSet {
            layoutSubviews()
        }
    }
    open var titleStyle:PTSliderTitleShowType = .Top
    open var titleColor:UIColor = .systemBlue
    open var titleFont:UIFont = .appfont(size: 14)
    open var titleValueUnit:String = ""
    
    fileprivate var lastBounds:CGRect? = .zero
    fileprivate lazy var sliderValueLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = self.titleFont
        view.textColor = self.titleColor
        
        if !self.isTitleValue! {
            view.text = String(format: "%.0f%%", self.value/self.maximumValue * 100)
        } else {
            view.text = String(format: "%.0f%@", self.value,self.titleValueUnit)
        }
        return view
    }()
    
    public init(showTitle:Bool,titleIsValue:Bool) {
        super.init(frame: .zero)
        isShowTitle = showTitle
        isTitleValue = titleIsValue
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var newRect = rect
        newRect.origin.x = rect.origin.x - 10
        newRect.size.width = rect.size.width + 20
        let result = super.thumbRect(forBounds: bounds, trackRect: newRect, value: value)
        lastBounds = result
        return result
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if point.x < 0 || point.x > bounds.size.width {
            return result
        }
        
        if point.y >= -thumbBound_y && point.y < (lastBounds!.size.height + thumbBound_y) {
            var value:CGFloat = 0.0
            value = point.x - bounds.origin.x
            value = value / bounds.size.width
            value = value < 0 ? 0 : value
            value = value > 1 ? 1: value
            value = value * CGFloat(maximumValue - minimumValue) + CGFloat(minimumValue)
            self.setValue(Float(value), animated: true)
        }
        
        return result
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var result = super.point(inside: point, with: event)
        if !result && point.y > -10 {
            if point.x >= (lastBounds!.origin.x - thumbBound_x) && point.x <= (lastBounds!.origin.x + lastBounds!.size.width + thumbBound_x) && point.y < (lastBounds!.size.height + thumbBound_y) {
                result = true
            }
        }
        return result
    }
    
    func createLabel() {
        if isShowTitle! {
            addTarget(self, action: #selector(sliderAction(slider:)), for: .valueChanged)
            isContinuous = true
            
            addSubview(sliderValueLabel)

            PTGCDManager.gcdAfter(time: 0.1) {
                
                if self.frame.size.height < (31 + self.sliderValueLabel.font.pointSize + 5) {
                    self.sliderValueLabel.isHidden = true
                    self.sliderValueLabel.removeFromSuperview()
                } else {
                    self.sliderValueLabel.isHidden = false
                }
                
                if !self.sliderValueLabel.isHidden {
                    self.sliderValueLabel.snp.makeConstraints { make in
                        switch self.titleStyle {
                        case .Top:
                            make.bottom.equalTo(self.snp.centerY).offset(-15.5)
                            make.top.equalToSuperview()
                        case .Bottom:
                            make.top.equalTo(self.snp.centerY).offset(15.5)
                            make.bottom.equalToSuperview()
                        }
                        make.left.right.equalToSuperview()
                    }
                }
            }
        } else {
            sliderValueLabel.removeFromSuperview()
        }
    }
    
    func sliderAction(slider:UISlider) {
        if !isTitleValue! {
            sliderValueLabel.text = String(format: "%.0f%%", value / maximumValue * 100)
        } else {
            sliderValueLabel.text = String(format: "%.0f%@", value, titleValueUnit)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        createLabel()
    }
    
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
    }
}
