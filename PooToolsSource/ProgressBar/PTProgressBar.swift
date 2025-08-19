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

    /// 當進度變化時回調，回傳範圍 0~1
    public var progressChanged: ((CGFloat) -> Void)?
    
    fileprivate var animationEnd: Bool = false
    fileprivate var isAnimating: Bool = false
    fileprivate var showType: PTProgressBarShowType!
    
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
    
    private var progressWidthConstraint: Constraint?
    private var progressHeightConstraint: Constraint?
    private var currentProgress: CGFloat = 0 {
        didSet {
            progressChanged?(currentProgress) // 更新時觸發回調
        }
    }

    public init(showType: PTProgressBarShowType) {
        super.init(frame: .zero)
        self.showType = showType
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // 先加轨道，再加进度条
        addSubview(trackView)
        addSubview(progressView)
        
        trackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        switch showType {
        case .Vertical:
            progressView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
                progressHeightConstraint = make.height.equalTo(0).constraint
            }
        case .Horizontal:
            progressView.snp.makeConstraints { make in
                make.top.bottom.leading.equalToSuperview()
                progressWidthConstraint = make.width.equalTo(0).constraint
            }
        default:
            break
        }
    }
    
    // MARK: - Public Methods
    
    public func animationProgress(duration: CGFloat, @PTClampedProperyWrapper(range: 0...1) value: CGFloat) {
        startAnimation(type: .Normal, duration: duration, value: value)
    }

    public func startAnimation(type: PTProgressBarAnimationType, duration: CGFloat, @PTClampedProperyWrapper(range: 0...1) value: CGFloat) {
        guard !isAnimating else { return }
        
        isAnimating = true
        animationEnd = false
        currentProgress = value
        
        let animations = {
            switch self.showType {
            case .Vertical:
                self.progressHeightConstraint?.update(offset: self.bounds.height * value)
            case .Horizontal:
                self.progressWidthConstraint?.update(offset: self.bounds.width * value)
            default:
                break
            }
            self.layoutIfNeeded()
        }

        let options: UIView.AnimationOptions = (type == .Reverse) ? [.autoreverse] : []
        UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: options, animations: animations) { _ in
            self.animationEnd = true
            self.isAnimating = false
        }
    }

    public func stopAnimation() {
        guard isAnimating else { return }

        progressView.layer.removeAllAnimations()
        
        switch showType {
        case .Vertical:
            progressHeightConstraint?.update(offset: 0)
        case .Horizontal:
            progressWidthConstraint?.update(offset: 0)
        default:
            break
        }
        
        currentProgress = 0
        
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }

        isAnimating = false
        animationEnd = false
    }

    public func getProgress() -> CGFloat {
        return currentProgress
    }
    
    // MARK: - Layout
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        guard bounds.width > 0 && bounds.height > 0 else { return } // 防止 0 大小時無效更新
        
        switch showType {
        case .Vertical:
            let targetHeight = bounds.height * currentProgress
            if abs((progressHeightConstraint?.layoutConstraints.first?.constant ?? 0) - targetHeight) > 0.5 {
                progressHeightConstraint?.update(offset: targetHeight)
            }
        case .Horizontal:
            let targetWidth = bounds.width * currentProgress
            if abs((progressWidthConstraint?.layoutConstraints.first?.constant ?? 0) - targetWidth) > 0.5 {
                progressWidthConstraint?.update(offset: targetWidth)
            }
        default:
            break
        }
    }
}
