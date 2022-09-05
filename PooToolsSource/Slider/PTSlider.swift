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

public enum PTSliderTitleShowType:Int
{
    case Top
    case Bottom
}

@objcMembers
public class PTSlider: UISlider {
    fileprivate var isShowTitle:Bool?
    {
        didSet
        {
            self.layoutSubviews()
        }
    }
    public var titleStyle:PTSliderTitleShowType = .Top
    public var titleColor:UIColor = .systemBlue
    public var titleFont:UIFont = .appfont(size: 14)
    
    fileprivate var lastBounds:CGRect? = .zero
    fileprivate lazy var sliderValueLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = self.titleFont
        view.textColor = self.titleColor
        view.text = String(format: "%.0f%%", self.value/self.maximumValue * 100)
        return view
    }()
    
    init(showTitle:Bool) {
        super.init(frame: .zero)
        self.isShowTitle = showTitle
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
        self.lastBounds = result
        return result
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if point.x < 0 || point.x > self.bounds.size.width
        {
            return result
        }
        
        if point.y >= -thumbBound_y && point.y < (self.lastBounds!.size.height + thumbBound_y)
        {
            var value:CGFloat = 0.0
            value = point.x - self.bounds.origin.x
            value = value / self.bounds.size.width
            value = value < 0 ? 0 : value
            value = value > 1 ? 1: value
            value = value * CGFloat(self.maximumValue - self.minimumValue) + CGFloat(self.minimumValue)
            self.setValue(Float(value), animated: true)
        }
        
        return result
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var result = super.point(inside: point, with: event)
        if !result && point.y > -10
        {
            if point.x >= (self.lastBounds!.origin.x - thumbBound_x) && point.x <= (self.lastBounds!.origin.x + self.lastBounds!.size.width + thumbBound_x) && point.y < (self.lastBounds!.size.height + thumbBound_y)
            {
                result = true
            }
        }
        return result
    }
    
    func createLabel()
    {
        if self.isShowTitle!
        {
            self.addTarget(self, action: #selector(self.sliderAction(slider:)), for: .valueChanged)
            self.isContinuous = true
            
            self.addSubview(self.sliderValueLabel)

            PTUtils.gcdAfter(time: 0.1) {
                
                if self.frame.size.height < (31 + self.sliderValueLabel.font.pointSize + 5)
                {
                    self.sliderValueLabel.isHidden = true
                    self.sliderValueLabel.removeFromSuperview()
                }
                else
                {
                    self.sliderValueLabel.isHidden = false
                }
                
                if !self.sliderValueLabel.isHidden
                {
                    self.sliderValueLabel.snp.makeConstraints { make in
                        switch self.titleStyle
                        {
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
        }
        else
        {
            self.sliderValueLabel.removeFromSuperview()
        }
    }
    
    func sliderAction(slider:UISlider)
    {
        self.sliderValueLabel.text = String(format: "%.0f%%", self.value/self.maximumValue * 100)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.createLabel()
    }
    
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
    }
}
