//
//  PTMediaBrowserLoadingView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

@objc public enum PTLoadingViewMode:Int {
    case LoopDiagram
    case PieDiagram
}

public let PTLoadingBackgroundColor:UIColor = .DevMaskColor
public let PTLoadingItemSpace :CGFloat = 10

@objcMembers
public class PTMediaBrowserLoadingView: UIView {
    
    public var hubTapCallback:PTActionTask?
    
    // 记录手势，防止重复添加
    private var tapGesture: UITapGestureRecognizer?

    public var viewCanTap:Bool = false {
        didSet {
            if viewCanTap {
                // 防御性编程：如果没有添加过手势才添加
                if tapGesture == nil {
                    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
                    self.addGestureRecognizer(tap)
                    self.tapGesture = tap
                }
            } else {
                // 如果设为 false，移除现有的手势
                if let tap = tapGesture {
                    self.removeGestureRecognizer(tap)
                    self.tapGesture = nil
                }
            }
        }
    }
    
    public var progress:CGFloat = 0 {
        didSet {
            // 限制 progress 的范围在 0.0 到 1.0 之间
            let safeProgress = max(0, min(1, progress))
            
            // 确保 UI 刷新和隐藏操作在主线程执行
            PTGCDManager.gcdMain {
                self.setNeedsDisplay()
                if safeProgress >= 1 {
                    self.hudHide()
                }
            }
        }
    }
    
    public var progressColor:UIColor = .white {
        didSet {
            circularProgressView.progressColor = progressColor
        }
    }
    
    fileprivate var progressMode:PTLoadingViewMode = .LoopDiagram
    
    lazy var backgroundView:UIView = {
        let view = UIView()
        view.backgroundColor = .DevMaskColor
        return view
    }()
    
    private lazy var circularProgressView: PTCircularProgressView = {
        let style: PTCircularProgressStyle = (progressMode == .LoopDiagram) ? .loop : .pie
        let view = PTCircularProgressView(style: style)
        view.progressColor = progressColor
        return view
    }()

    public init(type:PTLoadingViewMode) {
        super.init(frame: .zero)
        progressMode = type
        setupUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = .clear // 保证视图自身透明
        self.clipsToBounds = true
        
        // 之前是在 self 上通过 layer.cornerRadius 设置圆角
        // 为了方便，你可以直接在这里统一设置一个稍微柔和的圆角，也可以根据需求去掉
        self.layer.cornerRadius = 8.0
        self.backgroundColor = UIColor(white: 0, alpha: 0.6) // 给个半透明底色更好看
        
        // 将绘制组件添加到容器中
        addSubview(circularProgressView)
        circularProgressView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(PTLoadingItemSpace / 2) // 留出一点边距
        }
    }
    
    @objc private func handleTap() {
        self.hubTapCallback?()
    }

    public func hudShow(hudSize:CGSize = .init(width: 64, height: 64)) {
        guard self.superview == nil else { return }
                
        AppWindows?.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backgroundView.addSubview(self)
        self.snp.makeConstraints { make in
            make.size.equalTo(hudSize)
            make.centerX.centerY.equalToSuperview()
        }
        
        self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        self.backgroundView.alpha = 0
        
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.65,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseInOut) {
            self.transform = .identity
            self.backgroundView.alpha = 1
        }
    }
    
    public func hudHide() {
        // 增加了一个淡出效果，让关闭显得更自然
        UIView.animate(withDuration: 0.25, animations: {
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.backgroundView.alpha = 0
            self.alpha = 0
        }) { _ in
            self.backgroundView.removeFromSuperview()
            self.removeFromSuperview()
            // 恢复初始状态以便复用
            self.alpha = 1
            self.transform = .identity
        }
    }
}
