//
//  PTProgressBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

@objc public enum PTProgressBarShowType: Int {
    case Vertical
    case Horizontal
}

@objc public enum PTProgressBarAnimationType: Int {
    case Normal
    case Reverse
}

@objcMembers
public class PTProgressBar: UIView {
    
    /// 进度条颜色
    open var barColor: UIColor = .systemBlue {
        didSet {
            progressView.backgroundColor = barColor
        }
    }
    
    /// 底部轨道颜色
    open var trackColor: UIColor = .systemGray5 {
        didSet {
            trackView.backgroundColor = trackColor
        }
    }
    
    public var animationed: Bool {
        return animationEnd
    }

    /// 当进度变化时回调，回传范围 0~1 (现在支持动画过程中的实时回调)
    public var progressChanged: ((CGFloat) -> Void)?
    
    fileprivate var animationEnd: Bool = false
    fileprivate var isAnimating: Bool = false
    
    // 优化：改为 public let，避免使用隐式解包可选型 (!) 提高代码安全性
    public let showType: PTProgressBarShowType
    
    fileprivate lazy var trackView: UIView = {
        let view = UIView()
        view.backgroundColor = trackColor
        return view
    }()
    
    fileprivate lazy var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = barColor
        return view
    }()
    
    private var currentProgress: CGFloat = 0
    
    // 优化：引入 CADisplayLink 监听动画过程中的真实 UI 渲染状态
    private var displayLink: CADisplayLink?

    public init(showType: PTProgressBarShowType) {
        self.showType = showType
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 清理 DisplayLink 防止内存泄漏
    deinit {
        stopDisplayLink()
    }

    private func setupUI() {
        addSubview(trackView)
        addSubview(progressView)
        
        trackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 初始状态进度为 0
        updateConstraints(for: 0)
    }
    
    // MARK: - 核心约束更新机制 (替代 layoutSubviews)
    /// 使用 SnapKit 的 multipliedBy 实现比例布局，完美适配屏幕旋转和尺寸变化
    private func updateConstraints(for progress: CGFloat) {
        // 确保进度始终在 0~1 之间
        let safeProgress = max(0, min(1, progress))
        
        progressView.snp.remakeConstraints { make in
            if showType == .Vertical {
                make.leading.trailing.bottom.equalToSuperview()
                if safeProgress == 0 {
                    make.height.equalTo(0)
                } else {
                    make.height.equalToSuperview().multipliedBy(safeProgress)
                }
            } else {
                make.top.bottom.leading.equalToSuperview()
                if safeProgress == 0 {
                    make.width.equalTo(0)
                } else {
                    make.width.equalToSuperview().multipliedBy(safeProgress)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    public func animationProgress(duration: CGFloat, @PTClampedPropertyWrapper(range: 0...1) value: CGFloat) {
        startAnimation(type: .Normal, duration: duration, value: value)
    }

    public func startAnimation(type: PTProgressBarAnimationType, duration: CGFloat, @PTClampedPropertyWrapper(range: 0...1) value: CGFloat) {
        guard !isAnimating else { return }
        
        isAnimating = true
        animationEnd = false
        
        let safeValue = max(0, min(1, value))
        currentProgress = safeValue
        
        // 1. 更新约束目标
        updateConstraints(for: safeValue)
        
        // 2. 开启实时进度监听
        startDisplayLink()
        
        let options: UIView.AnimationOptions = (type == .Reverse) ? [.autoreverse, .curveEaseInOut] : [.curveEaseInOut]
        
        // 3. 执行动画，加入 [weak self] 防止闭包引起的内存泄漏
        UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: options, animations: {
            self.layoutIfNeeded()
        }) { [weak self] _ in
            guard let self = self else { return }
            self.stopDisplayLink()
            
            if type == .Reverse {
                // 修复：如果是 Reverse 动画，视觉上已经回到了 0，此时必须将真实数据和约束也重置为 0
                self.currentProgress = 0
                self.updateConstraints(for: 0)
                self.progressChanged?(0)
            } else {
                // 确保最终回调的值是绝对精确的目标值
                self.progressChanged?(safeValue)
            }
            
            self.animationEnd = true
            self.isAnimating = false
        }
    }

    public func stopAnimation() {
        guard isAnimating else { return }

        stopDisplayLink()
        progressView.layer.removeAllAnimations()
        
        currentProgress = 0
        updateConstraints(for: 0)
        
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.isAnimating = false
            self?.animationEnd = false
            self?.progressChanged?(0)
        }
    }

    public func getProgress() -> CGFloat {
        return currentProgress
    }
    
    // MARK: - CADisplayLink (用于动画时的实时回调)
    
    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgressFromPresentationLayer))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateProgressFromPresentationLayer() {
        // 读取视图层级在动画过程中的“渲染帧”，以计算最真实的视觉进度
        guard let presentationLayer = progressView.layer.presentation() else { return }
        let currentSize = presentationLayer.bounds.size
        let totalSize = trackView.bounds.size
        
        let progress: CGFloat
        if showType == .Horizontal {
            progress = totalSize.width > 0 ? currentSize.width / totalSize.width : 0
        } else {
            progress = totalSize.height > 0 ? currentSize.height / totalSize.height : 0
        }
        
        // 触发回调
        progressChanged?(max(0, min(1, progress)))
    }
}
