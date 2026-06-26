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

    /// 当进度变化时回调，回传范围 0~1 (支持动画过程中的实时回调)
    public var progressChanged: ((CGFloat) -> Void)?
    
    fileprivate var animationEnd: Bool = false
    fileprivate var isAnimating: Bool = false
    
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
    private var displayLink: CADisplayLink?

    public init(showType: PTProgressBarShowType) {
        self.showType = showType
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命周期管理
    
    deinit { }
    
    /// 优化：处理视图被意外移除父视图时的场景，防止 CADisplayLink 导致内存泄漏
    public override func removeFromSuperview() {
        super.removeFromSuperview()
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
    
    // MARK: - 核心约束更新机制
    
    private func updateConstraints(for progress: CGFloat) {
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
        
        // 优化：在更新目标约束前，强制刷新一次布局，确保起点正确
        self.layoutIfNeeded()
        
        // 更新约束目标
        updateConstraints(for: safeValue)
        
        // 开启实时进度监听
        startDisplayLink()
        
        let options: UIView.AnimationOptions = (type == .Reverse) ? [.autoreverse, .curveEaseInOut] : [.curveEaseInOut]
        
        // 优化：执行阻尼弹簧动画 (Spring Animation)，让进度条更加生动自然
        // dampingRatio: 0.82 意味着有一点点非常轻微的弹性，不会太夸张，但极其顺滑
        // initialVelocity: 0.2 提供一个微小的初速度
        UIView.animate(withDuration: TimeInterval(duration), delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2, options: options, animations: {
            self.layoutIfNeeded()
        }) { [weak self] finished in
            guard let self = self else { return }
            self.stopDisplayLink()
            
            if type == .Reverse {
                self.currentProgress = 0
                self.updateConstraints(for: 0)
                self.progressChanged?(0)
            } else {
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
        
        // 停止动画的回落过程也可以稍微加入弹簧效果
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.layoutIfNeeded()
        }) { [weak self] _ in
            guard let self = self else { return }
            self.isAnimating = false
            self.animationEnd = false
            self.progressChanged?(0)
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
        guard let presentationLayer = progressView.layer.presentation() else { return }
        let currentSize = presentationLayer.bounds.size
        let totalSize = trackView.bounds.size
        
        let progress: CGFloat
        if showType == .Horizontal {
            progress = totalSize.width > 0 ? currentSize.width / totalSize.width : 0
        } else {
            progress = totalSize.height > 0 ? currentSize.height / totalSize.height : 0
        }
        
        progressChanged?(max(0, min(1, progress)))
    }
}
