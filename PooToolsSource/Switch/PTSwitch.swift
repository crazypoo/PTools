//
//  PTSwitch.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/18.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

open class PTSwitch: UIControl {
    public var valueChangeCallBack:((Bool) -> Void)?
    
    public var isOn = false {
        didSet {
            if animation {
                UIView.animate(withDuration: 0.3) {
                    self.switchBackgroundView.backgroundColor = self.isOn ? self.onTintColor : self.switchTintColor
                }
            } else {
                self.switchBackgroundView.backgroundColor = self.isOn ? self.onTintColor : self.switchTintColor
            }
        }
    }
    
    public var switchTintColor:UIColor = UIColor(hexString: "c7c7c7")! {
        didSet {
            self.switchBackgroundView.backgroundColor = self.isOn ? self.onTintColor : switchTintColor
        }
    }

    public var onTintColor:UIColor = .systemGreen {
        didSet {
            self.switchBackgroundView.backgroundColor = self.isOn ? onTintColor : switchTintColor
        }
    }
    
    public var thumbColor:Any {
        get {
            return UIColor.white
        }
        set {
            switchThumbView.loadImage(contentData: newValue)
        }
    }
    
    private let switchBackgroundView = UIView()
    private lazy var switchThumbView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    private var animation:Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // 设置背景视图
        switchBackgroundView.backgroundColor = switchTintColor
        addSubview(switchBackgroundView)

        // 设置滑块视图
        switchThumbView.backgroundColor = (thumbColor as! UIColor)
        addSubview(switchThumbView)

        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSwitch))
        addGestureRecognizer(tapGesture)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        // 设置背景视图的布局
        switchBackgroundView.frame = bounds
        switchBackgroundView.layer.cornerRadius = frame.height / 2

        // 设置滑块视图的布局
        let thumbSize = CGSize(width: frame.height - 4, height: frame.height - 4)
        let thumbPosition = isOn ? frame.width - thumbSize.width - 2 : 2
        switchThumbView.frame = CGRect(x: thumbPosition, y: 2, width: thumbSize.width, height: thumbSize.height)
        switchThumbView.layer.cornerRadius = (frame.height - 4) / 2
    }

    @objc private func toggleSwitch() {
        isOn.toggle()
        sendActions(for: .valueChanged)
        updateSwitchState(animated: true)
        valueChangeCallBack?(isOn)
    }

    private func updateSwitchState(animated: Bool) {
        animation = animated
        let thumbSize = switchThumbView.frame.size
        let thumbPosition = isOn ? frame.width - thumbSize.width - 2 : 2
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.switchThumbView.frame.origin.x = thumbPosition
            }
        } else {
            switchThumbView.frame.origin.x = thumbPosition
        }
    }

    public func setOn(_ on: Bool, animated: Bool) {
        isOn = on
        updateSwitchState(animated: animated)
    }
}
